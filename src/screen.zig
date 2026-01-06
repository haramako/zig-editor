const std = @import("std");

pub fn hoge() void {}

pub const CUU = 'C';
pub const CHA = 'G';
pub const VPA = 'd';
pub const CUP = 'H';

pub const EscapeBuf = struct {
    code: u8,
    n: i16,
    buf: [6]u8 = undefined,
};

pub fn Esc(code: u8, n: i16) EscapeBuf {
    var buf = EscapeBuf{ .code = code, .n = n };
    _ = escape(&buf.buf, code, n) catch unreachable;
    return buf;
}

pub fn escape(buf: []u8, code: u8, n: i16) ![]u8 {
    return try std.fmt.bufPrint(buf, "\x1b[{}{c}", .{ n, code });
}

pub fn vpa(x: i32, y: i32) Buffer {
    var b = Buffer{};
    b.len = (std.fmt.bufPrint(&b.buf, "\x1b[{};{}H", .{ y, x }) catch unreachable).len;
    return b;
}

pub const Buffer = struct {
    buf: [8]u8 = undefined,
    len: usize = undefined,
    pub fn str(self: *const @This()) []const u8 {
        return self.buf[0..self.len];
    }
};
