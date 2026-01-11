const std = @import("std");

pub fn hoge() void {
    std.debug.print("Hoge function called\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality2" {
    try std.testing.expect(add(3, 7) == 11);
}
