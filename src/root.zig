const std = @import("std");
pub const arrays = @import("lib/arrays.zig");
pub const dequeue = @import("lib/deque.zig");

pub const types = @import("types.zig");
pub const App = @import("app.zig");
pub const key_sequence_processor = @import("key_sequence_processor.zig");
pub const screen = @import("screen.zig");
pub const Buffer = @import("buffer.zig");
pub const TextFrame = @import("text_frame.zig");
pub const vt100 = @import("vt100.zig");
pub const basic_commands = @import("basic_commands.zig");
pub const mainloop = @import("mainloop.zig");

test "hoge" {
    const gpa = std.testing.allocator;
    var tf = try TextFrame.init(gpa, "");
    defer tf.deinit();

    try std.testing.expect(true);
}
