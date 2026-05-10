const std = @import("std");
const Io = std.Io;
const utils = @import("utils.zig");
const url_manager = @import("url.zig");

const cuxh = @import("cuxh");

const CurlMetadata = struct {
    method: []const u8,
    url: url_manager.URL,
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
    var parts = std.mem.splitScalar(u8, curl_string, ' ');

    var metadata = CurlMetadata{ .method = "", .url = url_manager.URL.empty(), .Headers = .empty };

    while (parts.next()) |part| {
        if (utils.eql(part, "curl")) {
            continue;
        }

        if (utils.eql(part, "-X")) {
            const method = parts.next() orelse break;
            metadata.method = method;
            continue;
        }

        if (url_manager.is_url(part)) {
            if (url_manager.URL.parse(part)) |url| {
                metadata.url = url;
            } else {
                continue;
            }
        }

        if (utils.eql(part, "-H") or utils.eql(part, "--header")) {}
    }

    if (utils.eql(metadata.method, "")) {
        metadata.method = "GET";
    }

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

test "parse_curl" {
    const curl_string = "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";

    const metadata = parse_curl(curl_string);

    try std.testing.expect(utils.eql(metadata.method, "POST"));
    try std.testing.expect(utils.eql(metadata.url.url, "https://httpbin.org/post"));
}

test "parse_curl with no method" {
    const curl_string = "curl \"https://httpbin.org/get\" -H  \"accept: application/json\" -H 'Authorization: Bearer 123'";

    const metadata = parse_curl(curl_string);

    try std.testing.expect(utils.eql(metadata.method, "GET"));
    try std.testing.expect(utils.eql(metadata.url.url, "https://httpbin.org/get"));
    try std.testing.expect(utils.eql(metadata.url.host, "httpbin.org"));
}
