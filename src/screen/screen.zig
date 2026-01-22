const std = @import("std");
const mem = std.mem;

const builtin = @import("builtin");
const windows = std.os.windows;

pub const ConsoleInfo = struct {
    width: i32,
    height: i32,
};

pub fn getConsoleInfo(file: *std.Io.File) ?ConsoleInfo {
    if (builtin.os.tag != .windows) return null;
    const handle = file.handle;
    var info: std.os.windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    if (windows.kernel32.GetConsoleScreenBufferInfo(handle, &info) == 0) {
        return null;
    }
    return .{ .width = @intCast(info.dwMaximumWindowSize.X), .height = @intCast(info.dwMaximumWindowSize.Y) };
}

pub fn set_raw_mode(file: *std.Io.File, b: bool) !void {
    if (builtin.os.tag == .windows) {
        //const ENABLE_PROCESSED_INPUT: u32 = 0x0001;
        const ENABLE_LINE_INPUT: u32 = 0x0002;
        const ENABLE_ECHO_INPUT: u32 = 0x0004;
        //const ENABLE_WINDOW_INPUT: u32 = 0x0008;
        const ENABLE_INSERT_MODE: u32 = 0x0020;
        const ENABLE_VIRTUAL_TERMINAL_INPUT: u32 = 0x0200;

        const handle = file.handle;
        var flags: u32 = undefined;
        if (windows.kernel32.GetConsoleMode(handle, &flags) == 0) return error.NotATerminal;
        if (b) {
            flags &= ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_INSERT_MODE);
            flags |= (ENABLE_VIRTUAL_TERMINAL_INPUT);
        } else {
            flags |= ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT;
            flags &= ~(ENABLE_VIRTUAL_TERMINAL_INPUT);
        }
        std.debug.assert(windows.kernel32.SetConsoleMode(handle, flags) != 0);
    } else {
        const posix = std.posix;
        var t: posix.termios = try posix.tcgetattr(posix.STDIN_FILENO);

        t.lflag.ECHO = !b;
        t.lflag.ICANON = !b;
        try posix.tcsetattr(posix.STDIN_FILENO, .NOW, t);
    }
}

pub fn set_raw_mode_writer(file: *std.Io.File, b: bool) !void {
    if (builtin.os.tag == .windows) {
        const ENABLE_WRAP_AT_EOL_OUTPUT: u32 = 0x0002;
        const ENABLE_VIRTUAL_TERMINAL_PROCESSING: u32 = 0x0004;
        const DISABLE_NEWLINE_AUTO_RETURN: u32 = 0x0008;

        const handle = file.handle;
        var flags: u32 = undefined;
        if (windows.kernel32.GetConsoleMode(handle, &flags) == 0) return error.NotATerminal;
        if (b) {
            flags &= ~(ENABLE_VIRTUAL_TERMINAL_PROCESSING | ENABLE_WRAP_AT_EOL_OUTPUT);
            flags |= (DISABLE_NEWLINE_AUTO_RETURN);
        } else {
            flags |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
            //flags &= ~(ENABLE_VIRTUAL_TERMINAL_INPUT);
        }
        std.debug.assert(windows.kernel32.SetConsoleMode(handle, flags) != 0);
    } else {
        const posix = std.posix;
        var t: posix.termios = try posix.tcgetattr(posix.STDIN_FILENO);

        t.lflag.ECHO = !b;
        t.lflag.ICANON = !b;
        try posix.tcsetattr(posix.STDIN_FILENO, .NOW, t);
    }
}
