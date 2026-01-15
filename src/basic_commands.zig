const App = @import("app.zig");
const screen = @import("screen.zig");
const types = @import("types.zig");
const bufutil = @import("bufutil.zig");

pub fn do_up(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    const head1 = try bufutil.lineHead(&frame.buf, cur.pos);
    if (head1 == 0) {
        cur.pos = 0;
        return;
    }
    const head2 = try bufutil.lineHead(&frame.buf, head1 - 1);
    cur.pos = @min(head1, head2 + cur.column);
}

pub fn do_down(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    const tail = try bufutil.lineTail(&frame.buf, cur.pos) + 1;
    cur.pos = tail + cur.column;
    if (tail >= frame.buf.len()) {
        cur.pos = frame.buf.len();
    }
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
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    try frame.insertStr(cur, &[_]u8{'\n'});
    cur.pos += 1;
}

pub fn do_insert(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    const c = ctx.key.DisplayCharacter;
    try frame.insertStr(cur, &[_]u8{c});
    cur.pos += 1;
}

pub fn registerCommands(app: *App) !void {
    const Key = types.Key;
    try app.registerCommand(Key{ .Control = .Up }, &do_up);
    try app.registerCommand(Key{ .Control = .Down }, &do_down);
    try app.registerCommand(Key{ .Control = .Left }, &do_left);
    try app.registerCommand(Key{ .Control = .Right }, &do_right);
    try app.registerCommand(Key{ .Control = .NewLine }, &do_newline);
    //try app.registerCommand(Key{ .Control = .NewLine }, &do_insert);
}
