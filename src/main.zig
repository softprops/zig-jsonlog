//! Provides a JSON formatter for std lib logging
//!
//! Use as follows
//!
//! ```zig
//! const jsonLog = @import("jsonlog");
//! pub const std_options = struct {
//!   pub const logFn = jsonLog.func;
//! }
//! ```
const std = @import("std");
const datetime = @import("datetime").datetime;

const LogFn = fn (comptime std.log.Level, comptime @TypeOf(.enum_literal), comptime []const u8, anytype) void;

const defaultLogger = Logger(std.io.getStdErr().writer());

/// A JSON-based logging impl that writes to stderr
///
/// To write to another `std.io.Writer` use `Logger(yourWriter)`
pub const logFn = defaultLogger.func;

const default = scoped(.default);

pub fn scoped(comptime scope: @Type(.EnumLiteral)) type {
    return struct {
        pub fn debug(comptime format: []const u8, args: anytype, meta: anytype) void {
            withMeta(meta)(.debug, scope, format, args);
        }

        pub fn info(comptime format: []const u8, args: anytype, meta: anytype) void {
            withMeta(meta)(.info, scope, format, args);
        }

        /// Same as std.log.warn except you may provide arbitrary metadata to serialize with log output
        pub fn warn(comptime format: []const u8, args: anytype, meta: anytype) void {
            withMeta(meta)(.warn, scope, format, args);
        }

        /// Same as std.log.err except you may provide arbitrary metadata to serialize with log output
        pub fn err(comptime format: []const u8, args: anytype, meta: anytype) void {
            withMeta(meta)(.err, scope, format, args);
        }
    };
}

/// Same as std.log.debug except you may provide arbitrary metadata to serialize with log output
pub const debug = default.debug;
/// Same as std.log.info except you may provide arbitrary metadata to serialize with log output
pub const info = default.info;
/// Same as std.log.warn except you may provide arbitrary metadata to serialize with log output
pub const warn = default.warn;
/// Same as std.log.err except you may provide arbitrary metadata to serialize with log output
pub const err = default.err;

fn withMeta(comptime data: anytype) LogFn {
    return struct {
        fn func(
            comptime level: std.log.Level,
            comptime scope: @TypeOf(.EnumLiteral),
            comptime format: []const u8,
            args: anytype,
        ) void {
            defaultLogger.metaFunc(level, scope, format, args, data, std.time.milliTimestamp());
        }
    }.func;
}

fn Logger(comptime writer: anytype) type {
    return struct {
        fn func(
            comptime level: std.log.Level,
            comptime scope: @TypeOf(.EnumLiteral),
            comptime format: []const u8,
            args: anytype,
        ) void {
            metaFunc(level, scope, format, args, null, std.time.milliTimestamp());
        }

        fn metaFunc(
            comptime level: std.log.Level,
            comptime scope: @TypeOf(.EnumLiteral),
            comptime format: []const u8,
            args: anytype,
            meta: anytype,
            milliTimestamp: i64,
        ) void {
            var msg: [std.fmt.count(format, args)]u8 = undefined;
            _ = std.fmt.bufPrint(&msg, format, args) catch |e| {
                std.debug.print("caught err writing to buffer {any}", .{e});
            };
            var tsbuf: [26]u8 = undefined;
            const ts = datetime.Datetime.fromTimestamp(milliTimestamp).formatISO8601Buf(&tsbuf, false) catch "-";
            var payload = if (@TypeOf(meta) == @TypeOf(null)) .{
                .ts = ts,
                .level = level.asText(),
                .msg = msg,
                .scope = @tagName(scope),
            } else .{
                .ts = ts,
                .level = level.asText(),
                .msg = msg,
                .scope = @tagName(scope),
                .meta = meta,
            };
            nosuspend std.json.stringify(payload, .{}, writer) catch |e| {
                std.debug.print("caught err writing json {any}", .{e});
            };
            writer.writeAll("\n") catch return;
        }
    };
}

test "func" {
    const allocator = std.testing.allocator;
    comptime var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();
    comptime var writer = list.writer();

    Logger(writer).metaFunc(.info, .bar, "test", .{}, null, 1710775704741);
    const actual = try list.toOwnedSlice();
    defer allocator.free(actual);
    try std.testing.expectEqualStrings(
        \\{"ts":"2024-03-18T15:28:24+00:00","level":"info","msg":"test","scope":"bar"}
        \\
    , actual);
}

test "metaFunc" {
    const allocator = std.testing.allocator;
    comptime var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();
    comptime var writer = list.writer();

    Logger(writer).metaFunc(.info, .bar, "test", .{}, .{ .custom = "field" }, 1710775704741);
    const actual = try list.toOwnedSlice();
    defer allocator.free(actual);
    try std.testing.expectEqualStrings(
        \\{"ts":"2024-03-18T15:28:24+00:00","level":"info","msg":"test","scope":"bar","meta":{"custom":"field"}}
        \\
    , actual);
}
