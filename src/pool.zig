const std = @import("std");

pub const Pool = struct {
    nodes: ?[]u8,
    node_count: usize,
    node_byte_size: usize,
    capacity: usize,

    pub fn init(comptime node_byte_size: usize, capacity: usize) !Pool {
        const bytes_per_page = std.mem.page_size;

        const node_bytes = node_byte_size * capacity;

        const leftover = node_bytes % bytes_per_page;

        const bytes_to_mmap = if (leftover == 0) blk: {
            break :blk node_bytes;
        } else blk: {
            break :blk node_bytes + bytes_per_page - leftover;
        };

        const nodes = try std.os.mmap(null, bytes_to_mmap, 1 | 2, 0x0002 | 0x0020, 0, 0);

        // TODO: call std.os.mmap directly and assign to nodes
        return Pool{
            .nodes = nodes,
            .node_count = 0,
            .node_byte_size = node_byte_size,
            .capacity = capacity,
        };
    }
};

test "init" {
    const pool = try Pool.init(32, 1048);

    try std.testing.expectEqual(pool.node_count, 0);
    try std.testing.expectEqual(pool.node_byte_size, 32);
    try std.testing.expectEqual(pool.capacity, 1048);
    // try std.testing.expectEqual(pool.nodes, null);
}
