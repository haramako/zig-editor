const std = @import("std");
const mem = std.mem;
const Io = std.Io;

const ze = @import("zig_editor");
const FrameBuffer = ze.FrameBuffer;

pub fn main(init: std.process.Init) !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();

    // Parse command line arguments
    var it = try std.process.Args.iterateAllocator(init.minimal.args, gpa);
    defer it.deinit();
    _ = it.next(); // skip program name
    while (it.next()) |arg| {
        if (mem.eql(u8, arg, "--vt100")) {
            try ze.screen.vt100.testVt100();
            return;
        }
    }

    try ze.log.initLog(init.io, gpa);
    defer ze.log.deinitLog(init.io, gpa);

    var app: ze.App = try .init(init.io, gpa);
    defer app.deinit();

    try ze.basic_commands.registerCommands(&app);

    const src = "Hello\nZig Editor\nHow are you?\n";
    try app.current_frame.insertStr(app.current_frame.screen_cursor(), src);

    ze.log.log(.info, .default, "Zig Editor started.", .{});

    try app.setupConsole();
    try ze.mainloop.mainloop(&app);
}
