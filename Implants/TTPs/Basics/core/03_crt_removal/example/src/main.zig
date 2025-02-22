const std = @import("std");

// Define a custom entry point for a freestanding Windows binary.
// This bypasses the CRT startup routines.
pub export fn main() callconv(.C) void {
    // Insert your payload or initialization code here.
    return;
}
