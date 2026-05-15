const std = @import("std");
const Io = std.Io;

const url = @import("http/url.zig");

const utils = @import("utils.zig");

const xh_manager = @import("./transformer/generate_xh.zig");

const curl_handler = @import("curl/curl_handler.zig");

const cuxh = @import("cuxh");

fn read_full_stream(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    var stdin_file = Io.File.stdin();

    var fifo_buffer: [4096 * 2]u8 = undefined;
    var reader = stdin_file.reader(io, &fifo_buffer);

    var output = std.ArrayList(u8).empty;

    while (true) {
        const amt = try reader.interface.readSliceShort(&fifo_buffer);
        if (amt == 0) break; // EOF reached safely
        try output.appendSlice(allocator, fifo_buffer[0..amt]);
    }

    return output.items;
}

pub fn get_curl_string(allocator: std.mem.Allocator, args: ([]const [:0]const u8), io: std.Io) ![]u8 {
    const args_len = args.len;

    if (args_len < 2) {
        const input_string = try read_full_stream(allocator, io);
        return input_string;
    } else {
        var builder = std.ArrayList(u8).empty;

        var first_item = true;

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

        return builder.items;
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const out: Io.File = .stdout();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    const curl_string = try get_curl_string(allocator, args, io);
    defer allocator.free(curl_string);

    const curl_metadata = try curl_handler.CurlMetadata.parse_curl(curl_string, allocator);
    defer allocator.free(curl_metadata.headers.items);

    const xh_command = try xh_manager.curl_to_xh(curl_metadata, allocator);
    defer allocator.free(xh_command);

    try out.writeStreamingAll(io, xh_command);
}

test {
    _ = curl_handler;
    _ = url;
    _ = utils;
    _ = xh_manager;
}
