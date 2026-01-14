const TextFrame = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const types = @import("types.zig");
const Buffer = @import("buffer.zig");

const CPD = types.CPD;
const LineCPD = types.LineCPD;

const Cursor = struct {
    pos: usize,
    line: usize,
    column: usize,

    fn init() Cursor {
        return .{
            .pos = 0,
            .line = 0,
            .column = 0,
        };
    }
};

allocator: std.mem.Allocator,
buf: Buffer,
lines: std.ArrayList(LineCPD),
cursors: std.ArrayList(Cursor),

pub fn init(gpa: Allocator, source: []const u8) !TextFrame {
    const buf: Buffer = try .init(gpa, source, .{});
    var lines: std.ArrayList(LineCPD) = try .initCapacity(gpa, 100);
    var cursors: std.ArrayList(Cursor) = try .initCapacity(gpa, 8);

    try cursors.append(gpa, .init());
    try cursors.append(gpa, .init());

    try makeLineCPDList(gpa, &buf, &lines);
    return .{
        .allocator = gpa,
        .buf = buf,
        .lines = lines,
        .cursors = cursors,
    };
}

pub fn deinit(self: *TextFrame) void {
    self.buf.deinit();

    for (self.lines.items) |*item| {
        item.deinit(self.allocator);
    }
    self.lines.deinit(self.allocator);

    self.cursors.deinit(self.allocator);
}

pub fn screen_cursor(self: *@This()) *Cursor {
    return &self.cursors.items[0];
}

pub fn user_cursor(self: *@This()) *Cursor {
    return &self.cursors.items[1];
}

pub fn addCursor(self: *@This(), pos: usize) !*Cursor {
    try self.cursors.append(self.allocator, Cursor.init());
    const cursor = &self.cursors.items[self.cursors.items.len - 1];
    try self.updateCursor(cursor, pos);
    return cursor;
}

pub fn updateCursor(self: *const @This(), cursor: *Cursor, new_pos: usize) !void {
    cursor.pos = new_pos;
    for (0..self.buf.len()) |i| {
        if (i == new_pos) break;
        const c = self.buf.get(i) orelse return error.outOfBounds;
        if (c == '\n') {
            cursor.line += 1;
            cursor.column = 0;
        } else {
            cursor.column += 1;
        }
    }
}

pub fn modify(self: *@This(), cur: *Cursor, remove: usize, insert: []const u8) !void {
    const pos = cur.pos;
    const line = cur.line;
    const column = cur.column;

    if (pos + remove > self.buf.len()) {
        return error.outOfBounds;
    }

    if (remove > 0) {
        // 削除範囲内の改行数を数える
        var num_newlines: usize = 0;
        for (pos..pos + remove) |i| {
            const c = self.buf.get(i) orelse return error.outOfBounds;
            if (c == '\n') {
                num_newlines += 1;
            }
        }
        // カーソルの移動
        for (self.cursors.items) |*cursor| {
            if (cursor.pos > pos + remove) {
                cursor.pos -= remove;
                cursor.line -= num_newlines;
                cursor.column = 0; // TODO: 正確には列位置を調整する必要がある
            } else if (cursor.pos >= pos and cursor.pos <= pos + remove) {
                cursor.pos = pos;
                cursor.line = line;
                cursor.column = column;
            }
        }
    }

    try self.buf.modify(pos, remove, insert);
}

pub fn insertStr(self: *@This(), cur: *Cursor, s: []const u8) !void {
    try self.modify(cur, 0, s);
}

pub fn removeStr(self: *@This(), cur: *Cursor, remove: usize) !void {
    try self.modify(cur, remove, &[_]u8{});
}

pub fn makeLineCPDList(gpa: Allocator, buf: *const Buffer, lines: *std.ArrayList(LineCPD)) !void {
    var pos: usize = 0;
    while (true) {
        var line_cpd: LineCPD = try .init(gpa);
        const eob, pos = try makeLineCPD(gpa, buf, pos, &line_cpd.cpds);
        if (eob) {
            line_cpd.deinit(gpa);
            break;
        }
        try lines.append(gpa, line_cpd);
    }
}

fn makeLineCPD(gpa: Allocator, buf: *const Buffer, pos: usize, cpds: *std.ArrayList(CPD)) !struct { bool, usize } {
    var p = pos;
    while (true) {
        const c = buf.get(p) orelse return .{ true, p };
        if (c == '\n') return .{ false, p + 1 };
        try cpds.append(gpa, .{ .chr = c, .attr = 0, .color = 0 });
        p += 1;
    }
    return error.outOfBounds;
}

const t = std.testing;

test "cursor insert and remove" {
    const gpa = std.testing.allocator;
    const src = "123\n456\n789";
    var tf = try TextFrame.init(gpa, src);
    defer tf.deinit();

    const cursor1 = try tf.addCursor(0);

    const cursor2 = try tf.addCursor(9);

    try t.expectEqual(Cursor{ .pos = 0, .line = 0, .column = 0 }, cursor1.*);
    try t.expectEqual(Cursor{ .pos = 9, .line = 2, .column = 1 }, cursor2.*);

    cursor1.pos = 5;
    try tf.insertStr(cursor1, " World");

    cursor1.pos = 10;
    try tf.removeStr(cursor1, 4);

    //try t.expect(cursor1.pos == 11);
    //try t.expect(cursor2.pos == 12);
}
