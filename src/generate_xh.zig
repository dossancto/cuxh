const curl_handler = @import("curl_handler.zig");
const std = @import("std");

pub fn curl_to_xh(curl: curl_handler.CurlMetadata, allocator: std.mem.Allocator) ![]const u8 {
    var builder = std.ArrayList(u8).empty;

    try builder.appendSlice(allocator, "xh");
    try builder.append(allocator, ' ');

    try builder.appendSlice(allocator, curl.method);
    try builder.append(allocator, ' ');

    try builder.appendSlice(allocator, curl.url.url);
    try builder.append(allocator, ' ');

    for (curl.headers.items) |header| {
        const formated_header = try std.fmt.allocPrint(
            allocator,
            "'{s}':'{s}'",
            .{ header.name, header.value },
        );
        defer allocator.free(formated_header);

        try builder.appendSlice(allocator, formated_header);
        try builder.append(allocator, ' ');
    }

    const formated_body = try std.fmt.allocPrint(
        allocator,
        "'{s}'",
        .{curl.body.content},
    );
    defer allocator.free(formated_body);

    if (formated_body.len > 2) {
        try builder.appendSlice(allocator, "--raw");
        try builder.append(allocator, ' ');

        try builder.appendSlice(allocator, formated_body);
        try builder.append(allocator, ' ');
    }

    const res = builder.items;

    const trimmed = std.mem.trim(u8, res, " ");

    return trimmed;
}

fn join_string() ![]const u8 {
    const gpa = std.heap.page_allocator;

    var builder = std.ArrayList(u8).empty;

    try builder.appendSlice(gpa, "Hello");
    try builder.append(gpa, ' ');
    try builder.appendSlice(gpa, "Zig!");

    const res = builder.items;

    return res;
}

test "Generate xh command" {
    const curl_string = "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";
    const metadata = try curl_handler.CurlMetadata.parse_curl(curl_string);
    const xh_command = try curl_to_xh(metadata);

    const expected_xh_command = "xh POST https://httpbin.org/post --raw '{\"property1\": \"1\"}' 'accept':'application/json' 'Authorization':'Bearer 123'";

    try std.testing.expect(std.mem.eql(u8, xh_command, expected_xh_command));
}
