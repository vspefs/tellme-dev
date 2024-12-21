const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    b.addModule("tellme", .{
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path("src/root.zig"),
    });
}
