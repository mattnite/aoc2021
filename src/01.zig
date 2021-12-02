const std = @import("std");

const window_len = 3;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var depths = std.ArrayList(usize).init(allocator);
    defer depths.deinit();

    const reader = std.io.getStdIn().reader();
    var buf: [80]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line|
        try depths.append(try std.fmt.parseInt(usize, line, 10));

    var avgs = try std.ArrayList(usize).initCapacity(allocator, depths.items.len - (window_len - 1));
    defer avgs.deinit();

    for (depths.items[0 .. depths.items.len - (window_len - 1)]) |_, i|
        try avgs.append(depths.items[i] + depths.items[i + 1] + depths.items[i + 2]);

    var increase_count: usize = 0;
    for (avgs.items[1..]) |_, i| {
        if (avgs.items[i + 1] > avgs.items[i]) {
            increase_count += 1;
        }
    }

    std.log.info("increase count: {}", .{increase_count});
}
