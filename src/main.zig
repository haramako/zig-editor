const std = @import("std");
const mem = std.mem;
const Io = std.Io;

const ze = @import("zig_editor");
const corelib = @import("corelib");
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

    try corelib.log.initLog(init.io, gpa);
    defer corelib.log.deinitLog(init.io, gpa);

    var app: ze.App = try .init(init.io, gpa);
    defer app.deinit();

    try ze.basic_commands.registerCommands(&app);

    const src = "Hello\nZig Editor\nHow are you?\n";
    for (0..100) |i| {
        var buf: [32]u8 = undefined;
        const line = try std.fmt.bufPrint(&buf, "{d}\n", .{i});
        try app.current_frame.insertStr(app.current_frame.user_cursor(), line);
    }
    try app.current_frame.insertStr(app.current_frame.screen_cursor(), src);

    corelib.log.info("Zig Editor started.", .{});

    try app.setupConsole();
    defer {
        app.stdout().print("{f}", .{ze.screen.vt100.pos(1, @intCast(app.fb.height))}) catch unreachable;
        app.stdout().print("END\n", .{}) catch unreachable;
        app.stdout().flush() catch unreachable;

        ze.screen.screen.set_raw_mode_writer(&app.stdout_file_writer.file, false) catch unreachable;
    }

    ze.mainloop.mainloop(&app) catch |err| {
        if (err == error.QuitApp) {
            return;
        } else {
            corelib.log.err("Error in main loop: {any}", .{err});
            return err;
        }
    };
}
