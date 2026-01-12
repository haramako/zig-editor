const std = @import("std");

/// VT100 Escape Codes
pub const Code = enum(u8) {
    CUU = 'A', // Cursor Up
    CUD = 'B', // Cursor Down
    CUF = 'C', // Cursor Forward
    CUB = 'D', // Cursor Back
    CNL = 'E', // Cursor Next Line
    CPL = 'F', // Cursor Previous Line
    CHA = 'G', // Cursor Horizontal Absolute
    CUP = 'H', // (2) Cursor Position
    ED = 'J', // Erase in Display
    EL = 'K', // Erase in Line
    SGR = 'm', // (2) Select Graphic Rendition

    SCP = 's', // Save Cursor Position
    RCP = 'u', // Restore Cursor Position
};

/// VT100 Colors
pub const Color = enum(u8) {
    Black = 0,
    Red = 1,
    Green = 2,
    Yellow = 3,
    Blue = 4,
    Magenta = 5,
    Cyan = 6,
    White = 7,

    BrightBlack = 60,
    BrightRed = 61,
    BrightGreen = 62,
    BrightYellow = 63,
    BrightBlue = 64,
    BrightMagenta = 65,
    BrightCyan = 66,
    BrightWhite = 67,
};

/// SGR (Select Graphic Rendition) Parameters
pub const SGRParam = enum(u8) {
    Reset = 0,
    Bold = 1,
    Underline = 4,
    Reversed = 7,

    ForgroundColor = 30, // 30~37, 90~97
    BackgroundColor = 40, // 40~47, 100~107
};

pub const EscapeSequence = struct {
    code: Code,
    n: i32 = -1,
    m: i32 = -1,
    pub fn format(self: @This(), writer: anytype) !void {
        if (self.m >= 0) {
            return writer.print("\x1b[{};{}{c}", .{ self.n, self.m, @intFromEnum(self.code) });
        } else if (self.n >= 0) {
            return writer.print("\x1b[{}{c}", .{ self.n, @intFromEnum(self.code) });
        } else {
            return writer.print("\x1b{c}", .{@intFromEnum(self.code)});
        }
    }
};

pub fn esc0(code: Code) EscapeSequence {
    return EscapeSequence{ .code = code };
}

pub fn esc1(code: Code, n: i32) EscapeSequence {
    return EscapeSequence{ .code = code, .n = n };
}

pub fn esc2(code: Code, n: i32, m: i32) EscapeSequence {
    return EscapeSequence{ .code = code, .n = n, .m = m };
}

pub fn pos(x: i32, y: i32) EscapeSequence {
    return esc2(.CUP, y, x);
}

pub fn sgr(param: SGRParam) EscapeSequence {
    return esc1(.SGR, @intFromEnum(param));
}

pub fn reset() EscapeSequence {
    return sgr(.Reset);
}

pub fn fg(c: Color) EscapeSequence {
    return esc1(.SGR, @intFromEnum(SGRParam.ForgroundColor) + @intFromEnum(c));
}

pub fn bg(c: Color) EscapeSequence {
    return esc1(.SGR, @intFromEnum(SGRParam.BackgroundColor) + @intFromEnum(c));
}

pub fn testVt100() !void {
    const p = std.debug.print;
    p("{f}{f}", .{ esc1(.ED, 2), esc2(.CUP, 1, 1) });
    p("VT100 Test\n\n", .{});
    p("CURSOR: 1{f}2{f}3{f}4{f}5\n", .{ esc1(.CUF, 3), esc1(.CUB, 3), esc1(.CUU, 1), esc1(.CUD, 2) });

    p("FG    : ", .{});
    for (0..8) |i| {
        p("{f}{:04}{f}", .{ esc1(.SGR, 30 + @as(i32, @intCast(i))), i, reset() });
    }
    p("\n", .{});

    p("BG    : ", .{});
    for (0..8) |i| {
        p("{f}{:04}{f}", .{ esc1(.SGR, 40 + @as(i32, @intCast(i))), i, reset() });
    }
    p("\n", .{});

    p("BRIGHT: {f}Bright Red {f}Bright Green{f}\n", .{ fg(.BrightRed), fg(.BrightGreen), reset() });
    p("ATTR  : {f}UNDERLINE{f} {f}BOLD{f} {f}REVERSED{f}\n", .{ sgr(.Underline), reset(), sgr(.Bold), reset(), sgr(.Reversed), reset() });
    p("\n", .{});
}
