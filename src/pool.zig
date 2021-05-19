const std = @import("std");

pub const Pool = struct {
    nodes: ?[*]u8,
    node_count: usize,
    node_byte_size: usize,
    capacity: usize,

    pub fn init(comptime node_byte_size: usize, capacity: usize) Pool {
        // TODO: call std.os.mmap directly and assign to nodes
        return .{
            .nodes = null,
            .node_count = 0,
            .node_byte_size = node_byte_size,
            .capacity = capacity,
        };
    }
};

test "init" {
    const pool = Pool.init(32, 1048);

    try std.testing.expectEqual(pool.node_count, 0);
    try std.testing.expectEqual(pool.node_byte_size, 32);
    try std.testing.expectEqual(pool.capacity, 1048);
    try std.testing.expectEqual(pool.nodes, null);
}
