---
title: Binary Packing
description: Binary packing is a technique used to compress or encrypt a binary file. This can be used to hide the contents of the binary file from static analysis tools.
platforms: Windows 10
authors: Cam McLain
date: 05/01/2024
---


# Introduction to Binary Packing


Binary packing is a technique used to compress or encrypt a binary file. This can be used to hide the contents of the binary file from static analysis tools. This technique is often used by malware authors to evade detection by security tools. In this article, we will discuss the basics of binary packing and how it can be used to obfuscate malware.


## Goal is to create a Nim binary and pack it within a Zig binary

The goal of this exercise is to create a Nim binary and pack it within a Zig binary. This will allow us to obfuscate the Nim binary and make it more difficult for static analysis tools to detect.

The Nim binary will be a known malware sample from Byt3bl33d3r's repository. The Zig binary will be a simple program that will unpack the Nim binary and execute it.

## Step 1: Create the Nim Binary

