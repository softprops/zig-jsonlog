# jsonlog

A zero-allocation JSON formatting logging library for zig

## 🍬 features

- zero-allocation
- append arbitrary metadata to your logs

## examples

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
{"ts":"2024-03-18T15:32:37+00:00","level":"debug","msg":"DEBUG","scope":"demo"}
{"ts":"2024-03-18T15:32:37+00:00","level":"info","msg":"INFO","scope":"demo"}
{"ts":"2024-03-18T15:32:37+00:00","level":"warning","msg":"WARN","scope":"demo"}
{"ts":"2024-03-18T15:32:37+00:00","level":"error","msg":"ERR","scope":"demo"}
{"ts":"2024-03-18T15:32:37+00:00","level":"warning","msg":"things could be better","scope":"demo","meta":{"endpoint":"/home","method":"GET"}}
```
