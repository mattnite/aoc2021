const std = @import("std");

fn factorial(num: usize) usize {
    var ret: usize = 0;
    var i: usize = 1;
    while (i <= num) : (i += 1) {
        ret += i;
    }

    return ret;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const text = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(text);

    var positions = std.ArrayList(u8).init(allocator);
    defer positions.deinit();

    var it = std.mem.tokenize(u8, text, ",\n");
    while (it.next()) |num_str| {
        const num = try std.fmt.parseInt(usize, num_str, 10);

        if (positions.items.len <= num)
            try positions.appendNTimes(0, num - positions.items.len + 1);

        positions.items[num] += 1;
    }

    var fuel_costs = try std.ArrayList(usize).initCapacity(allocator, positions.items.len);
    defer fuel_costs.deinit();

    for (positions.items) |_, i| {
        try fuel_costs.append(0);
        for (positions.items) |count, j| {
            const diff = if (i > j) i - j else j - i;
            fuel_costs.items[i] += count * factorial(diff);
        }
    }

    var min_fuel_cost: usize = std.math.maxInt(usize);
    var min_index: usize = undefined;
    for (fuel_costs.items) |cost, i| {
        if (cost < min_fuel_cost) {
            min_fuel_cost = cost;
            min_index = i;
        }
    }

    std.log.info("min fuel cost {} at position {}", .{ min_fuel_cost, min_index });
}
