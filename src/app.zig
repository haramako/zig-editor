const App = @This();

const std = @import("std");
const Io = std.Io;
const mem = std.mem;
const deque = @import("deque.zig");
const arrays = @import("arrays.zig");
const screen = @import("screen.zig");
const types = @import("types.zig");
const TextFrame = @import("text_frame.zig");

const CharacterArray2D = types.CPDArray2D;
const Character = types.CPD;

pub const Ctx = struct {
    app: *App,
    frame: ?*TextFrame,
};

pub const Point = struct {
    x: i32,
    y: i32,
};

pub const CommandFunc = *const fn (ctx: Ctx) anyerror!void;

io: Io,
gpa: mem.Allocator,
buf: CharacterArray2D,
pos: Point,

stdout_buffer: []u8,
stdout_file_writer: Io.File.Writer,
stdin_buffer: []u8,
stdin_file_reader: Io.File.Reader,

current_frame: ?*TextFrame = null,

commands: std.AutoHashMap(screen.Key, CommandFunc),

pub fn init(io: Io, gpa: mem.Allocator) !App {
    var stdout_file = Io.File.stdout();
    var size: screen.ConsoleInfo = undefined;
    if (screen.getConsoleInfo(&stdout_file)) |info| {
        size = info;
    } else {
        size = .{ .width = 80, .height = 25 };
    }

    var buf: CharacterArray2D = try .init(gpa, @intCast(size.width), @intCast(size.height));
    buf.fill(Character{ .chr = ' ', .attr = 0, .color = 0 });

    const pos: Point = .{ .x = 10, .y = 10 };

    //var stdout_file = Io.File.stdout();
    try screen.set_raw_mode_writer(&stdout_file, true);
    const stdout_buffer = try gpa.alloc(u8, 1024);
    const stdout_file_writer: Io.File.Writer = .init(stdout_file, io, stdout_buffer);

    var stdin_file = Io.File.stdin();
    try screen.set_raw_mode(&stdin_file, true);
    const stdin_buffer = try gpa.alloc(u8, 1024);
    const stdin_file_reader: Io.File.Reader = .init(stdin_file, io, stdin_buffer);

    const commands = std.AutoHashMap(screen.Key, CommandFunc).init(gpa);

    return App{
        .io = io,
        .gpa = gpa,
        .buf = buf,
        .pos = pos,
        .stdout_buffer = stdout_buffer,
        .stdout_file_writer = stdout_file_writer,
        .stdin_buffer = stdin_buffer,
        .stdin_file_reader = stdin_file_reader,
        .commands = commands,
    };
}

pub fn deinit(self: *@This()) void {
    self.buf.deinit();
    self.gpa.free(self.stdout_buffer);
    self.gpa.free(self.stdin_buffer);
}

pub fn stdin(self: *@This()) *Io.Reader {
    return &self.stdin_file_reader.interface;
}

pub fn stdout(self: *@This()) *Io.Writer {
    return &self.stdout_file_writer.interface;
}

pub fn registerCommand(self: *@This(), key: screen.Key, command: CommandFunc) !void {
    self.commands.put(key, command) catch {
        return error.commandRegistrationFailed;
    };
}
