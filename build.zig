const std = @import("std");

const current_day = 2;
pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    var i: usize = 0;
    while (i < current_day) : (i += 1) {
        const name = try std.fmt.allocPrint(b.allocator, "{:0>2}", .{i + 1});
        defer b.allocator.free(name);

        const path = try std.fmt.allocPrint(b.allocator, "src/{s}.zig", .{name});
        defer b.allocator.free(path);

        const exe = b.addExecutable(name, path);
        exe.setBuildMode(mode);
        exe.install();
    }
}
