const App = @import("app.zig");
const screen = @import("screen.zig");

pub fn do_up(ctx: App.Ctx) !void {
    ctx.app.pos.y -= 1;
}

pub fn do_down(ctx: App.Ctx) !void {
    ctx.app.pos.y += 1;
}

pub fn do_left(ctx: App.Ctx) !void {
    ctx.app.pos.x -= 1;
}

pub fn do_right(ctx: App.Ctx) !void {
    ctx.app.pos.x += 1;
}

pub fn do_newline(ctx: App.Ctx) !void {
    ctx.app.pos.x = 0;
    ctx.app.pos.y += 1;
}

pub fn registerCommands(app: *App) !void {
    const Key = screen.Key;
    try app.registerCommand(Key{ .Control = .Up }, &do_up);
    try app.registerCommand(Key{ .Control = .Down }, &do_down);
    try app.registerCommand(Key{ .Control = .Left }, &do_left);
    try app.registerCommand(Key{ .Control = .Right }, &do_right);
    try app.registerCommand(Key{ .Control = .NewLine }, &do_newline);
}
