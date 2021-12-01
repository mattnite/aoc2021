const std = @import("std");

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

    var increase_count: usize = 0;
    for (depths.items[1..]) |_, i| {
        if (depths.items[i + 1] > depths.items[i]) {
            increase_count += 1;
        }
    }

    std.log.info("increase count: {}", .{increase_count});
}
