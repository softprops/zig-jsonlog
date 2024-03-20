const std = @import("std");

/// when printed, formats epoc seconds as an ISO-8601 UTC timestamp
pub const Timestamp = struct {
    seconds: i64,

    pub fn now() Timestamp {
        return Timestamp{ .seconds = std.time.timestamp() };
    }

    pub fn fromEpocSeconds(seconds: i64) Timestamp {
        return Timestamp{ .seconds = seconds };
    }

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const seconds: std.time.epoch.EpochSeconds = .{ .secs = @intCast(self.seconds) };
        const day = seconds.getEpochDay();
        const day_seconds = seconds.getDaySeconds();
        const year_day = day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();
        try writer.print("{d}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z", .{
            year_day.year,
            month_day.month.numeric(),
            month_day.day_index + 1,
            day_seconds.getHoursIntoDay(),
            day_seconds.getMinutesIntoHour(),
            day_seconds.getSecondsIntoMinute(),
        });
    }
};

test "fmt" {
    var buf: [20]u8 = undefined; // yyyy-mm-ddThh:mm:ssZ
    const actual = try std.fmt.bufPrint(
        &buf,
        "{any}",
        .{Timestamp.fromEpocSeconds(1710883557)},
    );
    try std.testing.expectEqualStrings(
        "2024-03-19T21:25:57Z",
        actual,
    );
}
