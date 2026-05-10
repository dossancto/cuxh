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

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn is_url(part: []const u8) bool {
    return std.mem.startsWith(u8, part, "http") or std.mem.startsWith(u8, part, "\"http");
}

fn clean_url(url: []const u8) []const u8 {
    if (std.mem.startsWith(u8, url, "\"") and std.mem.endsWith(u8, url, "\"")) {
        return url[1 .. url.len - 1];
    }
    return url;
}

fn parse_curl(curl_string: []const u8) CurlMetadata {
    var parts = std.mem.splitScalar(u8, curl_string, ' ');

    var metadata = CurlMetadata{ .method = "", .url = "", .Headers = .empty };

    while (parts.next()) |part| {
        if (eql(part, "curl")) {
            continue;
        }

        if (eql(part, "-X")) {
            const method = parts.next() orelse break;
            metadata.method = method;
            continue;
        }

        if (is_url(part)) {
            metadata.url = clean_url(part);
            continue;
        }

        if (eql(part, "-H") or eql(part, "--header")) {}
    }

    if (eql(metadata.method, "")) {
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

test "Is url" {
    try std.testing.expect(is_url("http://example.com"));
    try std.testing.expect(is_url("https://example.com"));
    try std.testing.expect(is_url("\"http://example.com\""));
    try std.testing.expect(is_url("\"https://example.com\""));
    try std.testing.expect(is_url("ftp://example.com") == false);
}

test "parse_curl" {
    const curl_string = "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";

    const metadata = parse_curl(curl_string);

    try std.testing.expect(eql(metadata.method, "POST"));
    try std.testing.expect(eql(metadata.url, "https://httpbin.org/post"));
}

test "parse_curl with no method" {
    const curl_string = "curl \"https://httpbin.org/get\" -H  \"accept: application/json\" -H 'Authorization: Bearer 123'";

    const metadata = parse_curl(curl_string);

    try std.testing.expect(eql(metadata.method, "GET"));
    try std.testing.expect(eql(metadata.url, "https://httpbin.org/get"));
}
