//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;
const arrays = @import("arrays.zig");

pub const types = @import("types.zig");
pub const FrameBuffer = @import("frame_buffer.zig");
pub const App = @import("app.zig");
pub const screen = @import("screen.zig");
pub const Buffer = @import("buffer.zig");
pub const TextFrame = @import("text_frame.zig");
pub const vt100 = @import("vt100.zig");

/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    var buf = try Buffer.init(std.testing.allocator, "Hello", .{});
    defer buf.deinit();
    try std.testing.expect(add(3, 7) == 10);
}
