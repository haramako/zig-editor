pub const Buffer = @This();

const std = @import("std");
const mem = std.mem;

pub const Option = struct {
    capacity: ?usize = null,
};

gpa: mem.Allocator,
data: []u8,
gapStart: usize,
gapEnd: usize,

/// A gap buffer implementation.
pub fn init(gpa: mem.Allocator, src: []const u8, opt: Option) !Buffer {
    const data = gpa.alloc(u8, opt.capacity orelse src.len) catch return error.OutOfMemory;
    @memcpy(data[0..src.len], src);
    return Buffer{
        .gpa = gpa,
        .data = data,
        .gapStart = src.len,
        .gapEnd = data.len,
    };
}

/// Deinitialize the buffer and free its resources.
pub fn deinit(self: *@This()) void {
    self.gpa.free(self.data);
}

/// Get the length of the data in the buffer.
pub fn len(self: *const @This()) usize {
    return self.gapStart + (self.data.len - self.gapEnd);
}

/// Get all data in the buffer into the provided output slice.
pub fn allData(self: *@This(), out: []u8) ![]u8 {
    if (out.len < self.len()) {
        return error.BufferTooSmall;
    }
    @memcpy(out[0..self.gapStart], self.data[0..self.gapStart]);
    @memcpy(out[self.gapStart..self.len()], self.data[self.gapEnd..]);
    return out[0..self.len()];
}

/// Get the two slices that represent all data in the buffer.
pub fn allDataSlice(self: *@This(), out: [][]u8) void {
    out[0] = self.data[0..self.gapStart];
    out[1] = self.data[self.gapEnd..];
}

/// Set a new capacity for the buffer.
pub fn setCapacity(self: *@This(), new_capacity: usize) !void {
    if (new_capacity < self.len()) {
        return error.NewCapacityTooSmall;
    }
    const new_data = try self.gpa.alloc(u8, new_capacity);
    errdefer self.gpa.free(new_data);
    const used_len = self.len();
    @memcpy(new_data[0..self.gapStart], self.data[0..self.gapStart]);
    const new_gap_end = new_capacity - (used_len - self.gapStart);
    @memcpy(new_data[new_gap_end..new_capacity], self.data[self.gapEnd..]);
    self.gpa.free(self.data);
    self.data = new_data;
    self.gapEnd = new_gap_end;
}

/// Move the gap to the specified position.
pub fn regap(self: *@This(), pos: usize) !void {
    if (pos == self.gapStart) {
        return;
    } else if (pos < self.gapStart) {
        const move_size = self.gapStart - pos;
        mem.copyBackwards(u8, self.data[self.gapEnd - move_size .. self.gapEnd], self.data[pos..self.gapStart]);
        self.gapStart = pos;
        self.gapEnd -= move_size;
    } else if (pos > self.gapStart and pos <= self.len()) {
        const move_size = pos - self.gapStart;
        mem.copyForwards(u8, self.data[self.gapStart .. self.gapStart + move_size], self.data[self.gapEnd .. self.gapEnd + move_size]);
        self.gapStart += move_size;
        self.gapEnd += move_size;
    } else {
        return error.outOfBounds;
    }
}

pub fn get(self: *const @This(), index: usize) ?u8 {
    if (index < self.gapStart) {
        return self.data[index];
    } else if (index >= self.gapStart and index < self.len()) {
        return self.data[self.gapEnd + (index - self.gapStart)];
    } else {
        return null;
    }
}

pub fn at(self: *@This(), index: usize) ?*u8 {
    if (index < self.gapStart) {
        return &self.data[index];
    } else if (index >= self.gapStart and index < self.len()) {
        return &self.data[self.gapEnd + (index - self.gapStart)];
    } else {
        return null;
    }
}

