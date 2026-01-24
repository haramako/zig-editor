const std = @import("std");

pub var logList: std.ArrayList([]const u8) = undefined;
pub var savedGpa: std.mem.Allocator = undefined;

pub fn debug(
    comptime format: []const u8,
    args: anytype,
) void {
    log(.debug, .default, format, args);
}

pub fn info(
    comptime format: []const u8,
    args: anytype,
) void {
    log(.info, .default, format, args);
}

pub fn warn(
    comptime format: []const u8,
    args: anytype,
) void {
    log(.warn, .default, format, args);
}

pub fn err(
    comptime format: []const u8,
    args: anytype,
) void {
    log(.err, .default, format, args);
}

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    _ = scope;
    const msg = std.fmt.allocPrint(savedGpa, format, args) catch return;
    logList.append(savedGpa, msg) catch {};

    logWriter.print("{s}\n", .{msg}) catch {};
    logWriter.flush() catch {};
}

var initialized: bool = false;
var logBuffer: [1024]u8 = undefined;
var logFile: std.Io.File = undefined;
var logFileWriter: std.Io.File.Writer = undefined;
var logWriter: *std.Io.Writer = undefined;

pub fn initLog(io: std.Io, gpa: std.mem.Allocator) !void {
    savedGpa = gpa;
    logList = try std.ArrayList([]const u8).initCapacity(gpa, 1024);
    errdefer logList.deinit(gpa);

    logFile = try std.Io.Dir.cwd().createFile(io, "zig_editor.log", .{ .truncate = true });
    errdefer logFile.close(io);

    logFileWriter = logFile.writer(io, &logBuffer);
    logWriter = &logFileWriter.interface;

    try logWriter.print("HOGE\n", .{});
    try logWriter.flush();

    initialized = true;
}

pub fn deinitLog(io: std.Io, gpa: std.mem.Allocator) void {
    if (!initialized) return;

    logWriter.flush() catch {};
    logFile.close(io);

    for (logList.items) |msg| {
        gpa.free(msg);
    }
    logList.deinit(gpa);
}
