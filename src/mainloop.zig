const std = @import("std");
const Io = std.Io;

const App = @import("app.zig");
const screen = @import("screen.zig");
const types = @import("types.zig");

pub fn mainloop(app: *App) !void {
    var ksp = try screen.KeySequenceProcessor.init(app.gpa);
    defer ksp.deinit();

    while (true) {
        const c2 = app.stdin().takeByte() catch continue;
        ksp.addByte(c2);

        while (ksp.nextKey()) |c| {
            try processKey(app, c);
            try refresh(app.stdout(), &app.buf);
            _ = try app.stdout().write(screen.vpa(app.pos.x + 1, app.pos.y + 1).str());
            try app.stdout().flush();
        }
    }
}

pub fn processKey(app: *App, k: screen.Key) !void {
    if (app.commands.get(k)) |command| {
        try command(.{ .app = app, .frame = app.current_frame });
    } else {
        switch (k) {
            .Control => |control| {
                std.debug.print("Pressed control key: {}\n", .{control});
            },
            .DisplayCharacter => |c| {
                app.buf.at(@intCast(app.pos.x), @intCast(app.pos.y)).chr = c;
                app.pos.x += 1;
            },
        }
    }
}

pub fn refresh(writer: *Io.Writer, fb: *const types.CPDArray2D) !void {
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
