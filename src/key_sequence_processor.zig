pub const KeySequenceProcessor = @This();

const std = @import("std");
const mem = std.mem;

const deque = @import("lib/deque.zig");

const types = @import("types.zig");

const KeySequenceState = enum {
    Normal,
    Escape,
    Escape2,
    Escape3,
};

keyQueue: deque.Deque(u8),
state: KeySequenceState = .Normal,
esc3_state: types.KeyControlType = undefined,

pub fn init(gpa: mem.Allocator) mem.Allocator.Error!@This() {
    return @This(){ .keyQueue = try .init(gpa) };
}

pub fn deinit(self: *@This()) void {
    self.keyQueue.deinit();
}

pub fn addByte(self: *@This(), c: u8) void {
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
                0x1b => {
                    self.state = .Escape;
                    return null;
                },
                0x08 => {
                    return .{ .Control = .Backspace };
                },
                0x0a => {
                    return .{ .Control = .NewLine };
                },
                0x0d => {
                    return .{ .Control = .NewLine };
                },
                0x7f => {
                    return .{ .Control = .Backspace };
                },
                else => {
                    if (c < 0x20) {
                        std.debug.print("Ignored control character: \\x{x:02}\n", .{c});
                        @panic("Ignored control character");
                    } else {
                        return .{ .DisplayCharacter = c };
                    }
                },
            }
        },
        .Escape => {
            if (c == '[') {
                self.state = .Escape2;
                return self.nextKey();
            } else {
                std.debug.print("Unknown escape sequence: \\x1b{}\n", .{c});
                @panic("Ignored control character");
                //self.state = .Normal;
                //return null;
            }
        },
        .Escape2 => {
            switch (c) {
                'A' => {
                    self.state = .Normal;
                    return .{ .Control = .Up };
                },
                'B' => {
                    self.state = .Normal;
                    return .{ .Control = .Down };
                },
                'C' => {
                    self.state = .Normal;
                    return .{ .Control = .Right };
                },
                'D' => {
                    self.state = .Normal;
                    return .{ .Control = .Left };
                },
                '3' => {
                    self.state = .Escape3;
                    self.esc3_state = .Delete;
                    return null;
                },
                '5' => {
                    self.state = .Escape3;
                    self.esc3_state = .PageUp;
                    return null;
                },
                '6' => {
                    self.state = .Escape3;
                    self.esc3_state = .PageDown;
                    return null;
                },
                else => {
                    std.debug.print("Unknown escape sequence: \\x1b[{}\n", .{c});
                    @panic("Ignored control character");
                    //self.state = .Normal;
                    //return null;
                },
            }
        },
        .Escape3 => {
            if (c == 126) {
                self.state = .Normal;
                return .{ .Control = self.esc3_state };
            } else {
                std.debug.print("Unknown escape sequence: \\x1b[3{}\n", .{c});
                @panic("Ignored control character");
                //self.state = .Normal;
                //return null;
            }
        },
    }
}
