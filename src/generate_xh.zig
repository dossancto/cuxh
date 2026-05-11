const curl_handler = @import("curl_handler.zig");
const std = @import("std");

pub fn curl_to_xh(curl: curl_handler.CurlMetadata) ![]const u8 {
    // 1. You need an allocator to manage memory
    const gpa = std.heap.page_allocator;

    // 2. Initialize the "StringBuilder"
    var builder = std.ArrayList(u8).empty;

    try builder.appendSlice(gpa, "xh");
    try builder.append(gpa, ' ');

    try builder.appendSlice(gpa, curl.method);
    try builder.append(gpa, ' ');

    try builder.appendSlice(gpa, curl.url.url);
    try builder.append(gpa, ' ');

    try builder.appendSlice(gpa, "--raw");
    try builder.append(gpa, ' ');

    const formated_body = try std.fmt.allocPrint(
        gpa,
        "'{s}'",
        .{curl.body.content},
    );
    defer gpa.free(formated_body);

    try builder.appendSlice(gpa, formated_body);
    try builder.append(gpa, ' ');

    for (curl.headers.items) |header| {
        const formated_header = try std.fmt.allocPrint(
            gpa,
            "'{s}':'{s}'",
            .{ header.name, header.value },
        );
        defer gpa.free(formated_header);

        try builder.appendSlice(gpa, formated_header);
        try builder.append(gpa, ' ');
    }

    const res = builder.items;

    const trimmed = std.mem.trim(u8, res, " ");

    return trimmed;
}

fn join_string() ![]const u8 {
    // 1. You need an allocator to manage memory
    const gpa = std.heap.page_allocator;

    // 2. Initialize the "StringBuilder"
    var builder = std.ArrayList(u8).empty;

    // 3. Append strings or characters
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

    std.debug.print("{s}\n", .{xh_command});
    std.debug.print("{s}\n", .{expected_xh_command});
    try std.testing.expect(std.mem.eql(u8, xh_command, expected_xh_command));
}
