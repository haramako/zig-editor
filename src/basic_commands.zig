const std = @import("std");

const App = @import("app.zig");
const screen = @import("screen.zig");
const types = @import("types.zig");
const bufutil = @import("bufutil.zig");
const TextFrame = @import("text_frame.zig");

pub fn do_up(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    try TextFrame.moveCursorUp(frame, cur);
}

pub fn do_down(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    try TextFrame.moveCursorDown(frame, cur);
}

pub fn do_left(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    try TextFrame.moveCursorLeft(frame, cur);
}

pub fn do_right(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    try TextFrame.moveCursorRight(frame, cur);
}

pub fn do_newline(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    try frame.insertStr(cur, &[_]u8{'\n'});
    cur.pos += 1;
}

pub fn do_backspace(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    if (cur.pos == 0) {
        return;
    }
    cur.pos -= 1;
    try frame.removeStr(cur, 1);
}

pub fn do_delete(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    try frame.removeStr(cur, 1);
}

pub fn do_insert(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    const c = ctx.key.DisplayCharacter;
    try frame.insertStr(cur, &[_]u8{c});
    cur.pos += 1;
}

pub fn do_nothing(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    const cur = frame.user_cursor();
    var buf: [256]u8 = undefined;
    const str = try std.fmt.bufPrint(&buf, "Press {any}\n", .{ctx.key});
    try frame.insertStr(cur, str);
}

pub fn registerCommands(app: *App) !void {
    const Key = types.Key;
    try app.registerCommand(Key{ .Control = .Up }, &do_up);
    try app.registerCommand(Key{ .Control = .Down }, &do_down);
    try app.registerCommand(Key{ .Control = .Left }, &do_left);
    try app.registerCommand(Key{ .Control = .Right }, &do_right);
    try app.registerCommand(Key{ .Control = .NewLine }, &do_newline);
    try app.registerCommand(Key{ .Control = .Backspace }, &do_backspace);
    try app.registerCommand(Key{ .Control = .Delete }, &do_delete);
    try app.registerCommand(Key{ .Control = .PageUp }, &do_nothing);
    try app.registerCommand(Key{ .Control = .PageDown }, &do_nothing);
}
