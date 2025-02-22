# ProcessHollowing

## Overview

Process Hollowing is an advanced shellcode injection technique that creates a new process in a suspended state, then replaces its memory with malicious code. This allows the malware to masquerade as a legitimate process, evading detection by security software.

## Implementation

The ProcessHollowing examples detail the steps required to perform this technique, including creating a suspended process, unmapping its memory, allocating new memory for the malicious code, writing the shellcode, and resuming the process.

## Example Code

Example code in this directory demonstrates the Process Hollowing technique with detailed comments explaining each step of the process. It is designed for educational purposes to provide insight into the technique's complexity and stealth capabilities.

## Usage

To implement Process Hollowing:

1. Compile the provided example code.
2. Run the compiled executable, ensuring you have the necessary permissions.
3. The example may require additional input, such as the path to a legitimate executable to hollow and the shellcode to inject.


