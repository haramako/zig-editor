const std = @import("std");

const App = @import("app.zig");
const screen = @import("screen.zig");
const types = @import("types.zig");
const log = @import("log.zig");
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
    log.log(.info, .default, "Pressed key: {any}", .{ctx.key});
}

pub fn do_save(ctx: App.Ctx) !void {
    const frame = ctx.frame.?;
    _ = frame;
    //try frame.saveToFile();
    log.log(.info, .default, "File saved.", .{});
}

pub fn registerCommands(app: *App) !void {
    try app.registerCommandKey("Up", &do_up);
    try app.registerCommandKey("Down", &do_down);
    try app.registerCommandKey("Left", &do_left);
    try app.registerCommandKey("Right", &do_right);
    try app.registerCommandKey("NewLine", &do_newline);
    try app.registerCommandKey("Backspace", &do_backspace);
    try app.registerCommandKey("Delete", &do_delete);
    try app.registerCommandKey("PageUp", &do_nothing);
    try app.registerCommandKey("PageDown", &do_nothing);

    try app.registerCommandKey("C-P", &do_up);
    try app.registerCommandKey("C-N", &do_down);
    try app.registerCommandKey("C-B", &do_left);
    try app.registerCommandKey("C-F", &do_right);
    try app.registerCommandKey("C-H", &do_backspace);
    try app.registerCommandKey("C-J", &do_newline);

    try app.registerCommandKey("C-x C-s", &do_save);
}
