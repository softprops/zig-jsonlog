# jsonlog

A zero-allocation JSON formatting logging library for zig

```zig
const std = @import("std");
const jsonLog = @import("jsonlog");

pub const std_options = struct {
    pub const logFn = jsonLog.logFn;
};

pub fn main() void {
    // std logging interfaces
    std.log.debug("DEBUG", .{});
    std.log.info("INFO", .{});
    std.log.warn("WARN", .{});
    std.log.err("ERR", .{});

    // extended logging interfaces to add metadata context to logs
    jsonLog.warn("things could be better", .{}, .{
        .endpoint = "/home",
        .method = "GET",
    });
}
```

```
{"level":"debug","msg":"DEBUG","scope":"default"}
{"level":"info","msg":"INFO","scope":"default"}
{"level":"warning","msg":"WARN","scope":"default"}
{"level":"error","msg":"ERR","scope":"default"}
{"level":"warning","msg":"things could be better","scope":"default","meta":{"endpoint":"/home","method":"GET"}}
```
