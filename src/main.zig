const std = @import("std");
const Io = std.Io;

const zig_editor = @import("zig_editor");
const screen = @import("screen.zig");
const arrays = @import("arrays.zig");

const U8Array2D = arrays.Array2D(u8);

pub fn main() !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    //var buf: [32]u8 = undefined;
    //const buf2 = try screen.escape(buf[0..], screen.ESC_CUU, 3);
    //std.debug.print("{s} DDD", .{buf2});
    //std.debug.print("{s} DDD", .{screen.Esc(screen.CUU, 0).buf});
    //std.debug.print("{s} DDD", .{screen.Esc(screen.CUU, 4).buf});
    //std.debug.print("{s} ***", .{screen.vpa(3, 5).str()});
    //std.debug.print("\x1b[3;5H ---", .{});

    // In order to allocate memory we must construct an `Allocator` instance.
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit(); // This checks for leaks.
    const gpa = debug_allocator.allocator();

    // In order to do I/O operations we must construct an `Io` instance.
    var threaded: std.Io.Threaded = .init(gpa, .{});
    defer threaded.deinit();
    const io = threaded.io();

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try zig_editor.printAnotherMessage(stdout_writer);

    var arr = try U8Array2D.init(gpa, 40, 30);
    defer arr.deinit();
    arr.fill(' ');

    screen.hoge();

    try refresh(stdout_writer, &arr);

    try stdout_writer.flush(); // Don't forget to flush!
}

fn refresh(writer: *Io.Writer, fb: *const U8Array2D) !void {
    const w = fb.width;
    const h = fb.height;
    for (0..h) |y| {
        _ = try writer.write(screen.vpa(0, @intCast(y)).str());
        for (0..w) |x| {
            if (fb.get(x, y)) |p| {
                try writer.writeByte(p.*);
            }
        }
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
