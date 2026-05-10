const std = @import("std");
const Io = std.Io;

const cuxh = @import("cuxh");

pub fn main(init: std.process.Init) !void {
    std.debug.print("Hello World", .{});

    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);

    const curl_string = args[1];

    std.debug.print("curl_string: {s}\n", .{curl_string});
}
