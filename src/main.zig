const std = @import("std");
const it = @import("InterningTable.zig");
const InterningTable = it.InterningTable;
const print = std.debug.print;

pub fn main() !void {
    try testString();
    // try testNumber();
    try testLoad();
}

fn testString() !void {
    const allocator = std.heap.page_allocator;

    // Initialize the interning table
    var interning_table = try InterningTable([]const u8).init(allocator);
    defer interning_table.deinit();

    // Intern some strings
    const index1 = try interning_table.intern("Hello");
    const index2 = try interning_table.intern("World");
    const index3 = try interning_table.intern("Hello"); // Reuses the first index

    // Print indices
    print("Index of 'Hello': {d}\n", .{index1});
    print("Index of 'World': {d}\n", .{index2});
    print("Index of 'Hello' again: {d}\n", .{index3});

    // Print stored tokens
    for (interning_table.tokens.items, 0..) |token, index| {
        print("Token {d}: {s}\n", .{ index, token });
    }
}

fn testNumber() !void {
    const allocator = std.heap.page_allocator;

    // Initialize the interning table
    var interning_table = try InterningTable(usize).init(allocator);
    defer interning_table.deinit();

    // Intern some strings
    const index1 = try interning_table.intern(42);
    const index2 = try interning_table.intern(7);
    const index3 = try interning_table.intern(42); // Reuses the first index

    // Print indices
    print("Index of 42: {d}\n", .{index1});
    print("Index of 7: {d}\n", .{index2});
    print("Index of 42 again: {d}\n", .{index3});

    // Print stored tokens
    for (interning_table.tokens.items, 0..) |token, index| {
        print("Token {d}: {d}\n", .{ index, token });
    }
}

fn testLoad() !void {
    // print("{d} Loading strings...\n", .{std.time.milliTimestamp()});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = std.heap.page_allocator;

    var interning_table = try InterningTable([]const u8).init(allocator);
    defer interning_table.deinit();

    // const count = 1000000;

    // const strings = try it.getRandomStrings(count, 30, std.testing.random_seed, arena.allocator());
    // defer strings.deinit();

    // // print("First 100 strings:\n", .{});
    // // for (strings.items, 0..strings.items.len) |item, i| {
    // //     std.debug.print("{s}\n", .{item});
    // //     if (i == 100) break;
    // // }

    // print("{d} Loading strings...done\n", .{std.time.milliTimestamp()});

    var buffer: [2]u8 = undefined;

    var rng = std.Random.DefaultPrng.init(@truncate(@abs(std.time.microTimestamp())));
    const r = rng.random();

    for (0..100) |_| {
        it.fillRandomString(r, buffer[0..]);
        const index = try interning_table.intern(&buffer);
        print("buffer: {s}, index: {d}\n", .{ buffer, index });
    }

    const t = interning_table.tokens;
    print("Token map value: {s}\n", .{t.getLast()});
}
