# jsonlog

A zero-allocation JSON formatting logging library for zig

```zig
const std = @import("std");
const jsonLog = @import("jsonlog");
const log = std.log.scoped(.demo);

pub const std_options = struct {
    pub const logFn = jsonLog.logFn;
};

pub fn main() void {
    log.debug("DEBUG", .{});
    log.info("INFO", .{});
    log.warn("WARN", .{});
    log.err("ERR", .{});

    jsonLog.scoped(.demo).warn("things could be better", .{}, .{
        .endpoint = "/home",
        .method = "GET",
    });
}
```

```
{"level":"debug","msg":"DEBUG","scope":"demo"}
{"level":"info","msg":"INFO","scope":"demo"}
{"level":"warning","msg":"WARN","scope":"demo"}
{"level":"error","msg":"ERR","scope":"demo"}
{"level":"warning","msg":"things could be better","scope":"demo","meta":{"endpoint":"/home","method":"GET"}}
```
