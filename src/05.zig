const std = @import("std");

const Point = struct {
    x: u32,
    y: u32,

    fn parse(text: []const u8) !Point {
        var it = std.mem.tokenize(u8, text, ",");
        const x_str = it.next() orelse return error.NoX;
        const y_str = it.next() orelse return error.NoY;
        if (it.next() != null)
            return error.TrailingText;

        return Point{
            .x = try std.fmt.parseInt(u32, x_str, 10),
            .y = try std.fmt.parseInt(u32, y_str, 10),
        };
    }

    fn eql(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Line = struct {
    begin: Point,
    end: Point,

    const Iterator = struct {
        current: ?Point,
        end: Point,
        delta: struct {
            x: i32,
            y: i32,
        },

        fn next(self: *Iterator) ?Point {
            return if (self.current) |current| blk: {
                const next_val: ?Point = if (current.eql(self.end))
                    null
                else
                    Point{
                        .x = @intCast(u32, self.delta.x + @intCast(i32, current.x)),
                        .y = @intCast(u32, self.delta.y + @intCast(i32, current.y)),
                    };

                const ret = current;
                self.current = next_val;
                break :blk ret;
            } else null;
        }
    };

    fn parse(text: []const u8) !Line {
        const arrow = " -> ";
        return if (std.mem.indexOf(u8, text, arrow)) |idx|
            Line{
                .begin = try Point.parse(text[0..idx]),
                .end = try Point.parse(text[idx + arrow.len ..]),
            }
        else
            error.InvalidArrow;
    }

    fn iterate(self: Line) Iterator {
        const x1 = self.begin.x;
        const x2 = self.end.x;
        const y1 = self.begin.y;
        const y2 = self.end.y;
        return Iterator{
            .current = self.begin,
            .end = self.end,
            .delta = .{
                .x = if (x1 < x2) @as(i32, 1) else if (x1 > x2) @as(i32, -1) else @as(i32, 0),
                .y = if (y1 < y2) @as(i32, 1) else if (y1 > y2) @as(i32, -1) else @as(i32, 0),
            },
        };
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var points = std.AutoArrayHashMap(Point, usize).init(allocator);
    defer points.deinit();

    var buf: [80]u8 = undefined;
    const stdin = std.io.getStdIn().reader();
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line_str| {
        const line = try Line.parse(line_str);
        var it = line.iterate();
        while (it.next()) |point| {
            const result = try points.getOrPut(point);
            if (result.found_existing)
                result.value_ptr.* += 1
            else
                result.value_ptr.* = 1;
        }
    }

    // count number of points where count > 1
    var count: usize = 0;
    var it = points.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* > 1) {
            count += 1;
        }
    }

    std.log.info("count: {}", .{count});
}

test "Point.parse()" {
    const expectEqual = std.testing.expectEqual;
    const point = try Point.parse("0,9");

    try expectEqual(@as(u32, 0), point.x);
    try expectEqual(@as(u32, 9), point.y);
}

test "Line.parse()" {
    const expectEqual = std.testing.expectEqual;
    const line = try Line.parse("0,9 -> 5,9");

    try expectEqual(@as(u32, 0), line.begin.x);
    try expectEqual(@as(u32, 9), line.begin.y);
    try expectEqual(@as(u32, 5), line.end.x);
    try expectEqual(@as(u32, 9), line.end.y);
}

test "Line.iterate()" {
    const expectEqual = std.testing.expectEqual;
    const line = try Line.parse("3,4 -> 1,4");

    var it = line.iterate();
    try expectEqual(Point{ .x = 3, .y = 4 }, it.next().?);
    try expectEqual(Point{ .x = 2, .y = 4 }, it.next().?);
    try expectEqual(Point{ .x = 1, .y = 4 }, it.next().?);
    try expectEqual(@as(?Point, null), it.next());
}
