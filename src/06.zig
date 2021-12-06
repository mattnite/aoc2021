const std = @import("std");

pub fn main() !void {
    var population = std.mem.zeroes([10]usize);
    var timer: usize = 0;

    var buf: [std.mem.page_size]u8 = undefined;
    const stdin = std.io.getStdIn().reader();
    const n = try stdin.readAll(&buf);
    var it = std.mem.tokenize(u8, buf[0..n], ",\n");

    while (it.next()) |token| {
        const time_left = try std.fmt.parseInt(usize, token, 10);
        population[time_left] += 1;
    }

    var i: usize = 0;
    while (i < 256) : ({
        i += 1;
        timer += 1;
        timer %= 7;
    }) {
        // timer is pretty much which group is giving birth
        population[(timer + 6) % 7] += population[7];
        population[7] = population[8];
        population[8] = population[9];
        population[9] = population[timer];

        std.log.info("{}: {any}", .{ timer, population });
    }

    var total: usize = 0;
    for (population) |group|
        total += group;

    std.log.info("total: {}", .{total});
}
