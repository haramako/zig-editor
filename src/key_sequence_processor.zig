pub const KeySequenceProcessor = @This();

const std = @import("std");
const mem = std.mem;

const deque = @import("lib/deque.zig");

const types = @import("types.zig");

const KeySequenceState = enum {
    Normal,
    Escape,
    Escape2,
};

keyQueue: deque.Deque(u8),
state: KeySequenceState = .Normal,

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
                0x0a => {
                    return .{ .Control = .NewLine };
                },
                0x0d => {
                    return .{ .Control = .NewLine };
                },
                0x00...0x09, 0x0b...0x0c, 0x0e...0x1a, 0x1c...0x1f => {
                    std.debug.print("Ignored control character: \\x{x:02}\n", .{c});
                    return null;
                },
                else => {
                    return .{ .DisplayCharacter = c };
                },
            }
        },
        .Escape => {
            if (c == '[') {
                self.state = .Escape2;
                return self.nextKey();
            } else {
                std.debug.print("Unknown escape sequence: \\x1b{}\n", .{c});
                self.state = .Normal;
                return null;
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
                else => {
                    std.debug.print("Unknown escape sequence: \\x1b[{}\n", .{c});
                    self.state = .Normal;
                    return null;
                },
            }
        },
    }
}
