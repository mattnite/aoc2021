const std = @import("std");

const Report = std.ArrayList(struct {
    keep: bool,
    code: u12,
});

fn calcRating(report: Report, op: std.math.CompareOperator, decider: u1) !u12 {
    var total: usize = report.items.len;
    var bit: u4 = 0;
    return blk: while (bit < 12) : (bit += 1) {
        var ones_count: usize = 0;
        var zeroes_count: usize = 0;
        for (report.items) |entry| {
            if (entry.keep) {
                if (0 == (entry.code & (@as(u12, 1) << (11 - bit))))
                    zeroes_count += 1
                else
                    ones_count += 1;
            }
        }

        const keep_bit: u1 = if (ones_count == zeroes_count)
            decider
        else if (std.math.compare(ones_count, op, zeroes_count))
            @as(u1, 1)
        else
            @as(u1, 0);

        for (report.items) |*entry| {
            if (entry.keep) {
                const bit_val: u1 = if (0 == (entry.code & (@as(u12, 1) << (11 - bit)))) 0 else 1;
                if (bit_val != keep_bit) {
                    entry.keep = false;
                    total -= 1;
                }
            }
        }

        // found it
        if (total == 1)
            for (report.items) |entry| if (entry.keep)
                break :blk entry.code;
    } else error.NoRatingFound;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var report = Report.init(gpa.allocator());
    defer report.deinit();

    const stdin = std.io.getStdIn().reader();
    var buf: [80]u8 = undefined;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line|
        try report.append(.{
            .keep = true,
            .code = try std.fmt.parseInt(u12, line, 2),
        });

    const oxygen_rating = try calcRating(report, .gt, 1);

    // reset keep flags
    for (report.items) |*entry| entry.keep = true;
    const co2_rating = try calcRating(report, .lt, 0);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("oxygen: {}, co2: {}, value: {}\n", .{ oxygen_rating, co2_rating, @as(u32, oxygen_rating) * @as(u32, co2_rating) });
}

test "calcRating, decider is 1" {
    var report = Report.init(std.testing.allocator);
    defer report.deinit();

    try report.append(.{ .keep = true, .code = 0b0000_0000_0000 });
    try report.append(.{ .keep = true, .code = 0b1000_0000_0000 });
    try report.append(.{ .keep = true, .code = 0b0100_0000_0000 });

    const rating = try calcRating(report, .gt, 1);
    try std.testing.expectEqual(@as(u12, 0b0100_0000_0000), rating);
}

test "calcRating, decider is 0" {
    var report = Report.init(std.testing.allocator);
    defer report.deinit();

    try report.append(.{ .keep = true, .code = 0b1111_1111_1111 });
    try report.append(.{ .keep = true, .code = 0b0111_1111_1111 });
    try report.append(.{ .keep = true, .code = 0b1011_1111_1111 });

    const rating = try calcRating(report, .lt, 0);
    try std.testing.expectEqual(@as(u12, 0b0111_1111_1111), rating);
}
