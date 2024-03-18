# 0.1.0

Initial version

## 📼 installing

```zig
.{
    .name = "my-app",
    .version = "0.1.0",
    .dependencies = .{
        // 👇 declare dep properties
        .jsonlog = .{
            // 👇 uri to download
            .url = "https://github.com/softprops/zig-jsonlog/archive/refs/tags/v0.1.0.tar.gz",
            // 👇 hash verification
            //.hash = "{...}",
        },
    },
}
```

```
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    // 👇 de-reference envy dep from build.zig.zon
     const jsonlog = b.dependency("jsonlog", .{
        .target = target,
        .optimize = optimize,
    });
    var exe = b.addExecutable(.{
        .name = "your-exe",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // 👇 add the jsonlog module to executable
    exe.addModule("jsonlog", jsonlog.module("jsonlog"));

    b.installArtifact(exe);
}
```
