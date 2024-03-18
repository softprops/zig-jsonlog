const std = @import("std");
const jsonLog = @import("jsonlog");

pub const std_options = struct {
    pub const logFn = jsonLog.logFn;
};

pub fn main() void {
    std.log.debug("DEBUG", .{});
    std.log.info("INFO", .{});
    std.log.warn("WARN", .{});
    std.log.err("ERR", .{});

    jsonLog.warn("things could be better", .{}, .{
        .endpoint = "/home",
        .method = "GET",
    });
}
