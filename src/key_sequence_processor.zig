pub const KeySequenceProcessor = @This();

const std = @import("std");
const mem = std.mem;

const deque = @import("lib/deque.zig");

const types = @import("types.zig");
const log = @import("log.zig");

const KeySequenceState = enum {
    Normal,
    Escape,
    Escape2,
    Escape3,
};

keyQueue: deque.Deque(u8),
state: KeySequenceState = .Normal,
esc3_state: types.KeyCommandType = undefined,

pub fn init(gpa: mem.Allocator) mem.Allocator.Error!@This() {
    return @This(){ .keyQueue = try .init(gpa) };
}

pub fn deinit(self: *@This()) void {
    self.keyQueue.deinit();
}

pub fn addByte(self: *@This(), c: u8) void {
    log.debug("Key: \\x{x:02}", .{c});

    self.keyQueue.pushBack(c) catch unreachable;
}

pub fn addBuf(self: *@This(), b: []const u8) void {
    for (b) |byte| {
        self.keyQueue.pushBack(byte) catch unreachable;
    }
}

pub fn nextKey(self: *@This()) ?types.Key {
    const c = self.keyQueue.popFront() orelse return null;
    switch (self.state) {
        .Normal => {
            switch (c) {
                0x01...0x1a => {
                    return .{ .Control = 'A' + c - 1 };
                },
                0x1b => {
                    self.state = .Escape;
                    return null;
                },
                0x7f => {
                    return .{ .Command = .Backspace };
                },
                else => {
                    if (c < 0x20) {
                        log.err("Ignored control character: \\x{x:02}", .{c});
                        return null;
                    } else {
                        return .{ .DisplayCharacter = c };
                    }
                },
            }
        },
        .Escape => {
            switch (c) {
                'A'...'Z', 'a'...'z' => {
                    self.state = .Normal;
                    return .{ .Alt = c };
                },
                '[' => {
                    self.state = .Escape2;
                    return self.nextKey();
                },
                else => {
                    log.err("Unknown escape sequence: \\x1b{}", .{c});
                    self.state = .Normal;
                    return null;
                },
            }
        },
        .Escape2 => {
            switch (c) {
                'A' => {
                    self.state = .Normal;
                    return .{ .Command = .Up };
                },
                'B' => {
                    self.state = .Normal;
                    return .{ .Command = .Down };
                },
                'C' => {
                    self.state = .Normal;
                    return .{ .Command = .Right };
                },
                'D' => {
                    self.state = .Normal;
                    return .{ .Command = .Left };
                },
                '3' => {
                    self.state = .Escape3;
                    self.esc3_state = .Delete;
                    return self.nextKey();
                },
                '5' => {
                    self.state = .Escape3;
                    self.esc3_state = .PageUp;
                    return self.nextKey();
                },
                '6' => {
                    self.state = .Escape3;
                    self.esc3_state = .PageDown;
                    return self.nextKey();
                },
                else => {
                    log.err("Unknown escape sequence: \\x1b[\\x{x}", .{c});
                    self.state = .Normal;
                    return null;
                },
            }
        },
        .Escape3 => {
            if (c == 126) {
                self.state = .Normal;
                return .{ .Command = self.esc3_state };
            } else {
                log.err("Unknown escape sequence: \\x1b[?\\x{x}", .{c});
                self.state = .Normal;
                return null;
            }
        },
    }
}

pub fn parseKey(str: []const u8) !types.Key {
    if (str.len == 0) return error.InvalidKey;

    // Control key: "C-a", "C-x", etc.
    if (str.len >= 3 and str[0] == 'C' and str[1] == '-') {
        const ch = str[2];
        if (ch >= 'a' and ch <= 'z') {
            return .{ .Control = ch - 'a' + 'A' };
        } else if (ch >= 'A' and ch <= 'Z') {
            return .{ .Control = ch };
        }
        return error.InvalidKey;
    }

    // Alt/Meta key: "M-a", "M-x", etc.
    if (str.len >= 3 and str[0] == 'M' and str[1] == '-') {
        const ch = str[2];
        if ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z')) {
            return .{ .Alt = ch };
        }
        return error.InvalidKey;
    }

    // Command keys
    if (mem.eql(u8, str, "Up")) return .{ .Command = .Up };
    if (mem.eql(u8, str, "Down")) return .{ .Command = .Down };
    if (mem.eql(u8, str, "Left")) return .{ .Command = .Left };
    if (mem.eql(u8, str, "Right")) return .{ .Command = .Right };
    if (mem.eql(u8, str, "Delete")) return .{ .Command = .Delete };
    if (mem.eql(u8, str, "Backspace")) return .{ .Command = .Backspace };
    if (mem.eql(u8, str, "PageUp")) return .{ .Command = .PageUp };
    if (mem.eql(u8, str, "PageDown")) return .{ .Command = .PageDown };
    if (mem.eql(u8, str, "Home")) return .{ .Command = .Home };
    if (mem.eql(u8, str, "End")) return .{ .Command = .End };
    if (mem.eql(u8, str, "NewLine")) return .{ .Control = 'M' };

    // Single display character
    if (str.len == 1) {
        return .{ .DisplayCharacter = str[0] };
    }

    return error.InvalidKey;
}
