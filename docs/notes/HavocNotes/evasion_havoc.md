Optimized Evasion Stack for Havoc Demon Implant
Overview: The Havoc Framework’s “Demon” implant is designed with advanced evasion in mind, but further optimizations can enhance its stealth. Key evasion tactics span AMSI bypass, in-memory obfuscation, code modifications, and C2 traffic OPSEC. All these techniques should be implemented ethically in controlled red-team scenarios, with careful testing to maintain stability. Below, we break down each area with practical strategies and real-world considerations.
1. AMSI Patching Across Different Security Solutions
Bypassing Windows Defender’s AMSI: Havoc Demon (like many implants) often neutralizes Windows Defender’s Antimalware Scan Interface (AMSI) to prevent script and memory scans from flagging the payload. A common technique is in-memory patching of the AmsiScanBuffer function so it always returns a benign status or error. For example, patching the function prologue with instructions to set an error code (e.g. 0x80070057) and immediately return will trick AMSI into thinking the scan failed, bypassing detection​
PAYATU.COM
. This typically involves changing the memory protection of amsi.dll in the current process, writing the patch bytes (such as mov eax, 0x80070057; ret), then restoring memory protection. The patch causes AMSI to return an error or “clean” result without actually scanning, effectively disabling Defender’s script/content scanning in that process​
PAYATU.COM
. Crucially, this patch is done dynamically in memory – it does not persist on disk or system-wide, and only affects the current process’s AMSI instance. This ensures that the bypass exists only as long as needed (e.g. during payload execution) and is gone once the process exits or AMSI is reloaded, aligning with stealth and least-persistence principles.Dynamic and Just-in-Time Patching: For better OPSEC, red-teamers apply the AMSI patch only at the moment it’s needed (for instance, right before executing malicious code that would trigger AMSI). This “just-in-time” approach avoids keeping AMSI disabled longer than necessary. Some advanced loaders even remove the patch after use or use trampolines so that AMSI is only bypassed for specific high-risk calls. While complete removal is often not needed, the idea is to minimize the window in which security products might notice the tampering. Because the patch resides solely in memory and mimics normal code (simply returning an error code), it often flies under the radar of Windows Defender itself. This allows the Demon to run payloads (PowerShell commands, .NET assemblies, etc.) without AMSI’s content scans interfering.EDR-Specific AMSI Bypass Variations: Modern EDR solutions may detect or block the classic AMSI patch if done in a known pattern. Vendors are aware of the common 5-byte AmsiScanBuffer patch, so they may scan memory for the modified bytes or hook the AMSI functions at a deeper level. To counter this, attackers modify their approach:
Signature Evasion: Instead of using the well-known patch bytes, alter them slightly (achieving the same logical effect via different opcodes) to avoid simple signature matching. For instance, patching a later part of the function or a conditional jump within AmsiScanBuffer (not just the entry point) can bypass naive memory scans​
R-TEC.NET
. By not patching the very start of the function (a red-flag for EDR), but rather a subsequent check or the call instruction, the bypass is less obvious. As one report notes, “patching at custom offsets is still appropriate for amsi.dll” and avoids the memory scan detections that entry-point patching triggers​
R-TEC.NET
.
Alternative Hooks: In some cases, it’s possible to hook higher-level AMSI calls that lead to AmsiScanBuffer instead of patching amsi.dll directly. For example, a bypass method by OffSec targets the .NET System.Management.Automation assembly’s AMSI invocation – patching the pointer used to call AmsiScanBuffer during PowerShell JIT initialization​
OFFSEC.COM
. Because this leverages a spot that’s already writable in memory (a .NET JIT stub), it avoids calling VirtualProtect and can slip past certain EDR defenses​
OFFSEC.COM
. Such CLR hooking or patching of the AMSI integration layer (e.g., the PowerShell AMSI trigger or the CLR’s AMSI callback) may not be monitored as heavily as amsi.dll itself.
Prevent AMSI Initialization: Another variation is to prevent amsi.dll from ever loading or initializing in the process. Tools like SharpBlock use debug techniques to block AMSI DLL loading in child processes​
R-TEC.NET
. If no AMSI present, no scanning occurs. However, this is more applicable when spawning a new process for payload execution. In Demon’s context (running in an already started implant), in-memory patching is the more direct route.
Hardware Breakpoints: Some red team tradecraft even uses hardware breakpoints on AmsiScanBuffer to skip its execution without altering bytes (essentially pausing execution at that function and returning)​
R-TEC.NET
. This is quite advanced and rare, but it demonstrates the cat-and-mouse with EDR: as of this writing, most EDRs do not flag such breakpoint tricks, making it an “opsec safe” method in practice​
R-TEC.NET
.
In summary, the Demon’s evasion stack would patch or disable AMSI in-memory to bypass Defender, and adjust those techniques if a specific EDR is in play. By only modifying AMSI in the current process and in a stealthy manner, the implant avoids AMSI-based detection across various AV/EDR solutions. These approaches should always be tested in a lab against the target EDR to ensure the chosen variation isn’t detected – what works for Defender might need tweaking for CrowdStrike, SentinelOne, etc.
2. In-Memory Obfuscation Strategies
Hiding the Demon in RAM: To avoid heuristic detection or memory forensics, the Demon implant must conceal its presence and behaviors in RAM. Havoc’s Demon already incorporates sleep obfuscation and indirect execution to stay invisible​
ZSCALER.COM
​
CRITICALSTART.COM
. The idea is to never remain as a obvious, static blob of malicious code in memory when not actively needed. Two key techniques are used: (a) self-encryption of code during idle periods, and (b) using indirect or stealthy calls for sensitive operations.
Sleep Encryption (“Sleep Masking”): When the Demon agent is idle (sleeping between C2 beacons), it can encrypt or otherwise hide its own code in memory. This prevents memory scanners from finding recognizable malicious code patterns during those periods. Havoc implements multiple sleep obfuscation techniques (configurable in its profile)​
IMMERSIVELABS.COM
. For example, the Ekko and Foliage techniques use creative Windows API abuse to encrypt the payload in place: Ekko leverages RtlCreateTimerQueueTimer to schedule a series of operations (an ROP chain) that encrypt the implant, put the thread to sleep, then decrypt it later​
IMMERSIVELABS.COM
. Foliage uses APC (Asynchronous Procedure Calls) with NtQueueApcThread to achieve a similar encrypted-sleep state​
IMMERSIVELABS.COM
. In effect, when Demon goes to sleep, its code sections in memory are either marked as no-execute and/or XORed/RC4-encrypted so that an EDR scanning memory finds nothing but gibberish. Just before the implant needs to execute again (on wakeup for the next beacon or task), the code is decrypted back to original form. This “sleep -> encrypt -> decrypt -> wake” cycle (inspired by techniques like Ekko) lets malware hide during dormancy​
IMMERSIVELABS.COM
​
IMMERSIVELABS.COM
. It’s a direct response to advanced EDRs that do periodic memory scrapes looking for known malware implants.
Heuristic Evasion in Memory: Beyond encryption, Demon tries to avoid common memory indicators. For instance, the shellcode loader in Havoc removes the normal PE headers when loading the Demon DLL in memory​
ZSCALER.COM
. By stripping DOS/NT headers and other metadata, it prevents scanners from easily recognizing a loaded PE file or dumping it via normal means. Additionally, the implant’s memory regions are allocated with innocuous names/permissions where possible. Any large executable region can be a red flag, so techniques like run-in-place (execute from RWX memory then free it) or reflecting into existing process memory are used. The goal is to ensure the Demon doesn’t look like a typical injected DLL or a big suspicious code blob. Some malware even copy their code into executor threads’ call stacks or other unusual places to hide from scanners – though such extremes must be weighed against stability.
Indirect Syscalls and API Unhooking: A significant in-memory evasion is avoiding userland API hooks by EDR. Havoc Demon employs indirect syscalls, meaning instead of calling Windows API functions directly (which EDRs might have hooked in ntdll.dll), it invokes system calls in a way that bypasses those hooks​
CRITICALSTART.COM
. For example, when Demon needs to perform an action like allocating memory or loading a library, it may execute the CPU instruction for a syscall directly, or use a small stub that jumps into the kernel, rather than call the normal NtAllocateVirtualMemory in ntdll. By doing so, it sidesteps any monitoring that occurs in the user-mode API layer. Indirect syscalls can be implemented by retrieving syscall IDs dynamically and using assembly stubs (a technique often called “Hell’s Gate” or “SysWhispers”). This not only thwarts hook-based detections, but also makes the in-memory call trace less typical (the call stack won’t show the implant calling suspicious APIs directly). Demon further pairs this with return address spoofing – when making a syscall, it manipulates the stack so that the return address points to a legitimate module (like ntdll or an EXE), masking the true caller​
ZSCALER.COM
. This fools EDR heuristics that analyze call stacks for anomalies. Together, “indirect syscalls and return address stack spoofing” allow Demon to perform actions in memory without leaving the usual footprints that behavioral engines look for​
CRITICALSTART.COM
.
Encrypted Configuration and Communication Buffers: To reduce forensic artifacts, any sensitive data the Demon holds in memory (config, keys, payloads) is encrypted or encoded. Havoc’s agent, for instance, decrypts tasks and encrypts results on the fly, and even its in-memory C2 messages use encryption keys so that raw strings aren’t visible in RAM​
IMMERSIVELABS.COM
​
IMMERSIVELABS.COM
. This means that even if a memory dump is taken, an analyst can’t easily extract things like command history or operator notes from the implant.
Balancing Obfuscation and Stability: It’s important that these in-memory tricks do not crash the process or incur huge performance penalties. Techniques like Ekko/Foliage have been tested by the community and shown to let the code sleep safely while encrypted​
IMMERSIVELABS.COM
. Red team operators should use known implementations or thoroughly test custom ones. Also, encrypting/decrypting on each beacon adds a bit of overhead – configuration can adjust sleep intervals such that this is manageable. Always ensure the implant has a failsafe (e.g., if the timer or APC fails, it can still continue running) to avoid deadlocking itself. From an OPSEC perspective, these measures greatly reduce the “footprint” of the Demon in memory, making incident response and live forensics much harder for defenders. As Zscaler observed, Havoc’s combination of sleep masking and syscalls was key to bypassing even Windows 11 Defender’s latest protections​
ZSCALER.COM
.
3. Modifications to Demon’s Core Code for Evasion
Altering API Resolution (Signature Evasion): Out-of-the-box, the Demon agent uses certain patterns to resolve Windows API functions. According to analyses, it employs an API hashing routine (a modified DJB2 algorithm) to find function addresses at runtime​
ZSCALER.COM
. While this is already more stealthy than storing API names as clear text, the hashing approach itself could become a signature if it’s unique to Havoc. To evade static detection, you can modify how the Demon resolves APIs. For example, change the hash constants or algorithm slightly, so the byte sequence of the resolver differs from the public Havoc code. Alternatively, implement a completely different dynamic resolution: some malware enumerate the Export Address Table of DLLs and resolve APIs by checksum or by walking function pointer tables. Others load a fresh copy of the DLL and use its exports to avoid revealing imports. The key is to deviate from the known Demon code enough that static analysis tools or YARA rules looking for Havoc’s resolver will not match. Since Havoc is open-source, defensive researchers have likely catalogued its behaviors – a little refactoring (reordering instructions, adding dummy operations, using different registers) can break those signatures without changing functionality.Using Syscalls to Evade Hooks: As noted, Demon already leverages direct or indirect syscalls for many operations​
CRITICALSTART.COM
. Ensuring all critical actions use these hook-evasion techniques is important. If modifying Demon’s core, you might extend syscall usage to any new functionality or to cover more APIs that were previously unhooked. For instance, if file operations or registry queries in Demon still go through the WinAPI normally, consider using native syscalls for them as well. This can be done by implementing known syscall stubs (via inline assembly or using projects like SysWhispers). However, be mindful of target OS versions – syscalls numbers can change between Windows builds, so Demon’s code should either retrieve syscall numbers dynamically or gracefully handle failure (to avoid crashing on mismatch). Another approach is DLL unhooking: instead of calling syscalls directly, the implant can restore the original DLL code in memory. By copying a fresh ntdll.dll from disk over the hooked one in memory, an implant removes EDR hooks entirely​
IRED.TEAM
. This “full DLL unhooking” gives it back the normal API functions unmonitored (at least until hooks might be reinstalled)​
IRED.TEAM
. Implementing such unhooking in Demon’s initialization could be a powerful evasion, though it’s a bit noisy (changing a large memory region) and could itself be detected. Many attackers prefer direct syscalls for precision, but unhooking is an option if syscalls are impractical in some context.Avoiding Static Indicators: Aside from API resolution, other static signatures in Demon’s binary or behavior can be tweaked. One known indicator was the Demon’s network protocol using a magic value 0xDEADBEEF in its headers​
IMMERSIVELABS.COM
. Changing or removing such obvious constants is advisable so the implant isn’t trivially identified by memory or PCAP scans. Similarly, any embedded strings (even innocuous ones) in the Demon payload should be reviewed – e.g., compiler artifacts, library names, or default usernames. These can be encrypted or randomized on each compile. Even the hash algorithm mentioned above – if it’s known to be DJB2, an AV could emulate the code to get the API names. Using a less common algorithm or adding a step (like an XOR with a secret) would hamper that analysis. Essentially, polymorphism is your friend: rebuild the Demon with slight variations for each engagement so no two samples look alike. This could involve automated instruction substitution or using a polymorphic engine on the final shellcode.Userland Hook Evasion and Other Tweaks: To make Demon less recognizable in behavioral analysis, we focus on interfering with common monitoring avenues:
ETW Patching: Event Tracing for Windows is another telemetry mechanism that modern implants disable. Havoc’s loader already patches EtwEventWrite in ntdll, for example​
ZSCALER.COM
​
ZSCALER.COM
. By overwriting the start of this function, the implant stops Windows from logging events about its actions​
ZSCALER.COM
. Ensuring this patch (or an equivalent) is in place helps evade any detection that relies on ETW events (used by some EDRs and Windows Defender ATP). This kind of modification is a one-time tweak in Demon’s startup – it should get the address of EtwEventWrite and nop it out or return immediately​
ZSCALER.COM
​
ZSCALER.COM
. It’s a small change but has big impact on reducing noise in telemetry.
Use Legitimate Paths: Modify the implant to use more “legitimate” sequences of calls. For instance, if Demon normally injects into a process using a common API pattern (VirtualAllocEx -> WriteProcessMemory -> CreateRemoteThread), that’s very well-known to EDR. Instead, one could implement an alternative like QueueUserAPC injection or SetThreadContext with a suspended thread. By deviating from the usual injection technique, the implant’s behavior is less likely to match detection rules. This requires core code changes in how Demon does lateral movement or process migration.
Timing and Frequency: Demon’s core loop can be adjusted to avoid being too regular. The default beacon interval was 2 seconds​
IMMERSIVELABS.COM
, which is quite fast and potentially noisy. Increasing the interval or adding jitter (random variation) makes its network and CPU usage patterns less suspicious. This is a configuration change (C2 profile tweak) rather than code, but it’s an important operational consideration that complements code-level evasion.
Reduced Footprint: Finally, any non-essential features in Demon that could create noise might be stripped out for a stealth edition. If, say, Demon has an option for keylogging or screenshotting that isn’t needed, those modules could be removed to reduce the memory profile. Fewer capabilities mean fewer API calls and signatures to potentially catch. This kind of slimming down improves evasion (and is a good practice in threat emulation – use only the TTPs you need for the scenario).
In short, modifying Demon’s internals for evasion involves breaking known patterns – changing hashes, using syscalls or unhooking to dodge API monitors, patching telemetry like ETW, and generally making the binary as unique as possible for each operation. These changes maintain functionality but make static and behavioral analysis much harder for defenders.
4. Operational Security Considerations for HTTP-Based C2 Traffic
Stealthy C2 via Cloudflare: Routing C2 traffic through a Cloudflare proxy or CDN is a common red-team practice to hide the team server and blend in with normal web traffic. The goal is to make Demon’s HTTP(S) communications look indistinguishable from legitimate user traffic. To achieve this, one should utilize domain fronting or redirectors such that the implant appears to be talking to a benign host. For example, an operator might configure a Cloudflare Worker or Tunnel that forwards traffic from a benign domain (over HTTPS) to the real C2 server​
LABS.JUMPSEC.COM
. From the target’s network perspective, the beacon is simply making TLS requests to a Cloudflare IP or a whitelisted domain – which raises no immediate red flags. It’s critical to choose a domain that fits the victim environment’s normal profile (e.g. something like cdn-content\[.\]domain.com or an IT service domain) and register it behind Cloudflare. DNS and SNI should match that domain so that even deep packet inspection sees nothing amiss.Blending in with Legitimate Web Activity: Beyond routing, the content and pattern of C2 communications should mimic legitimate traffic. Havoc allows customizing the HTTP profile (similar to Cobalt Strike’s malleable profiles). Several tips to make Demon’s traffic OPSEC-safe:
HTTP Headers: Use realistic header values. Set the User-Agent to a common one (e.g. a popular web browser agent string or a known software updater). Include typical headers like Accept, Accept-Language, Connection, etc., as a normal browser would. Avoid any default or empty headers that implants sometimes use. For instance, ensure it doesn’t use the literal word “Havoc” or “Demon” anywhere in the protocol – those defaults must be changed.
URI and Parameters: Structure Beacon callback URLs to look like normal API endpoints or resource fetches. Instead of POST /beacon (which is obvious), use something like POST /api/v1/auth or GET /resources/<id> that could be part of a legit web application. Some C2 profiles even mimic known services (Office 365, Slack, etc.) in their URL patterns. The idea is to blend in with “normal” expected traffic on the network​
VECTRA.AI
. If the target network heavily uses a certain cloud service, you might shape C2 traffic to resemble that service’s protocol.
Packet Size and Timing: Employ a jitter in beacon interval – e.g., plus/minus 20% random – so the beacons don’t arrive exactly every X seconds. Real user traffic is somewhat bursty and irregular, so a perfectly periodic beacon can stand out. Also consider payload size: always sending a fixed 512-byte encrypted blob is abnormal. Instead, pad responses to varying lengths or occasionally send benign-looking decoy data. Some attackers will intermix innocuous web requests with the C2 channel on the same domain – for example, downloading an image or script that actually is a decoy. This can confuse automated detections that look for repetitive patterns.
Encrypted Content: Since Demon uses HTTPS (TLS) via the Cloudflare proxy, the content is encrypted in transit, which helps. However, note that on the target host, TLS inspection appliances could see SNI or certificate info. Using Cloudflare means you’re likely using a shared certificate (e.g., sni.cloudflaressl.com or the domain’s cert from Cloudflare). This is generally fine, but ensure the certificate common name and other details wouldn’t arouse suspicion. If possible, use a real-looking certificate (Cloudflare’s managed cert for your domain should suffice here).
Avoiding Default Profile Detections: Defenders have started writing signatures for Havoc’s default C2 profile, just as they did for Cobalt Strike. For instance, as mentioned, Havoc’s default HTTP beacon has a “DEAD BEEF” magic header in its payload​
IMMERSIVELABS.COM
. If you leave this unchanged, any packet capture or memory inspection could trivially identify the traffic as Havoc. It’s imperative to change such values – e.g., use a different magic constant or no obvious marker at all. The same goes for the default sleep interval (2 seconds)​
IMMERSIVELABS.COM
 and the predictable sequence of “checkin” followed by tasks. You might configure the Demon to do some innocuous GET requests for a fake resource as a heartbeat, and only POST real data every Nth beacon. Mixing GET/POST or varying status codes (maybe sometimes returning 204 No Content) can help simulate normal web behavior.Another detection point is the order of HTTP headers or TLS fingerprints. Tools like JA3 fingerprinting can identify C2 frameworks by how they initiate TLS. Malleable profiles can’t easily change the TLS stack (that’s up to the HTTP library in use), but you could embed Demon in a wrapper that uses an alternative HTTP client implementation if needed. In practice, using a well-known TLS library (like WinHTTP or WinInet with system defaults) will give a benign fingerprint (appearing as Internet Explorer or Windows OS traffic). Ensure Demon uses the WinHTTP API with default settings so that its TLS ClientHello looks like any other Windows process.Finally, when using Cloudflare, monitor your C2 traffic from the defender’s perspective if possible. Cloudflare logs or a tool like Wireshark (with decryption if you have keys) can help verify that your beacons truly resemble ordinary traffic. The Cloudflare proxy will also filter out obviously malicious patterns (e.g., it might block non-HTTP-compliant behavior), so using a proxy forces you to stay within normal HTTP usage – which is good for OPSEC.Operational Safeguards: It’s worth noting some OPSEC safeguards while using these network evasion techniques. Always operate your C2 over TLS (never plaintext HTTP) to prevent easy content inspection. Use DNS names that don’t map back to known bad indicators – avoid reuse of domains across engagements, and ideally use domains that have some legitimate history or similarity to real ones (typosquatting can help here, though be careful with legality/ethics of that). Also, have a redirector architecture such that if one node is discovered, it doesn’t lead directly to your main server. Cloudflare in front helps a lot here, as the true IP is hidden and you could rotate backend servers if needed.In summary, make the Demon’s C2 traffic look like a normal user browsing or a standard application communicating. By leveraging Cloudflare as a front and customizing the HTTP profile (headers, URIs, intervals, and data patterns), you reduce the chance that defenders will single out your C2 traffic. Blending with normal traffic or mimicking known services (even as far as imitating something like Windows Update’s request format​
VECTRA.AI
) can dramatically improve network stealth. Always keep in mind the balance: too much obfuscation can complicate your operation, so focus on the high-value modifications that yield the biggest reduction in detectability.Conclusion: Each layer of this evasion stack – AMSI bypass, memory hiding, code camouflage, and network blending – contributes to Demon’s stealth in a defense-in-depth fashion. These techniques are drawn from real attacker tradecraft but are repurposed here for authorized red-team use, helping threat emulation teams stay ahead of detection mechanisms​
CRITICALSTART.COM
. By carefully implementing these measures and adhering to ethical guidelines, red teamers can test and improve an organization’s detection capabilities against a truly advanced evasive implant, without causing unintended harm or instability. Always ensure you have permission and a rollback plan when deploying such techniques in an engagement, as even benign “malware” can trigger instability if misconfigured. With the optimized evasion stack, Havoc’s Demon can remain furtive, allowing operators to assess and sharpen the target’s security posture against state-of-the-art evasion.Sources:
Zscaler ThreatLabz – “Havoc Across the Cyberspace” (Feb 2023) – Analysis of Havoc Demon’s evasion (sleep obfuscation, indirect syscalls, etc.)​
ZSCALER.COM
​
ZSCALER.COM
CriticalStart – “New Framework Raising Havoc” – Notes on Demon bypassing Defender via return address spoofing & sleep masking​
CRITICALSTART.COM
R-TEC – “Bypass AMSI in 2025” – Discussion of AMSI patch detection and variants (entry-point vs. offset patch)​
R-TEC.NET
Payatu – “All you need to know about AMSI Bypass in 2024” – Overview of AMSI patch technique (AmsiScanBuffer patch bytes)​
PAYATU.COM
OffSec – “AMSI WriteRaid 0-day” – Innovative AMSI bypass via System.Management.Automation hooking (alternative to patching amsi.dll)​
OFFSEC.COM
Immersive Labs – “Havoc C2 – Defensive Operator’s Guide” – Details on Demon’s sleep encryption (Ekko, Foliage) and network indicators​
IMMERSIVELABS.COM
​
IMMERSIVELABS.COM
Vectra – “C2 Evasion Techniques: Malleable Profiles” – How malleable C2 traffic can mimic normal traffic (blending with legit patterns)​
VECTRA.AI
Jumpsec Labs – “Putting the C2 in C2loudflare” – (Red-team infrastructure guide for Cloudflare redirectors)​
LABS.JUMPSEC.COM
ired.team – “Full DLL Unhooking with C++” – Method of restoring in-memory DLL to evade userland hooks​
IRED.TEAM
Zscaler – Technical analysis of Havoc Demon loader – ETW patching via EtwEventWrite in ntdll to disable telemetry​
ZSCALER.COM
​
ZSCALER.COM
Others: Various security blogs and open-source tools documentation for AMSI bypass and EDR evasion techniques​
PAYATU.COM
​
ZSCALER.COM
.