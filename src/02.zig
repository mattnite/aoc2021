const std = @import("std");

const Command = enum {
    forward,
    down,
    up,
};

pub fn main() !void {
    var position: usize = 0;
    var depth: isize = 0;
    var aim: isize = 0;

    const stdin = std.io.getStdIn().reader();
    var buf: [80]u8 = undefined;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.tokenize(u8, line, " ");
        const cmd_str = it.next() orelse return error.NoCommand;
        const num_str = it.next() orelse return error.NoNum;
        if (it.next() != null)
            return error.ExtraData;

        const cmd = inline for (std.meta.fields(Command)) |field| {
            if (std.mem.eql(u8, cmd_str, field.name))
                break @field(Command, field.name);
        } else {
            std.log.err("'{s}' is not a command", .{cmd_str});
            return error.BadCommand;
        };

        const num = try std.fmt.parseInt(usize, num_str, 10);
        switch (cmd) {
            .forward => {
                position += num;
                depth += aim * @intCast(isize, num);

                std.debug.assert(depth >= 0);
            },
            .down => aim += @intCast(isize, num),
            .up => aim -|= @intCast(isize, num),
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("position: {}, depth: {}, value: {}\n", .{ position, depth, position * @intCast(usize, depth) });
}
