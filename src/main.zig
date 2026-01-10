const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const Io = std.Io;
const windows = std.os.windows;
const builtin = @import("builtin");

const zig_editor = @import("zig_editor");
const screen = @import("screen.zig");
const arrays = @import("arrays.zig");

const U8Array2D = arrays.Array2D(u8);

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    //var buf: [32]u8 = undefined;
    //const buf2 = try screen.escape(buf[0..], screen.ESC_CUU, 3);
    //std.debug.print("{s} DDD", .{buf2});
    //std.debug.print("{s} DDD", .{screen.Esc(screen.CUU, 0).buf});
    //std.debug.print("{s} DDD", .{screen.Esc(screen.CUU, 4).buf});
    //std.debug.print("{s} ***", .{screen.vpa(3, 5).str()});
    //std.debug.print("\x1b[3;5H ---", .{});

    // In order to allocate memory we must construct an `Allocator` instance.
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit(); // This checks for leaks.
    const gpa = debug_allocator.allocator();

    // In order to do I/O operations we must construct an `Io` instance.
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var stdin = Io.File.stdin();

    try set_raw_mode(&stdin, true);

    var app = try App.init(io, gpa);

    var stdin_buffer: [8]u8 = undefined;
    var stdin_file_reader = stdin.reader(io, &stdin_buffer);
    var stdin_reader = &stdin_file_reader.interface;

    var ksp = try screen.KeySequenceProcessor.init(init.gpa);
    defer ksp.deinit();

    while (true) {
        //if (stdin_reader.peekByte()) |_| {
        const c2 = stdin_reader.takeByte() catch continue;
        ksp.addByte(c2);

        while (ksp.nextKey()) |c| {
            app.processKey(c);
            //arr.set(0, 0, c);
            //try refresh(stdout_writer, &arr);
            try refresh(stdout_writer, &app.buf);
        }
    }

    try stdout_writer.flush(); // Don't forget to flush!
}

const Point = struct {
    x: i32,
    y: i32,
};

pub const App = struct {
    io: Io,
    gpa: mem.Allocator,
    buf: U8Array2D,
    pos: Point,

    pub fn init(io: Io, gpa: mem.Allocator) !App {
        var buf = try U8Array2D.init(gpa, 40, 30);
        buf.fill(' ');
        return App{ .io = io, .gpa = gpa, .buf = buf, .pos = Point{ .x = 10, .y = 10 } };
    }

    pub fn deinit(self: *@This()) void {
        self.buf.deinit();
    }

    pub fn processKey(self: *@This(), c: u8) void {
        switch (c) {
            @intFromEnum(screen.KeyCode.Up) => {
                self.pos.y -= 1;
                self.buf.at(@intCast(self.pos.x), @intCast(self.pos.y)).* = '@';
            },
            @intFromEnum(screen.KeyCode.Down) => {
                self.pos.y += 1;
                self.buf.at(@intCast(self.pos.x), @intCast(self.pos.y)).* = '@';
            },
            @intFromEnum(screen.KeyCode.Left) => {
                self.pos.x -= 1;
                self.buf.at(@intCast(self.pos.x), @intCast(self.pos.y)).* = '@';
            },
            @intFromEnum(screen.KeyCode.Right) => {
                self.pos.x += 1;
                self.buf.at(@intCast(self.pos.x), @intCast(self.pos.y)).* = '@';
            },
            else => {
                debug.print("Pressed key: {c}\n", .{c});
            },
        }
    }
};

fn set_raw_mode(file: *Io.File, b: bool) !void {
    if (builtin.os.tag == .windows) {
        const ENABLE_PROCESSED_INPUT: u32 = 0x0001;
        const ENABLE_ECHO_INPUT: u32 = 0x0004;
        const ENABLE_LINE_INPUT: u32 = 0x0002;
        const ENABLE_VIRTUAL_TERMINAL_INPUT: u32 = 0x0200;

        const handle = file.handle;
        var flags: u32 = undefined;
        if (windows.kernel32.GetConsoleMode(handle, &flags) == 0) return error.NotATerminal;
        if (b) {
            flags &= ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT);
            flags |= (ENABLE_VIRTUAL_TERMINAL_INPUT);
        } else {
            flags |= ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT | ENABLE_VIRTUAL_TERMINAL_INPUT;
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

fn refresh(writer: *Io.Writer, fb: *const U8Array2D) !void {
    const w = fb.width;
    const h = fb.height;
    for (0..h) |y| {
        _ = try writer.write(screen.vpa(0, @intCast(y)).str());
        for (0..w) |x| {
            if (fb.get(x, y)) |p| {
                try writer.writeByte(p.*);
            }
        }
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
