const App = @This();

const std = @import("std");
const Io = std.Io;
const mem = std.mem;
const corelib = @import("corelib");
const deque = corelib.deque;
const arrays = corelib.arrays;
const screen = @import("screen");
const types = @import("types.zig");
const TextFrame = @import("text_frame.zig");
const keybinding = @import("keybinding.zig");

const CharacterArray2D = types.CPDArray2D;
const Character = screen.CPD;

pub const Ctx = struct {
    app: *App,
    frame: ?*TextFrame,
    key: screen.Key,
};

pub const Point = struct {
    x: i32,
    y: i32,
};

pub const CommandFunc = *const fn (ctx: Ctx) anyerror!void;

pub const KeyBindingCommand = struct {
    key: keybinding.KeyBinding,
    func: CommandFunc,
};

io: Io,
gpa: mem.Allocator,
fb: CharacterArray2D,

stdout_buffer: []u8,
stdout_file_writer: Io.File.Writer,
stdin_buffer: []u8,
stdin_file_reader: Io.File.Reader,

current_frame: *TextFrame,

commands: std.ArrayList(KeyBindingCommand),

pub fn init(io: Io, gpa: mem.Allocator) !App {
    var stdout_file = Io.File.stdout();
    const stdout_buffer = try gpa.alloc(u8, 4096);
    const stdout_file_writer: Io.File.Writer = .init(stdout_file, io, stdout_buffer);

    const stdin_file = Io.File.stdin();
    const stdin_buffer = try gpa.alloc(u8, 4096);
    const stdin_file_reader: Io.File.Reader = .init(stdin_file, io, stdin_buffer);

    var size: screen.screen.ConsoleInfo = undefined;
    if (screen.screen.getConsoleInfo(&stdout_file)) |info| {
        size = info;
    } else {
        size = .{ .width = 80, .height = 25 };
    }

    var buf: CharacterArray2D = try .init(gpa, @intCast(size.width), @intCast(size.height));
    buf.fill(Character{ .chr = ' ', .attr = 0, .color = 0 });

    const commands = try std.ArrayList(KeyBindingCommand).initCapacity(gpa, 100);

    const current_frame = try gpa.create(TextFrame);
    current_frame.* = try TextFrame.init(gpa, "");

    return App{
        .io = io,
        .gpa = gpa,
        .fb = buf,
        .stdout_buffer = stdout_buffer,
        .stdout_file_writer = stdout_file_writer,
        .stdin_buffer = stdin_buffer,
        .stdin_file_reader = stdin_file_reader,
        .commands = commands,
        .current_frame = current_frame,
    };
}

pub fn setupConsole(self: *@This()) !void {
    try screen.screen.set_raw_mode_writer(&self.stdout_file_writer.file, true);
    try screen.screen.set_raw_mode(&self.stdin_file_reader.file, true);
}

pub fn deinit(self: *@This()) void {
    self.fb.deinit();
    self.gpa.free(self.stdout_buffer);
    self.gpa.free(self.stdin_buffer);
}

pub fn stdin(self: *@This()) *Io.Reader {
    return &self.stdin_file_reader.interface;
}

pub fn stdout(self: *@This()) *Io.Writer {
    return &self.stdout_file_writer.interface;
}

pub fn registerCommandKey(self: *@This(), keyStr: []const u8, command: CommandFunc) !void {
    const key = try keybinding.parseKeyBinding(keyStr);
    try self.registerCommand(key, command);
}

pub fn registerCommand(self: *@This(), key: keybinding.KeyBinding, command: CommandFunc) !void {
    try self.commands.append(self.gpa, .{ .key = key, .func = command });
}
