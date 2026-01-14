const std = @import("std");
const mem = std.mem;
const Buffer = @import("buffer.zig");
const types = @import("types.zig");

pub fn lineHead(buf: *Buffer, pos: usize) !usize {
    if (pos < 0 and pos > buf.len()) {
        return error.outOfBounds;
    }
    var p = pos;
    while (p > 0) : (p -= 1) {
        const c = buf.get(p - 1) orelse return 0;
        if (c == '\n') {
            return p;
        }
    }
    return p;
}

pub fn lineTail(buf: *Buffer, pos: usize) !usize {
    var p: usize = pos;
    while (p < buf.len()) {
        const c = buf.get(p) orelse return error.outOfBounds;
        if (c == '\n') {
            break;
        }
        p += 1;
    }
    return p;
}

pub fn getColumnInLine(buf: *Buffer, pos: usize) !usize {
    const head = try lineHead(buf, pos);
    return pos - head;
}

test "lineHead and lineTail" {
    const gpa = std.testing.allocator;

    var buf = try Buffer.init(gpa, "Hello\nWorld\nZig", .{});
    defer buf.deinit();

    try std.testing.expectEqual(6, try lineHead(&buf, 8)); // start of "World"
    try std.testing.expectEqual(11, try lineTail(&buf, 8)); // start of "World"

    try std.testing.expectEqual(0, try lineHead(&buf, 2)); // first line
    try std.testing.expectEqual(15, try lineTail(&buf, 12)); // last line
}
