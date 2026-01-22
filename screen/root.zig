const std = @import("std");

pub const vt100 = @import("vt100.zig");
pub const screen = @import("screen.zig");
pub const KeySequenceProcessor = @import("key_sequence_processor.zig");

pub const KeyCommandType = enum(u8) {
    Up,
    Down,
    Right,
    Left,
    NewLine,
    Delete,
    Backspace,
    PageUp,
    PageDown,
    Home,
    End,
};

pub const Key = union(enum) {
    None,
    Command: KeyCommandType,
    DisplayCharacter: u8,
    Control: u8,
    Alt: u8,

    pub fn compare(a: Key, b: Key) std.math.Order {
        const ta = std.meta.activeTag(a);
        const tb = std.meta.activeTag(b);
        if (ta != tb) {
            return std.math.order(@intFromEnum(ta), @intFromEnum(tb));
        }

        return switch (a) {
            .None => .eq,
            .Command => |ac| {
                const bc = b.Command;
                return std.math.order(@intFromEnum(ac), @intFromEnum(bc));
            },
            .DisplayCharacter => |ac| {
                const bc = b.DisplayCharacter;
                return std.math.order(ac, bc);
            },
            .Control => |ac| {
                const bc = b.Control;
                return std.math.order(ac, bc);
            },
            .Alt => |ac| {
                const bc = b.Alt;
                return std.math.order(ac, bc);
            },
        };
    }
};

/// Character Presentation Descriptor
pub const CPD = struct {
    chr: u8,
    attr: u8,
    color: u8,
};
