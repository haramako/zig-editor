const std = @import("std");
const Allocator = std.mem.Allocator;
const arrays = @import("lib/arrays.zig");
const screen = @import("screen.zig");

pub const LineCPD = struct {
    cpds: std.ArrayList(screen.CPD),
    pub fn init(gpa: Allocator) !LineCPD {
        return .{
            .cpds = try std.ArrayList(screen.CPD).initCapacity(gpa, 100),
        };
    }
    pub fn deinit(self: *LineCPD, gpa: Allocator) void {
        self.cpds.deinit(gpa);
    }
};

pub const U8Array2D = arrays.Array2D(u8);
pub const CPDArray2D = arrays.Array2D(screen.CPD);
