

use std::fs::File;

use std::io::Write;


const XOR_KEY: u8 = 0xAA;

const PAYLOAD: &[u8] = include_bytes!("../../zig_payload/payload.bin")




