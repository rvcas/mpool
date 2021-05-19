const std = @import("std");

pub fn Pool(comptime node_byte_size: usize) type {
    return struct {
        nodes: ?*[node_byte_size]u8,
        node_count: usize,
        node_byte_size: usize = node_byte_size,
        capacity: usize,

        const Self = @This();

        pub fn init(capacity: usize) !Self {
            const bytes_per_page = std.mem.page_size;

            const node_bytes = node_byte_size * capacity;

            const leftover = node_bytes % bytes_per_page;

            const bytes_to_mmap = if (leftover == 0) blk: {
                break :blk node_bytes;
            } else blk: {
                break :blk node_bytes + bytes_per_page - leftover;
            };

            const nodes = try std.os.mmap(null, bytes_to_mmap, 1 | 2, 0x0002 | 0x0020, 0, 0);

            return Self{
                .nodes = @ptrCast(*[node_byte_size]u8, nodes),
                .node_count = 0,
                .capacity = capacity,
            };
        }
    };
}

test "init" {
    const pool = try Pool(32).init(1048);

    try std.testing.expectEqual(pool.node_count, 0);
    try std.testing.expectEqual(pool.node_byte_size, 32);
    try std.testing.expectEqual(pool.capacity, 1048);
    // try std.testing.expectEqual(pool.nodes, null);
}
