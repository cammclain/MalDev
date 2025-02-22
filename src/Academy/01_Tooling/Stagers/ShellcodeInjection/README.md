# Shellcode Injection

## Overview

Shellcode Injection is a technique used by malware developers to execute arbitrary code in the memory space of another process. This method is commonly employed to evade detection and maintain persistence on the target system. The Shellcode Injection directory contains examples and methodologies for performing shellcode injection in various ways, ranging from simple injection techniques to more sophisticated methods like process hollowing.

## Techniques

- **SimpleInjector**: This method involves injecting shellcode directly into a process's memory space and executing it. It is straightforward and effective for quick tasks.
- **ProcessHollowing**: A more advanced technique that involves creating a process in a suspended state, hollowing out its memory, and replacing it with malicious code. This method is stealthier as it can masquerade as a legitimate process.

## Usage

Each subdirectory contains example code and detailed explanations of the technique it covers. Review the README.md file within each subdirectory for more information on how to use and implement these techniques.

