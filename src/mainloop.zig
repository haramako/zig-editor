const std = @import("std");
const Io = std.Io;

const App = @import("app.zig");
const log = @import("lib/log.zig");
const screen = @import("screen.zig");
const keybinding = @import("keybinding.zig");
const types = @import("types.zig");
const vt100 = screen.vt100;
const TextFrame = @import("text_frame.zig");
const bufutil = @import("bufutil.zig");
const basic_commands = @import("basic_commands.zig");

pub fn mainloop(app: *App) !void {
    var ksp = try screen.KeySequenceProcessor.init(app.gpa);
    defer ksp.deinit();

    try updateScreen(app);

    var buf_len: usize = 0;
    var buf: [4]screen.Key = undefined;

    while (true) {
        const c2 = app.stdin().takeByte() catch continue;
        ksp.addByte(c2);

        while (ksp.nextKey()) |c| {
            if (buf_len >= buf.len) {
                buf_len = 0;
                continue;
                //return error.OutOfKeyBuffer;
            }
            buf[buf_len] = c;
            buf_len = buf_len + 1;

            const kb = try keybinding.KeyBinding.init(buf[0..buf_len]);

            const consumed = processKey(app, kb) catch break;
            if (consumed) {
                buf_len = 0;
            }
        }
        try updateScreen(app);
    }
}

pub fn updateScreen(app: *App) !void {
    try updateCursors(app);
    try redraw(app);
    try refresh(app.stdout(), &app.fb);

    if (log.logList.items.len > 0) {
        app.stdout().print("{f}{s}", .{ vt100.pos(@intCast(1), @intCast(app.fb.height)), log.logList.items[log.logList.items.len - 1] }) catch {};
    }

    const frame = app.current_frame;
    const cur = frame.user_cursor();
    const column = cur.column;
    const line = cur.line;
    try app.stdout().print("{f}", .{vt100.pos(@intCast(column + 1), @intCast(line + 1))});

    try app.stdout().flush();
}

pub fn updateCursors(app: *App) !void {
    var frame = app.current_frame;
    for (frame.cursors.items) |*cur| {
        try frame.updateCursor(cur, cur.pos);
    }
}

fn comp2(context: keybinding.KeyBinding, key: App.KeyBindingCommand) std.math.Order {
    return keybinding.KeyBinding.compare(context, key.key);
}

fn lessThan(_: void, a: App.KeyBindingCommand, b: App.KeyBindingCommand) bool {
    return keybinding.KeyBinding.compare(a.key, b.key) == .lt;
}

pub fn processKey(app: *App, k: keybinding.KeyBinding) !bool {
    std.sort.heap(App.KeyBindingCommand, app.commands.items, {}, lessThan);

    const idx = std.sort.lowerBound(App.KeyBindingCommand, app.commands.items, k, comp2);
    if (idx < app.commands.items.len) {
        const command = app.commands.items[idx];
        if (keybinding.KeyBinding.compare(k, command.key) == .eq) {
            try command.func(.{ .app = app, .frame = app.current_frame, .key = k.sequence[0] });
            return true;
        } else {
            const k2 = k.sequence[k.len - 1];
            switch (k2) {
                .Control => |key| {
                    if (key == 'G') {
                        // Clear the key buffer on Ctrl+G
                        log.info("Canceled", .{});
                        return true;
                    }
                },
                else => {},
            }
            if (k.len == 1) {
                switch (k.sequence[0]) {
                    .None => {
                        return false;
                    },
                    .Alt => |alt| {
                        log.warn("Pressed Alt+{c}", .{alt});
                        return false;
                    },
                    .Control => |control| {
                        log.warn("Pressed Ctrl+{c}", .{control});
                        return false;
                    },
                    .Command => |cmd| {
                        log.warn("Pressed command key: {}", .{cmd});
                        return false;
                    },
                    .DisplayCharacter => {
                        try basic_commands.do_insert(.{ .app = app, .frame = app.current_frame, .key = k.sequence[0] });
                        return true;
                    },
                }
            } else {
                return false;
            }
        }
    } else {
        return false;
    }
}

pub fn redraw(app: *App) !void {
    app.fb.fill(.{ .chr = ' ', .attr = 0, .color = 0 });
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
