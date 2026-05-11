const curl_handler = @import("curl_handler.zig");
const std = @import("std");

pub fn curl_to_xh(curl: curl_handler.CurlMetadata, allocator: std.mem.Allocator) ![]const u8 {
    var builder = std.ArrayList(u8).empty;

    try builder.appendSlice(allocator, "xh");
    try builder.append(allocator, ' ');

    try builder.appendSlice(allocator, curl.method);
    try builder.append(allocator, ' ');

    if (curl.url.is_localhost()) {
        try builder.appendSlice(allocator, curl.url.path);
        try builder.append(allocator, ' ');
    } else {
        try builder.appendSlice(allocator, curl.url.url);
        try builder.append(allocator, ' ');
    }

    for (curl.headers.items) |header| {
        if (header.is_bearer_auth()) {
            const token = header.get_bearer_token() orelse continue;

            try builder.appendSlice(allocator, "--bearer");
            try builder.append(allocator, ' ');

            try builder.appendSlice(allocator, token);
            try builder.append(allocator, ' ');
            continue;
        }

        const formated_header = try std.fmt.allocPrint(
            allocator,
            "'{s}':'{s}'",
            .{ header.name, header.value },
        );
        defer allocator.free(formated_header);

        try builder.appendSlice(allocator, formated_header);
        try builder.append(allocator, ' ');
    }

    if (curl.body.content.len > 0) {
        const formated_body = try std.fmt.allocPrint(
            allocator,
            "'{s}'",
            .{curl.body.content},
        );

        defer allocator.free(formated_body);

        try builder.appendSlice(allocator, "--raw");
        try builder.append(allocator, ' ');

        try builder.appendSlice(allocator, formated_body);
        try builder.append(allocator, ' ');
    }

    const res = builder.items;

    const trimmed = std.mem.trim(u8, res, " ");

    return trimmed;
}

test "Generate xh command" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const curl_string = "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";
    const metadata = try curl_handler.CurlMetadata.parse_curl(curl_string, allocator);
    const xh_command = try curl_to_xh(metadata, allocator);

    const expected_xh_command = "xh POST https://httpbin.org/post 'accept':'application/json' --bearer '123123' --raw '{\"property1\": \"1\"}'";

    try std.testing.expect(std.mem.eql(u8, xh_command, expected_xh_command));
}

test "Generate xh command on localhost" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const curl_string = "curl -X POST \"http://localhost:5000/users\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";
    const metadata = try curl_handler.CurlMetadata.parse_curl(curl_string, allocator);
    const xh_command = try curl_to_xh(metadata, allocator);

    const expected_xh_command = "xh POST :5000/users 'accept':'application/json' --bearer '123123' --raw '{\"property1\": \"1\"}'";

    try std.testing.expect(std.mem.eql(u8, xh_command, expected_xh_command));
}
