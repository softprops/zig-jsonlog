const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // create a module to be used internally.
    const jsonlog_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
    });

    // register the module so it can be referenced
    // using the package manager.
    try b.modules.put(b.dupe("jsonlog"), jsonlog_module);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // examples (pattern inspired by zap's build.zig)
    inline for ([_]struct {
        name: []const u8,
        src: []const u8,
    }{
        .{ .name = "demo", .src = "examples/demo/main.zig" },
    }) |example| {
        const example_step = b.step(try std.fmt.allocPrint(
            b.allocator,
            "{s}-example",
            .{example.name},
        ), try std.fmt.allocPrint(
            b.allocator,
            "build the {s} example",
            .{example.name},
        ));

        const example_run_step = b.step(try std.fmt.allocPrint(
            b.allocator,
            "run-{s}-example",
            .{example.name},
        ), try std.fmt.allocPrint(
            b.allocator,
            "run the {s} example",
            .{example.name},
        ));

        var exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(example.src),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("jsonlog", jsonlog_module);

        // run the artifact - depending on the example exe
        const example_run = b.addRunArtifact(exe);
        example_run_step.dependOn(&example_run.step);

        // install the artifact - depending on the example exe
        const example_build_step = b.addInstallArtifact(exe, .{});
        example_step.dependOn(&example_build_step.step);
    }
}