/// Modify the buffer by removing and inserting data at the specified position.
pub fn modify(self: *@This(), pos: usize, remove: usize, insert: []const u8) !void {
    try self.regap(pos);
    if (remove > 0) {
        if (self.gapStart + remove > self.len()) {
            return error.outOfBounds;
        }
        self.gapEnd += remove;
    }
    const insert_len = insert.len;
    if (insert_len > 0) {
        if (self.gapEnd - self.gapStart < insert_len) {
            const nextLen = @max(self.len() + insert_len, self.data.len * 2);
            try self.setCapacity(nextLen);
        }
        @memcpy(self.data[self.gapStart .. self.gapStart + insert_len], insert);
        self.gapStart += insert_len;
    }
}
/// Insert a string at the specified position.
pub fn insertStr(self: *@This(), pos: usize, insert: []const u8) !void {
    return self.modify(pos, 0, insert);
}

/// Remove `n` bytes at the specified position.
pub fn removeStr(self: *@This(), pos: usize, remove: usize) !void {
    return self.modify(pos, remove, &[_]u8{});
}

test "buffer initialization" {
    const gpa = std.testing.allocator;
    const src = "Hello, Zig!";
    var buf = try Buffer.init(gpa, src, .{ .capacity = 20 });
    defer buf.deinit();

    var dataBuf: [1024]u8 = undefined;
    const data = try buf.allData(&dataBuf);
    try std.testing.expect(mem.eql(u8, data, src));
}

test "buffer expansion" {
    const gpa = std.testing.allocator;
    const src = "Hello, Zig!";
    var buf = try Buffer.init(gpa, src, .{});
    defer buf.deinit();

    try buf.setCapacity(50);
    try std.testing.expect(buf.data.len == 50);

    try buf.setCapacity(src.len);

    buf.setCapacity(src.len - 1) catch |err| {
        try std.testing.expect(err == error.NewCapacityTooSmall);
    };
}

test "buffer regap" {
    const gpa = std.testing.allocator;
    const src = "Hello, Zig!";
    var buf = try Buffer.init(gpa, src, .{});
    defer buf.deinit();

    try buf.setCapacity(20);

    const L = struct {
        fn regapAndCheck(_buf: *Buffer, pos: usize) !void {
            var srcBuf: [1024]u8 = undefined;
            var workBuf: [1024]u8 = undefined;
            const _src = try _buf.allData(&srcBuf);
            try _buf.regap(pos);
            try std.testing.expectEqual(pos, _buf.gapStart);
            try std.testing.expectEqualStrings(_src, try _buf.allData(&workBuf));
        }
    };

    try L.regapAndCheck(&buf, 5);

    // 重なった領域のコピーをテストする
    try L.regapAndCheck(&buf, 0);
    try L.regapAndCheck(&buf, 1);
    try L.regapAndCheck(&buf, src.len - 1);
    try L.regapAndCheck(&buf, src.len);

    try L.regapAndCheck(&buf, src.len - 1);
    try L.regapAndCheck(&buf, 1);
    try L.regapAndCheck(&buf, 0);

    try std.testing.expectError(error.outOfBounds, buf.regap(buf.len() + 1));
}

test "buffer modify" {
    const gpa = std.testing.allocator;
    const src = "Hello, Zig!";
    var buf = try Buffer.init(gpa, src, .{});
    defer buf.deinit();

    // Insert
    try buf.insertStr(5, ", Wonderful");
    var dataBuf: [1024]u8 = undefined;
    var data = try buf.allData(&dataBuf);
    try std.testing.expectEqualStrings(data, "Hello, Wonderful, Zig!");

    // Remove
    try buf.removeStr(5, 11);
    data = try buf.allData(&dataBuf);
    try std.testing.expectEqualStrings(data, "Hello, Zig!");

    // Modify (remove and insert)
    try buf.modify(7, 4, "Zig Programming Language!");
    data = try buf.allData(&dataBuf);
    try std.testing.expectEqualStrings(data, "Hello, Zig Programming Language!");
}
