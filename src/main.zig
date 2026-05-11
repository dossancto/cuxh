const std = @import("std");
const Io = std.Io;
const url = @import("url.zig");
const utils = @import("utils.zig");
const xh_manager = @import("generate_xh.zig");
const curl_handler = @import("curl_handler.zig");

const cuxh = @import("cuxh");

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var builder = std.ArrayList(u8).empty;

    const args = try init.minimal.args.toSlice(allocator);

    var first_item = true;

    for (args) |arg| {
        if (first_item) {
            first_item = false;
            continue;
        }
        const str = std.mem.trim(u8, arg, " ");
        builder.appendSlice(allocator, str) catch return error.AllocationFailed;
        try builder.append(allocator, ' ');
    }

    const curl_string = builder.items;

    std.debug.print("Received curl command: {s}\n", .{curl_string});
    const curl_metadata = try curl_handler.CurlMetadata.parse_curl(curl_string);
    std.debug.print("curl metadata: {s}\n", .{curl_metadata.body.content});

    const xh_command = try xh_manager.curl_to_xh(curl_metadata, allocator);
    std.debug.print("Generated xh command: {s}\n", .{xh_command});

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const out: Io.File = .stdout();
    try out.writeStreamingAll(io, xh_command);
}

test {
    _ = curl_handler;
    _ = url;
    _ = utils;
    _ = xh_manager;
}
