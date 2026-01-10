const std = @import("std");
const mem = std.mem;
const deque = @import("deque.zig");

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

pub const KeyCode = enum(u8) {
    Up = 0x10,
    Down = 0x11,
    Right = 0x12,
    Left = 0x13,
};

const KeySequenceState = enum {
    Normal,
    Escape,
    Escape2,
};

pub const KeySequenceProcessor = struct {
    deque: deque.Deque(u8),
    state: KeySequenceState = .Normal,

    pub fn init(gpa: mem.Allocator) mem.Allocator.Error!@This() {
        return @This(){ .deque = try .init(gpa) };
    }

    pub fn deinit(self: *@This()) void {
        self.deque.deinit();
    }

    pub fn addByte(self: *@This(), c: u8) void {
        self.deque.pushBack(c) catch unreachable;
    }

    pub fn addBuf(self: *@This(), b: []const u8) void {
        for (b) |byte| {
            self.deque.pushBack(byte) catch unreachable;
        }
    }

    pub fn nextKey(self: *@This()) ?u8 {
        const c = self.deque.popFront() orelse return null;
        switch (self.state) {
            .Normal => {
                if (c == 0x1b) {
                    self.state = .Escape;
                    return null;
                } else {
                    return c;
                }
            },
            .Escape => {
                if (c == '[') {
                    self.state = .Escape2;
                    return self.nextKey();
                } else {
                    self.state = .Normal;
                    return c;
                }
            },
            .Escape2 => {
                switch (c) {
                    'A' => {
                        self.state = .Normal;
                        return @intFromEnum(KeyCode.Up);
                    },
                    'B' => {
                        self.state = .Normal;
                        return @intFromEnum(KeyCode.Down);
                    },
                    'C' => {
                        self.state = .Normal;
                        return @intFromEnum(KeyCode.Right);
                    },
                    'D' => {
                        self.state = .Normal;
                        return @intFromEnum(KeyCode.Left);
                    },
                    else => {
                        self.state = .Normal;
                        return null;
                    },
                }
            },
        }
    }
};
