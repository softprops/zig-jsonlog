<h1 align="center">
    jsonlog
</h1>

<div align="center">
    A zero-allocation JSON formatting logging library for zig
</div>

---

[![ci](https://github.com/softprops/zig-jsonlog/actions/workflows/ci.yml/badge.svg)](https://github.com/softprops/zig-jsonlog/actions/workflows/ci.yml) ![License Info](https://img.shields.io/github/license/softprops/zig-jsonlog) ![Release](https://img.shields.io/github/v/release/softprops/zig-jsonlog) [![Zig Support](https://img.shields.io/badge/zig-0.11.0-black?logo=zig)](https://ziglang.org/documentation/0.11.0/)

## 🍬 features

- zero-allocation
- append arbitrary metadata to your logs

## examples

```zig
const std = @import("std");
const jsonLog = @import("jsonlog");
const log = std.log.scoped(.demo);

pub const std_options = struct {
    // configure the std lib log api fn to use jsonlog formatting
    pub const logFn = jsonLog.logFn;
};

pub fn main() void {
    // std log interface
    log.debug("DEBUG", .{});
    log.info("INFO", .{});
    log.warn("WARN", .{});
    log.err("ERR", .{});

    // jsonLog interface for provoding arbitrary structured metadata
    jsonLog.info("things are happening", .{}, .{
        .endpoint = "/home",
        .method = "GET",
    });

    // create a custom scope for doing the same
    jsonLog.scoped(.demo).warn("things could be better", .{}, .{
        .endpoint = "/home",
        .method = "GET",
    });
}
```

```json
{"ts":"2024-03-20T15:07:15.363Z","level":"debug","msg":"DEBUG","scope":"demo"}
{"ts":"2024-03-20T15:07:15.364Z","level":"info","msg":"INFO","scope":"demo"}
{"ts":"2024-03-20T15:07:15.364Z","level":"warning","msg":"WARN","scope":"demo"}
{"ts":"2024-03-20T15:07:15.364Z","level":"error","msg":"ERR","scope":"demo"}
{"ts":"2024-03-20T15:07:15.364Z","level":"info","msg":"things are happening","scope":"default","meta":{"endpoint":"/home","method":"GET"}}
{"ts":"2024-03-20T15:07:15.364Z","level":"warning","msg":"things could be better","scope":"demo","meta":{"endpoint":"/home","method":"GET"}}
```

## 📼 installing

Create a new exec project with `zig init-exe`. Copy the echo handler example above into `src/main.zig`

Create a `build.zig.zon` file to declare a dependency

> .zon short for "zig object notation" files are essentially zig structs. `build.zig.zon` is zigs native package manager convention for where to declare dependencies

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
            .hash = "{...}",
        },
    },
}
```

> the hash below may vary. you can also depend any tag with `https://github.com/softprops/zig-jsonlog/archive/refs/tags/v{version}.tar.gz` or current main with `https://github.com/softprops/zig-jsonlog/archive/refs/heads/main/main.tar.gz`. to resolve a hash omit it and let zig tell you the expected value.

Add the following in your `build.zig` file

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    // 👇 de-reference jsonlog dep from build.zig.zon
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

## 🥹 for budding ziglings

Does this look interesting but you're new to zig and feel left out? No problem, zig is young so most us of our new are as well. Here are some resources to help get you up to speed on zig

- [the official zig website](https://ziglang.org/)
- [zig's one-page language documentation](https://ziglang.org/documentation/0.11.0/)
- [ziglearn](https://ziglearn.org/)
- [ziglings exercises](https://github.com/ratfactor/ziglings)

\- softprops 2024
