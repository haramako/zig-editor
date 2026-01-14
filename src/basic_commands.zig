const App = @import("app.zig");
const screen = @import("screen.zig");
const types = @import("types.zig");

pub fn do_up(ctx: App.Ctx) !void {
    ctx.frame.?.user_cursor().line -= 1;
}

pub fn do_down(ctx: App.Ctx) !void {
    ctx.frame.?.user_cursor().line += 1;
}

pub fn do_left(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    if (cur.pos > 0) {
        cur.pos -= 1;
    }
}

pub fn do_right(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    if (cur.pos < frame.buf.len()) {
        cur.pos += 1;
    }
}

pub fn do_newline(ctx: App.Ctx) !void {
    ctx.frame.?.user_cursor().column = 0;
    ctx.frame.?.user_cursor().line += 1;
}

pub fn registerCommands(app: *App) !void {
    const Key = types.Key;
    try app.registerCommand(Key{ .Control = .Up }, &do_up);
    try app.registerCommand(Key{ .Control = .Down }, &do_down);
    try app.registerCommand(Key{ .Control = .Left }, &do_left);
    try app.registerCommand(Key{ .Control = .Right }, &do_right);
    try app.registerCommand(Key{ .Control = .NewLine }, &do_newline);
}
