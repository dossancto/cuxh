const std = @import("std");
const Io = std.Io;

const url = @import("http/url.zig");

const utils = @import("utils.zig");

const xh_manager = @import("./transformer/generate_xh.zig");

const curl_handler = @import("curl/curl_handler.zig");

const cuxh = @import("cuxh");

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var builder = std.ArrayList(u8).empty;
    defer builder.deinit(allocator);

    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    var first_item = true;

    const args_len = args.len;

    if (args_len < 2) {
        std.debug.print("Usage: {s} \"<curl command>\"\n", .{args[0]});
        return;
    }

    for (args) |arg| {
        if (first_item) {
            first_item = false;
            continue;
        }
        const str = std.mem.trim(u8, arg, " ");
        defer allocator.free(str);
        builder.appendSlice(allocator, str) catch return error.AllocationFailed;
        try builder.append(allocator, ' ');
    }

    const curl_string = builder.items;

    const curl_metadata = try curl_handler.CurlMetadata.parse_curl(curl_string, allocator);
    defer allocator.free(curl_metadata.headers.items);

    const xh_command = try xh_manager.curl_to_xh(curl_metadata, allocator);
    defer allocator.free(xh_command);

    const io = init.io;

    const out: Io.File = .stdout();
    try out.writeStreamingAll(io, xh_command);
}

test {
    _ = curl_handler;
    _ = url;
    _ = utils;
    _ = xh_manager;
}
