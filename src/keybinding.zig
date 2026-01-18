const std = @import("std");
const mem = std.mem;

const types = @import("types.zig");
const key_sequence_processor = @import("key_sequence_processor.zig");

const KeyBinding = struct {
    sequence: []types.Key,
    pub fn init(gpa: std.mem.Allocator, sequence: []types.Key) !KeyBinding {
        const new_sequence = try gpa.alloc(types.Key, sequence.len);
        @memcpy(new_sequence, sequence);
        return .{ .sequence = new_sequence };
    }
    pub fn deinit(self: *KeyBinding, gpa: std.mem.Allocator) void {
        gpa.free(self.sequence);
    }
};

/// Parses a key binding string into a KeyBinding struct.
/// Example:
///   "up" -> KeyBinding{ .sequence = [.{ .Command = .Up }] }
///   "C-x M-s" -> KeyBinding{ .sequence = [.{ .Control = 'X' }, .{ .Alt = 's' }] }
pub fn parseKeyBinding(gpa: std.mem.Allocator, _str: []const u8) !KeyBinding {
    const str = std.mem.trimStart(u8, _str, " ");
    var keys: [8]types.Key = undefined;
    var count: usize = 0;
    var iterator = std.mem.splitAny(u8, str, " ");
    while (iterator.next()) |part| {
        //std.debug.print("Parsing key part: '{s}'\n", .{part});
        const key = try key_sequence_processor.parseKey(part);
        if (count >= keys.len) {
            return std.mem.Allocator.Error.OutOfMemory;
        }
        keys[count] = key;
        count += 1;
    }

    return KeyBinding.init(gpa, keys[0..count]);
}

const t = std.testing;
test "parseKeyBinding" {
    const gpa = std.testing.allocator;
    var kb1 = try parseKeyBinding(gpa, "Up Down C-x M-s");
    defer kb1.deinit(gpa);

    try t.expectEqual(4, kb1.sequence.len);
    try t.expectEqual(types.Key{ .Command = .Up }, kb1.sequence[0]);
    try t.expectEqual(types.Key{ .Command = .Down }, kb1.sequence[1]);
    try t.expectEqual(types.Key{ .Control = 'X' }, kb1.sequence[2]);
    try t.expectEqual(types.Key{ .Alt = 's' }, kb1.sequence[3]);
}
