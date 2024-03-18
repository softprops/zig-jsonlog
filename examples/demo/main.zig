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
