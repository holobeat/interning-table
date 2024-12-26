const std = @import("std");

pub fn InterningTable(comptime T: type) type {
    const token_map_type: type = switch (T) {
        []const u8 => std.StringHashMap(usize),
        else => std.AutoHashMap(T, T),
    };

    return struct {
        const Self = @This();

        tokens: std.ArrayList(T), // Array to store the data
        token_map: token_map_type, // std.StringHashMap(usize), // Map to associate strings with indices
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .allocator = allocator,
                .tokens = std.ArrayList(T).init(allocator),
                .token_map = token_map_type.init(allocator), //std.StringHashMap(usize).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            if (T == []const u8) {
                for (self.tokens.items) |token| {
                    self.allocator.free(token);
                }
            }
            self.tokens.deinit();
            self.token_map.deinit();
        }

        pub fn intern(self: *Self, value: T) !usize {
            // Check if the string already exists
            if (self.token_map.get(value)) |index| {
                return index; // Return existing index
            }

            switch (T) {
                []const u8 => {
                    // Allocate and store the new string
                    const str_copy = try self.allocator.dupe(u8, value);
                    try self.tokens.append(str_copy);
                    const index = self.tokens.items.len - 1;

                    // Update the hash map
                    try self.token_map.put(str_copy, index);

                    return index; // Return the new index
                },

                else => {
                    try self.tokens.append(value);
                    const index = self.tokens.items.len - 1;
                    try self.token_map.put(value, index);
                    return index;
                    // return 1;
                },
            }
        }

        pub fn get(self: *Self, index: usize) ?T {
            if (index >= self.tokens.items.len) {
                return null;
            }
            return self.tokens.items[index];
        }
    };
}

pub fn getRandomStrings(count: usize, length: usize, seed: u32, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    // Create an ArrayList to hold the generated random strings
    var list = std.ArrayList([]const u8).init(allocator);

    // Create a buffer to hold each random string
    const buffer = try allocator.alloc(u8, length);
    defer allocator.free(buffer);

    var rng = std.Random.DefaultPrng.init(seed);
    const r = rng.random();

    // Generate 'count' random strings of 'length' characters
    for (0..count) |_| {
        // Fill the buffer with random printable ASCII characters (from 32 to 126)
        for (buffer) |*c| {
            c.* = @intCast(65 + (r.int(u8) % 26)); // 95 printable ASCII characters from 32 to 126
        }

        // Copy the string from the buffer into the list
        const random_string = try allocator.dupe(u8, buffer);
        try list.append(random_string);
    }

    return list;
}

pub fn fillRandomString(r: std.Random, buffer: []u8) void {
    for (buffer) |*c| {
        c.* = @intCast(65 + (r.int(u8) % 26));
    }
}

test "intern string" {
    const allocator = std.testing.allocator;
    const assert = std.debug.assert;

    var interning_table = try InterningTable([]const u8).init(allocator);
    defer interning_table.deinit();

    const index1 = try interning_table.intern("Hello");
    _ = try interning_table.intern("World");
    const index3 = try interning_table.intern("Hello"); // Reuses the first index

    assert(index1 == index3);
}

test "intern integers" {
    const allocator = std.testing.allocator;
    const assert = std.debug.assert;

    var interning_table = try InterningTable(usize).init(allocator);
    defer interning_table.deinit();

    const index1 = try interning_table.intern(42);
    _ = try interning_table.intern(7);
    const index3 = try interning_table.intern(42); // Reuses the first index

    assert(index1 == index3);
    // assert(true);
}

test "random strings" {
    const allocator = std.testing.allocator;
    const assert = std.debug.assert;

    const count = 20;

    const strings = try getRandomStrings(count, 30, std.testing.random_seed, allocator);
    defer {
        for (strings.items) |s| {
            allocator.free(s);
        }
        strings.deinit();
    }

    for (strings.items) |item| {
        std.debug.print("{s}\n", .{item});
    }

    std.debug.print("Item count: {d}\n", .{strings.items.len});

    assert(strings.items.len == count);
}
