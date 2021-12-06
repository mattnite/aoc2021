const std = @import("std");

const Game = struct {
    allocator: std.mem.Allocator,
    rolls: []u8,
    boards: []Board,

    fn parse(allocator: std.mem.Allocator, text: []const u8) !Game {
        var rolls = std.ArrayList(u8).init(allocator);
        defer rolls.deinit();

        var boards = std.ArrayList(Board).init(allocator);
        defer boards.deinit();

        var chunk_it = std.mem.split(u8, text, "\n\n");
        const rolls_line = chunk_it.next() orelse return error.NoRollsLine;

        var rolls_it = std.mem.tokenize(u8, rolls_line, ",");
        while (rolls_it.next()) |roll|
            try rolls.append(try std.fmt.parseInt(u8, roll, 10));

        while (chunk_it.next()) |chunk|
            try boards.append(try Board.parse(chunk));

        return Game{
            .allocator = allocator,
            .rolls = rolls.toOwnedSlice(),
            .boards = boards.toOwnedSlice(),
        };
    }

    fn deinit(self: *Game) void {
        self.allocator.free(self.rolls);
        self.allocator.free(self.boards);
    }
};

const Board = struct {
    numbers: [5][5]u8,
    marks: struct {
        rows: [5]u5,
        cols: [5]u5,
    },

    fn parse(text: []const u8) !Board {
        var ret: Board = undefined;
        var line_it = std.mem.tokenize(u8, text, "\n");
        for (ret.numbers) |*row| {
            const line = line_it.next() orelse return error.NoLine;
            var it = std.mem.tokenize(u8, line, " ");
            for (row) |*number| {
                const num_str = it.next() orelse return error.NoNumber;
                number.* = try std.fmt.parseInt(u8, num_str, 10);
            }
        }

        ret.marks = .{
            .rows = std.mem.zeroes([5]u5),
            .cols = std.mem.zeroes([5]u5),
        };

        return ret;
    }

    fn won(self: Board) bool {
        for (self.marks.rows) |row|
            if (row == 0x1f)
                return true;

        for (self.marks.cols) |col|
            if (col == 0x1f)
                return true;

        return false;
    }

    fn mark(self: *Board, roll: u8) void {
        const pos = blk: {
            for (self.numbers) |row, i| {
                for (row) |num, j| {
                    if (num == roll) {
                        break :blk .{ .row = i, .col = j };
                    }
                }
            } else return;
        };

        self.marks.rows[pos.row] |= (@as(u5, 1) << @truncate(u3, pos.col));
        self.marks.cols[pos.col] |= (@as(u5, 1) << @truncate(u3, pos.row));
    }

    fn sumUnmarked(self: Board) u32 {
        var ret: u32 = 0;
        for (self.marks.rows) |row, i| {
            var j: u3 = 0;
            while (j < 5) : (j += 1) {
                if (0 == row & (@as(u5, 1) << j)) {
                    ret += self.numbers[i][j];
                }
            }
        }

        return ret;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(data);

    var game = try Game.parse(allocator, data);
    defer game.deinit();

    var losers = std.AutoHashMap(usize, void).init(allocator);
    defer losers.deinit();

    {
        var i: usize = 0;
        while (i < game.boards.len) : (i += 1)
            try losers.putNoClobber(i, {});
    }

    std.log.info("rolls: {}, boards: {}", .{ game.rolls.len, game.boards.len });
    for (game.rolls) |roll| {
        for (game.boards) |*board, i| {
            if (!losers.contains(i))
                continue;

            board.mark(roll);
            if (board.won()) {
                if (losers.count() > 1) {
                    _ = losers.remove(i);
                    continue;
                }

                const unmarked_sum = board.sumUnmarked();
                std.log.info("board {} wins last, last roll was {}, unmarked sum is {}, score is {}", .{
                    i,
                    roll,
                    unmarked_sum,
                    roll * unmarked_sum,
                });
                return;
            }
        }
    }
}

test "parse example data" {
    const expectEqual = std.testing.expectEqual;
    const data =
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\ 2  0 12  3  7
        \\
    ;

    var game = try Game.parse(std.testing.allocator, data);
    defer game.deinit();

    try expectEqual(@as(usize, 27), game.rolls.len);
    try expectEqual(@as(u8, 7), game.rolls[0]);
    try expectEqual(@as(usize, 3), game.boards.len);
}

test "unmarked sum" {
    const board = Board{
        .numbers = [_][5]u8{
            [_]u8{ 14, 21, 17, 24, 4 },
            [_]u8{ 10, 16, 15, 9, 19 },
            [_]u8{ 18, 8, 23, 26, 20 },
            [_]u8{ 22, 11, 13, 6, 5 },
            [_]u8{ 2, 0, 12, 3, 7 },
        },
        .marks = .{
            // these are mirrored from how things are highlighted in the
            // example
            .rows = [_]u5{
                0b11111,
                0b01000,
                0b00100,
                0b10010,
                0b10011,
            },
            .cols = std.mem.zeroes([5]u5),
        },
    };

    try std.testing.expectEqual(@as(u32, 188), board.sumUnmarked());
}
