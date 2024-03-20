const std = @import("std");

/// when printed, formats epoc seconds as an ISO-8601 UTC timestamp
pub const Timestamp = struct {
    millis: i64,

    pub fn now() Timestamp {
        return Timestamp{ .seconds = std.time.milliTimestamp() };
    }

    /// typically millis will come from `std.time.milliTimestamp()`
    pub fn fromEpochMillis(millis: i64) Timestamp {
        return Timestamp{ .millis = millis };
    }

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const secs = @divTrunc(self.millis, 1000);
        const millis: u64 = @intCast(@mod(self.millis, 1000));
        const seconds: std.time.epoch.EpochSeconds = .{ .secs = @intCast(secs) };
        const day = seconds.getEpochDay();
        const day_seconds = seconds.getDaySeconds();
        const year_day = day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();
        try writer.print("{d}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}.{d:0>3}Z", .{
            year_day.year,
            month_day.month.numeric(),
            month_day.day_index + 1,
            day_seconds.getHoursIntoDay(),
            day_seconds.getMinutesIntoHour(),
            day_seconds.getSecondsIntoMinute(),
            millis,
        });
    }
};

test "fmt" {
    var buf: [40]u8 = undefined; // yyyy-mm-ddThh:mm:ss:SSZ
    const actual = try std.fmt.bufPrint(
        &buf,
        "{any}",
        .{Timestamp.fromEpochMillis(1710946475600)},
    );
    try std.testing.expectEqualStrings(
        "2024-03-20T14:54:35.600Z",
        actual,
    );
}
