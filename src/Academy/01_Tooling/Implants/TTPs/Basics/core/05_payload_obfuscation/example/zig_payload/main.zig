const print = @import("std").debug.print;

pub export fn main() callconv(.C) void {
    print("Hello, from the zig payload!\n");
}
