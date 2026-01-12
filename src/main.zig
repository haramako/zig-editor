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
            try ze.vt100.testVt100();
            return;
        }
    }

    const tf = try ze.TextFrame.init(gpa, "");
    _ = tf;

    var app: ze.App = try .init(init.io, gpa);
    defer app.deinit();

    //try app.setupConsole();
    try ze.basic_commands.registerCommands(&app);

    const src = "Hello\nZig Editor\nHow are you?\n";
    var text_frame = app.current_frame;
    try text_frame.buf.insertStr(0, src);

    if (false) {
        try ze.TextFrame.makeLineCPDList(gpa, &text_frame.buf, &text_frame.lines);

        var i: usize = 0;
        for (text_frame.lines.items) |line| {
            @memcpy(app.fb.items[i][0..line.cpds.items.len], line.cpds.items);
            i += 1;
        }

        try ze.mainloop.refresh(app.stdout(), &app.fb);
        _ = try ze.vt100.pos(app.pos.x + 1, app.pos.y + 1).format(app.stdout());
        try app.stdout().flush();
    }

    try ze.mainloop.mainloop(&app);
}

test "hoge" {
    const gpa = std.testing.allocator;
    var tf = try ze.TextFrame.init(gpa, "");
    defer tf.deinit();

    try std.testing.expect(true);
}
