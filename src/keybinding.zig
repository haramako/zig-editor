const std = @import("std");
const mem = std.mem;

const types = @import("types.zig");
const key_sequence_processor = @import("key_sequence_processor.zig");

pub const KeyBinding = struct {
    len: usize = undefined,
    sequence: [4]types.Key = .{ .None, .None, .None, .None },
    pub fn init(sequence: []types.Key) !KeyBinding {
        var new_sequence: [4]types.Key = undefined;
        @memcpy(new_sequence[0..sequence.len], sequence);
        return .{ .len = sequence.len, .sequence = new_sequence };
    }

    pub fn compare(a: KeyBinding, b: KeyBinding) std.math.Order {
        const len = @min(a.len, b.len);
        for (a.sequence[0..len], b.sequence[0..len]) |ka, kb| {
            const ord = types.Key.compare(ka, kb);
            if (ord != .eq) {
                return ord;
            }
        }
        return std.math.order(a.len, b.len);
    }
};

/// Parses a key binding string into a KeyBinding struct.
/// Example:
///   "up" -> KeyBinding{ .sequence = [.{ .Command = .Up }] }
///   "C-x M-s" -> KeyBinding{ .sequence = [.{ .Control = 'X' }, .{ .Alt = 's' }] }
pub fn parseKeyBinding(_str: []const u8) !KeyBinding {
    const str = std.mem.trimStart(u8, _str, " ");
    var keys: [4]types.Key = undefined;
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

    return KeyBinding.init(keys[0..count]);
}

const t = std.testing;
test "parseKeyBinding" {
    var kb1 = try parseKeyBinding("Up Down C-x M-s");

    try t.expectEqual(4, kb1.sequence.len);
    try t.expectEqual(types.Key{ .Command = .Up }, kb1.sequence[0]);
    try t.expectEqual(types.Key{ .Command = .Down }, kb1.sequence[1]);
    try t.expectEqual(types.Key{ .Control = 'X' }, kb1.sequence[2]);
    try t.expectEqual(types.Key{ .Alt = 's' }, kb1.sequence[3]);
}
