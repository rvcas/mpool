const std = @import("std");

pub fn NodeId(comptime T: type) type {
    return struct {
        index: usize,
    };
}

pub fn Pool(comptime node_byte_size: usize) type {
    return struct {
        nodes: ?[*]align(node_byte_size) u8,
        node_count: usize,
        capacity: usize,
        node_byte_size: usize = node_byte_size,

        const Self = @This();

        const PoolError = error{NotInitialized};

        pub fn init(capacity: usize) !Self {
            const bytes_per_page = std.mem.page_size;

            const node_bytes = node_byte_size * capacity;

            const leftover = node_bytes % bytes_per_page;

            const bytes_to_mmap = if (leftover == 0) blk: {
                break :blk node_bytes;
            } else blk: {
                break :blk node_bytes + bytes_per_page - leftover;
            };

            var nodes = try std.os.mmap(null, bytes_to_mmap, 1 | 2, 0x0002 | 0x0020, 0, 0);

            return Self{
                .nodes = @ptrCast([*]u8, nodes),
                .node_count = 0,
                .capacity = capacity,
            };
        }

        // pub fn deinit(self: *Self) void {
        //     if (self.nodes) |nodes| {
        //         std.os.munmap(nodes.*);

        //         self.nodes = null;
        //     }
        // }

        pub fn add(self: *Self, comptime T: type, node: T) PoolError!NodeId(T) {
            std.debug.assert(@sizeOf(T) <= node_byte_size);

            if (self.nodes) |nodes| {
                const node_id = self.reserve(T, 1);

                const node_data = std.mem.toBytes(node);

                var node_ptr = nodes + (node_id.index * node_byte_size);

                @memcpy(node_ptr, &node_data, @sizeOf(T));

                return node_id;
            }

            return PoolError.NotInitialized;
        }

        pub fn get(self: *Self, comptime T: type, node_id: NodeId(T)) !T {
            std.debug.assert(@sizeOf(T) <= node_byte_size);

            if (self.nodes) |nodes| {
                const node_data = nodes + (node_id.index * node_byte_size);

                return std.mem.bytesToValue(T, @ptrCast(*[@sizeOf(T)]u8, node_data));
            }

            return PoolError.NotInitialized;
        }

        fn reserve(self: *Self, comptime T: type, nodes: usize) NodeId(T) {
            const index = self.node_count;

            if (index < self.capacity) {
                self.node_count = index + nodes;

                return NodeId(T){
                    .index = index,
                };
            } else {
                @panic("out of capacity. TODO: grow pool");
            }
        }
    };
}
test "init" {
    var pool = try Pool(32).init(1048);
    // defer pool.deinit();

    try std.testing.expectEqual(pool.node_count, 0);
    try std.testing.expectEqual(pool.node_byte_size, 32);
    try std.testing.expectEqual(pool.capacity, 1048);
    try std.testing.expect(pool.nodes != null);
}

test "add/get" {
    var pool = try Pool(32).init(1048);
    // defer pool.deinit();

    const Foo = struct {
        bar: usize,
    };

    const Bar = struct {
        foo: usize,
        wow: usize,
    };

    const node_id1 = try pool.add(Foo, .{ .bar = 1 });
    const node_id2 = try pool.add(Bar, .{ .foo = 1, .wow = 3 });

    try std.testing.expectEqual(node_id1.index, 0);
    try std.testing.expectEqual(node_id2.index, 1);

    try std.testing.expectEqual(@TypeOf(node_id1), NodeId(Foo));
    try std.testing.expectEqual(@TypeOf(node_id2), NodeId(Bar));

    try std.testing.expectEqual(pool.node_count, 2);

    const foo = try pool.get(Foo, node_id1);

    try std.testing.expectEqual(foo.bar, 1);

    const bar = try pool.get(Bar, node_id2);

    try std.testing.expectEqual(bar.foo, 1);
    try std.testing.expectEqual(bar.wow, 3);
}
