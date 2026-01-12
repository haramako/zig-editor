const std = @import("std");
const mem = std.mem;
const Io = std.Io;

const zig_editor = @import("zig_editor");
const screen = zig_editor.screen;
const arrays = zig_editor.arrays;
const FrameBuffer = zig_editor.FrameBuffer;

pub fn main(init: std.process.Init) !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();

    var it = try std.process.Args.iterateAllocator(init.minimal.args, gpa);
    defer it.deinit();
    _ = it.next(); // skip program name
    while (it.next()) |arg| {
        if (mem.eql(u8, arg, "--vt100")) {
            try zig_editor.vt100.testVt100();
            return;
        }
    }

    var app: zig_editor.App = try .init(init.io, gpa);
    defer app.deinit();

    var ksp = try screen.KeySequenceProcessor.init(init.gpa);
    defer ksp.deinit();

    const src = "Hello\nZig Editor\nHow are you?\n";
    var text_frame = try zig_editor.TextFrame.init(gpa, src);
    defer text_frame.deinit();

    var i: usize = 0;
    for (text_frame.lines.items) |line| {
        @memcpy(app.buf.items[i][0..line.cpds.items.len], line.cpds.items);
        i += 1;
    }

    try refresh(app.stdout(), &app.buf);
    _ = try app.stdout().write(screen.vpa(app.pos.x + 1, app.pos.y + 1).str());
    try app.stdout().flush();

    while (true) {
        const c2 = app.stdin().takeByte() catch continue;
        ksp.addByte(c2);

        while (ksp.nextKey()) |c| {
            processKey(&app, c);
            try refresh(app.stdout(), &app.buf);
            _ = try app.stdout().write(screen.vpa(app.pos.x + 1, app.pos.y + 1).str());
            try app.stdout().flush();
        }
    }
}

pub fn processKey(self: *zig_editor.App, c: u8) void {
    switch (c) {
        @intFromEnum(screen.KeyCode.Up) => {
            self.pos.y -= 1;
        },
        @intFromEnum(screen.KeyCode.Down) => {
            self.pos.y += 1;
        },
        @intFromEnum(screen.KeyCode.Left) => {
            self.pos.x -= 1;
        },
        @intFromEnum(screen.KeyCode.Right) => {
            self.pos.x += 1;
        },
        else => {
            self.buf.at(@intCast(self.pos.x), @intCast(self.pos.y)).chr = c;
            self.pos.x += 1;
            //debug.print("Pressed key: {c}\n", .{c});
        },
    }
}

fn refresh(writer: *Io.Writer, fb: *const zig_editor.types.CPDArray2D) !void {
    const w = fb.width;
    const h = fb.height;
    for (0..h) |y| {
        _ = try writer.write(screen.vpa(1, @intCast(y + 1)).str());
        for (0..w) |x| {
            if (fb.get(x, y)) |p| {
                try writer.writeByte(p.chr);
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
