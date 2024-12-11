const std = @import("std");

tokens: std.ArrayList([]const u8), // Array to store the unique strings
token_map: std.StringHashMap(usize), // Map to associate strings with indices
allocator: std.mem.Allocator,

const InterningTable = @This();

pub fn init(allocator: std.mem.Allocator) !InterningTable {
    return InterningTable{
        .tokens = std.ArrayList([]const u8).init(allocator),
        .token_map = std.StringHashMap(usize).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *InterningTable) void {
    for (self.tokens.items) |token| {
        self.allocator.free(token);
    }
    self.tokens.deinit();
    self.token_map.deinit();
}

pub fn intern(self: *InterningTable, str: []const u8) !usize {
    // Check if the string already exists
    if (self.token_map.get(str)) |index| {
        return index; // Return existing index
    }

    // Allocate and store the new string
    const str_copy = try self.allocator.dupe(u8, str);
    try self.tokens.append(str_copy);
    const index = self.tokens.items.len - 1;

    // Update the hash map
    try self.token_map.put(str_copy, index);

    return index; // Return the new index
}

test "intern string" {
    const allocator = std.testing.allocator;
    const assert = std.debug.assert;

    var interning_table = try InterningTable.init(allocator);
    defer interning_table.deinit();

    const index1 = try interning_table.intern("Hello");
    _ = try interning_table.intern("World");
    const index3 = try interning_table.intern("Hello"); // Reuses the first index

    assert(index1 == index3);
}
