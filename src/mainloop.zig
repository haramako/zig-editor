const std = @import("std");
const Io = std.Io;

const App = @import("app.zig");
const screen = @import("screen.zig");
const KeySequenceProcessor = @import("key_sequence_processor.zig");
const types = @import("types.zig");
const vt100 = @import("vt100.zig");
const TextFrame = @import("text_frame.zig");

pub fn mainloop(app: *App) !void {
    var ksp = try KeySequenceProcessor.init(app.gpa);
    defer ksp.deinit();

    try updateScreen(app);

    while (true) {
        const c2 = app.stdin().takeByte() catch continue;
        ksp.addByte(c2);

        while (ksp.nextKey()) |c| {
            try processKey(app, c);
            try updateScreen(app);
        }
    }
}

pub fn updateScreen(app: *App) !void {
    try redraw(app);
    try refresh(app.stdout(), &app.fb);
    try app.stdout().print("{f}", .{vt100.pos(app.pos.x + 1, app.pos.y + 1)});
    try app.stdout().flush();
}

pub fn processKey(app: *App, k: types.Key) !void {
    if (app.commands.get(k)) |command| {
        try command(.{ .app = app, .frame = app.current_frame });
    } else {
        switch (k) {
            .Control => |control| {
                std.debug.print("Pressed control key: {}\n", .{control});
            },
            .DisplayCharacter => |c| {
                try app.current_frame.buf.insertStr(10, &[_]u8{c});
                app.pos.x += 1;
            },
        }
    }
}

pub fn redraw(app: *App) !void {
    const text_frame = app.current_frame;
    text_frame.lines.clearAndFree(app.gpa);
    try TextFrame.makeLineCPDList(app.gpa, &text_frame.buf, &text_frame.lines);

    for (text_frame.lines.items, 0..) |line, i| {
        @memcpy(app.fb.items[i][0..line.cpds.items.len], line.cpds.items);
    }
}

pub fn refresh(writer: *Io.Writer, fb: *const types.CPDArray2D) !void {
    for (0..fb.height) |y| {
        _ = try vt100.pos(1, @intCast(y + 1)).format(writer);
        for (0..fb.width) |x| {
            if (fb.get(x, y)) |p| {
                try writer.writeByte(p.chr);
            }
        }
    }
}
