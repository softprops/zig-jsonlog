const std = @import("std");

pub const std_options = struct {
    pub const logFn = jsonLog;
};

pub fn jsonLog(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    impl(
        std.io.getStdErr().writer(),
        level,
        scope,
        format,
        args,
    );
}

fn impl(
    writer: anytype,
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    var msg: [std.fmt.count(format, args)]u8 = undefined;
    _ = std.fmt.bufPrint(&msg, format, args) catch |err| {
        std.debug.print("caught err writing to buffer {any}", .{err});
    };
    nosuspend std.json.stringify(.{
        .level = level.asText(),
        .msg = msg,
        .scope = @tagName(scope),
    }, .{}, writer) catch |err| {
        std.debug.print("caught err writing json {any}", .{err});
    };
    writer.writeAll("\n") catch return;
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    std.log.debug("test 1", .{});
    std.log.info("test 2", .{});
    std.log.warn("test 3", .{});
    std.log.err("test 4", .{});
}

test "simple test" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();
    var writer = list.writer();

    impl(writer, .info, .bar, "test", .{});
    const actual = try list.toOwnedSlice();
    defer allocator.free(actual);
    try std.testing.expectEqualStrings(
        \\{"level":"info","msg":"test","scope":"bar"}
        \\
    , actual);
}
