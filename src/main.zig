const std = @import("std");
const Io = std.Io;

const cuxh = @import("cuxh");

// pub fn main(init: std.process.Init) !void {
//     std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
//
//     const arena: std.mem.Allocator = init.arena.allocator();
//
//     const args = try init.minimal.args.toSlice(arena);
//
//     for (args) |arg| {
//         const a = .{arg};
//
//         std.log.info("arg: {s}", a);
//     }
//
//     const io = init.io;
//
//     var stdout_buffer: [1024]u8 = undefined;
//     var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
//     const stdout_writer = &stdout_file_writer.interface;
//
//     try cuxh.printAnotherMessage(stdout_writer);
//
//     try stdout_writer.flush(); // Don't forget to flush!
// }
//

const CurlMetadata = struct {
    method: []const u8,
    url: []const u8,
    Headers: std.ArrayList([][]const u8),
};

pub fn main(init: std.process.Init) !void {
    std.debug.print("Hello World", .{});

    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);

    const curl_string = args[1];

    std.debug.print("curl_string: {s}\n", .{curl_string});
}

fn parse_curl(curl_string: []const u8) CurlMetadata {
    _ = std.mem.splitScalar(u8, curl_string, ' ');

    const metadata = CurlMetadata{
        .method = "",
        .url = "",
        .Headers = std.ArrayList([][]const u8).init(std.heap.page_allocator),
    };

    return metadata;
}

fn valid_curl_string(curl_string: []const u8) bool {
    return std.mem.startsWith(u8, curl_string, "curl");
}

test "valid_curl_string" {
    try std.testing.expect(valid_curl_string("curl -X GET https://example.com"));

    try std.testing.expect(valid_curl_string("some random text") == false);

    try std.testing.expect(valid_curl_string("wget https://example.com") == false);
}

test "can split string" {
    const text = "curl test teste";

    var parts = std.mem.splitScalar(u8, text, ' ');

    var count: u8 = 0;

    while (parts.next()) |a| {
        if (count == 0) {
            count += 1;
            continue;
        }
        count += 1;
        _ = a;
    }

    try std.testing.expect(count == 3);
}

// test "parse_curl" {
//     const curl_string = "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";
//
//     _ = parse_curl(curl_string);
//
//     // const is_post = std.mem.eql(u8, metadata.method, "POST");
//     //
//     // try std.testing.expect(is_post);
// }
