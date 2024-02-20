# SimpleInjector

## Overview

The SimpleInjector technique involves straightforward methods of shellcode injection, where the shellcode is directly written into the memory of a target process and executed. This approach is typically the first step for many malware developers due to its simplicity and directness.

## Implementation

SimpleInjector examples demonstrate basic Windows API calls such as `OpenProcess`, `VirtualAllocEx`, `WriteProcessMemory`, and `CreateRemoteThread` to inject and execute shellcode within a target process.

## Example Code

The provided example code illustrates a basic shellcode injection scenario using the mentioned Windows APIs. It is designed to be simple to understand and modify for specific needs.

## Usage

To use the SimpleInjector technique:

1. Compile the example code.
2. Execute it with appropriate privileges.
3. Specify the target process ID as required.

