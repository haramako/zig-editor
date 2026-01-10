const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const Io = std.Io;

const zig_editor = @import("zig_editor");
const screen = @import("screen.zig");
const arrays = @import("arrays.zig");
const App = @import("app.zig");

pub fn main(init: std.process.Init) !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();

    var app: App = try .init(init.io, gpa);
    defer app.deinit();

    var ksp = try screen.KeySequenceProcessor.init(init.gpa);
    defer ksp.deinit();

    while (true) {
        const c2 = app.stdin().takeByte() catch continue;
        ksp.addByte(c2);

        while (ksp.nextKey()) |c| {
            processKey(&app, c);
            try refresh(app.stdout(), &app.buf);
        }
    }
}

pub fn processKey(self: *App, c: u8) void {
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

fn refresh(writer: *Io.Writer, fb: *const App.U8Array2D) !void {
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
