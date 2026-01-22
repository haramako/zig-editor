const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // corelib module.
    const mod_corelib = b.addModule("corelib", .{
        .root_source_file = b.path("corelib/root.zig"),
        .target = target,
    });

    // screen module.
    const mod_screen = b.addModule("screen", .{
        .root_source_file = b.path("screen/root.zig"),
        .target = target,
        .imports = &.{.{ .name = "corelib", .module = mod_corelib }},
    });

    // zig_editor module.
    const mod_zig_editor = b.addModule("zig_editor", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "corelib", .module = mod_corelib },
            .{ .name = "screen", .module = mod_screen },
        },
    });

    // Executable
    const exe = b.addExecutable(.{
        .name = "zig_editor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zig_editor", .module = mod_zig_editor },
                .{ .name = "screen", .module = mod_screen },
                .{ .name = "corelib", .module = mod_corelib },
            },
        }),
    });

    b.installArtifact(exe);

    // Run step.
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Test executable.
    const mod_tests = b.addTest(.{
        .root_module = mod_zig_editor,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    // Test step.
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
