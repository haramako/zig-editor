const std = @import("std");
const Allocator = std.mem.Allocator;
const arrays = @import("lib/arrays.zig");

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

pub const Hoge = packed union {
    a: u8,
    b: u16,
};

pub const Key = packed union {
    None: u8,
    Command: KeyCommandType,
    DisplayCharacter: u8,
    Control: u8,
    Alt: u8,
};

/// Character Presentation Descriptor
pub const CPD = struct {
    chr: u8,
    attr: u8,
    color: u8,
};

pub const LineCPD = struct {
    cpds: std.ArrayList(CPD),
    pub fn init(gpa: Allocator) !LineCPD {
        return .{
            .cpds = try std.ArrayList(CPD).initCapacity(gpa, 100),
        };
    }
    pub fn deinit(self: *LineCPD, gpa: Allocator) void {
        self.cpds.deinit(gpa);
    }
};

pub const U8Array2D = arrays.Array2D(u8);
pub const CPDArray2D = arrays.Array2D(CPD);
