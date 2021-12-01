const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const a1 = b.addExecutable("01a", "src/01a.zig");
    a1.install();
    const b1 = b.addExecutable("01b", "src/01b.zig");
    b1.install();
}
