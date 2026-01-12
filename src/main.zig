const std = @import("std");
const mem = std.mem;
const Io = std.Io;

const ze = @import("zig_editor");
const screen = ze.screen;
const arrays = ze.arrays;
const FrameBuffer = ze.FrameBuffer;

pub fn main(init: std.process.Init) !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();

    var it = try std.process.Args.iterateAllocator(init.minimal.args, gpa);
    defer it.deinit();
    _ = it.next(); // skip program name
    while (it.next()) |arg| {
        if (mem.eql(u8, arg, "--vt100")) {
            try ze.vt100.testVt100();
            return;
        }
    }

    var app: ze.App = try .init(init.io, gpa);
    defer app.deinit();

    try ze.basic_commands.registerCommands(&app);

    const src = "Hello\nZig Editor\nHow are you?\n";
    var text_frame = try ze.TextFrame.init(gpa, src);
    defer text_frame.deinit();

    var i: usize = 0;
    for (text_frame.lines.items) |line| {
        @memcpy(app.buf.items[i][0..line.cpds.items.len], line.cpds.items);
        i += 1;
    }

    try ze.mainloop.refresh(app.stdout(), &app.buf);
    _ = try app.stdout().write(screen.vpa(app.pos.x + 1, app.pos.y + 1).str());
    try app.stdout().flush();

    try ze.mainloop.mainloop(&app);
}
