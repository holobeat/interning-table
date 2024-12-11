const std = @import("std");
const InterningTable = @import("InterningTable.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Initialize the interning table
    var interning_table = try InterningTable.init(allocator);
    defer interning_table.deinit();

    // Intern some strings
    const index1 = try interning_table.intern("Hello");
    const index2 = try interning_table.intern("World");
    const index3 = try interning_table.intern("Hello"); // Reuses the first index

    // Print indices
    std.debug.print("Index of 'Hello': {d}\n", .{index1});
    std.debug.print("Index of 'World': {d}\n", .{index2});
    std.debug.print("Index of 'Hello' again: {d}\n", .{index3});

    // Print stored tokens
    for (interning_table.tokens.items, 0..) |token, index| {
        std.debug.print("Token {d}: {s}\n", .{ index, token });
    }
}
