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
const timestamp = @import("timestamp.zig");

const LogFn = fn (comptime std.log.Level, comptime @TypeOf(.enum_literal), comptime []const u8, anytype) void;

const defaultLogger = Logger(std.io.getStdErr().writer());

/// A JSON-based logging impl that writes to stderr
pub const logFn = defaultLogger.func;

const default = scoped(.default);

/// Same as `std.log.scoped` but provides an interface for supplying arbitrary metadata with
/// log entries which will get serialized to JSON
pub fn scoped(comptime scope: @Type(.EnumLiteral)) type {
    return struct {
        /// Same as `std.log.debug` except you may provide arbitrary metadata to serialize with log output
        pub fn debug(comptime format: []const u8, args: anytype, meta: anytype) void {
            withMeta(meta)(.debug, scope, format, args);
        }

        /// Same as `std.log.info` except you may provide arbitrary metadata to serialize with log output
        pub fn info(comptime format: []const u8, args: anytype, meta: anytype) void {
            withMeta(meta)(.info, scope, format, args);
        }

        /// Same as `std.log.warn` except you may provide arbitrary metadata to serialize with log output
        pub fn warn(comptime format: []const u8, args: anytype, meta: anytype) void {
            withMeta(meta)(.warn, scope, format, args);
        }

        /// Same as `std.log.err` except you may provide arbitrary metadata to serialize with log output
        pub fn err(comptime format: []const u8, args: anytype, meta: anytype) void {
            withMeta(meta)(.err, scope, format, args);
        }
    };
}

/// Same as `std.log.debug` except you may provide arbitrary metadata to serialize with log output
pub const debug = default.debug;

/// Same as `std.log.info` except you may provide arbitrary metadata to serialize with log output
pub const info = default.info;

/// Same as `std.log.warn` except you may provide arbitrary metadata to serialize with log output
pub const warn = default.warn;

/// Same as `std.log.err` except you may provide arbitrary metadata to serialize with log output
pub const err = default.err;

fn withMeta(comptime data: anytype) LogFn {
    return struct {
        fn func(
            comptime level: std.log.Level,
            comptime scope: @TypeOf(.EnumLiteral),
            comptime format: []const u8,
            args: anytype,
        ) void {
            defaultLogger.metaFunc(
                level,
                scope,
                format,
                args,
                data,
                std.time.milliTimestamp(),
            );
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
            metaFunc(
                level,
                scope,
                format,
                args,
                null,
                std.time.milliTimestamp(),
            );
        }

        fn metaFunc(
            comptime level: std.log.Level,
            comptime scope: @TypeOf(.EnumLiteral),
            comptime format: []const u8,
            args: anytype,
            meta: anytype,
            epocMillis: i64,
        ) void {
            impl(
                level,
                scope,
                format,
                args,
                meta,
                epocMillis,
                writer,
            );
        }
    };
}

inline fn impl(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
    meta: anytype,
    epocMillis: i64,
    writer: anytype,
) void {
    var msg: [std.fmt.count(format, args)]u8 = undefined;
    _ = std.fmt.bufPrint(&msg, format, args) catch |e| {
        // the only possible error here is errror.NoSpaceLeft and if that happens
        // in means the std lib fmt.count(...) is broken
        std.debug.print("caught err writing to buffer {any}", .{e});
        return;
    };
    var tsbuf: [24]u8 = undefined; // yyyy-mm-ddThh:mm:ss:SSSZ
    const ts = std.fmt.bufPrint(&tsbuf, "{any}", .{timestamp.Timestamp.fromEpocMillis(epocMillis)}) catch |e| blk: {
        // the only possible error here is errror.NoSpaceLeft and if that happens
        // in means the std lib timestamp.format(...) is broken
        std.debug.print("timestamp error {any}", .{e});
        break :blk "???";
    };
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

test "std" {
    var buf: [76]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const writer = fbs.writer();

    impl(
        .info,
        .bar,
        "test",
        .{},
        null,
        1710946475600,
        writer,
    );
    const actual = fbs.getWritten();
    try std.testing.expectEqualStrings(
        \\{"ts":"2024-03-20T14:54:35.600Z","level":"info","msg":"test","scope":"bar"}
        \\
    , actual);
}

test "meta" {
    var buf: [103]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const writer = fbs.writer();

    impl(
        .info,
        .bar,
        "test",
        .{},
        .{ .custom = "field" },
        1710946475600,
        writer,
    );
    const actual = fbs.getWritten();
    try std.testing.expectEqualStrings(
        \\{"ts":"2024-03-20T14:54:35.600Z","level":"info","msg":"test","scope":"bar","meta":{"custom":"field"}}
        \\
    , actual);
}
