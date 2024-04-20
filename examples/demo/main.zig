const std = @import("std");
const jsonLog = @import("jsonlog");
const log = std.log.scoped(.demo);

pub const std_options: std.Options = .{
    // configure the std lib log api fn to use jsonlog formatting
    .logFn = jsonLog.logFn,
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
