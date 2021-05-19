const std = @import("std");

test "temp" {
    try std.testing.expectEqual(2, 1 + 1);
}

comptime {
    std.testing.refAllDecls(@This());
}
