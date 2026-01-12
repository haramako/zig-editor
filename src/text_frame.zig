const TextFrame = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const types = @import("types.zig");
const Buffer = @import("buffer.zig");

const CPD = types.CPD;
const LineCPD = types.LineCPD;

allocator: std.mem.Allocator,
buf: Buffer,
lines: std.ArrayList(LineCPD),

pub fn init(gpa: Allocator, source: []const u8) !TextFrame {
    const buf: Buffer = try .init(gpa, source, .{});
    var lines: std.ArrayList(LineCPD) = try .initCapacity(gpa, 100);
    try makeLineCPDList(gpa, &buf, &lines);
    return .{
        .allocator = gpa,
        .buf = buf,
        .lines = lines,
    };
}

pub fn deinit(self: *TextFrame) void {
    self.buf.deinit();
    for (self.lines.items) |*item| {
        item.deinit(self.allocator);
    }
    self.lines.deinit(self.allocator);
}

fn makeLineCPDList(gpa: Allocator, buf: *const Buffer, lines: *std.ArrayList(LineCPD)) !void {
    var pos: usize = 0;
    while (true) {
        var line_cpd: LineCPD = try .init(gpa);
        const eob, pos = try makeLineCPD(gpa, buf, pos, &line_cpd.cpds);
        if (eob) break;
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
