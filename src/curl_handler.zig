const url_manager = @import("url.zig");
const std = @import("std");
const utils = @import("utils.zig");
const http_headers = @import("headers.zig");
const http_body = @import("http_body.zig");

const SliceIterator = struct {
    slice: [][]const u8,
    index: usize = 0,

    pub fn next(self: *SliceIterator) ?[]const u8 {
        if (self.index >= self.slice.len) return null;
        const val = self.slice[self.index];
        self.index += 1;
        return val;
    }
};

pub const CurlMetadata = struct {
    method: []const u8,
    url: url_manager.URL,
    headers: std.ArrayList(http_headers.HttpHeader),
    body: http_body.HttpBody,

    pub fn deinit(self: *CurlMetadata, allocator: std.mem.Allocator) void {
        self.headers.deinit(allocator);
    }

    pub fn parse_curl(curl_string: []const u8, allocator: std.mem.Allocator) !CurlMetadata {
        if (valid_curl_string(curl_string) == false) {
            return error.InvalidCurlString;
        }

        var parts = try get_splited_parts(curl_string, allocator);
        defer allocator.free(parts.slice);

        var metadata = CurlMetadata{
            .method = "",
            .url = url_manager.URL.empty(),
            .headers = .empty,
            .body = http_body.HttpBody.empty(),
        };

        while (parts.next()) |part| {
            if (utils.eql(part, "curl")) {
                continue;
            }

            if (utils.eql(part, "-X")) {
                const method = parts.next() orelse continue;
                metadata.method = method;
                continue;
            }

            if (url_manager.is_url(part)) {
                if (url_manager.URL.parse(part)) |url| {
                    metadata.url = url;
                } else {
                    return error.InvalidURL;
                }
            }

            if (utils.eql(part, "-H") or utils.eql(part, "--header")) {
                const header_str = parts.next() orelse continue;
                const header = http_headers.HttpHeader.parse(header_str) orelse continue;
                try metadata.headers.append(allocator, header);
            }

            if (utils.eql(part, "--data") or utils.eql(part, "--data-raw") or utils.eql(part, "--data-binary") or utils.eql(part, "--data-ascii")) {
                const body = parts.next() orelse continue;

                if (http_body.HttpBody.from_string(body)) |parsed_body| {
                    metadata.body = parsed_body;
                } else {
                    return error.InvalidBody;
                }
            }
        }

        if (utils.eql(metadata.method, "")) {
            metadata.method = "GET";
        }

        if (url_manager.is_url(metadata.url.url) == false) {
            return error.CantFindUrl;
        }

        return metadata;
    }
};

fn get_splited_parts(curl_string: []const u8, allocator: std.mem.Allocator) !SliceIterator {
    var result = std.ArrayList([]const u8).empty;

    var current_token = std.ArrayList(u8).empty;

    var escaped = false;
    var in_double_quotes = false;
    var in_single_quotes = false;

    for (curl_string) |c| {
        if (escaped) {
            current_token.append(allocator, c) catch return error.AllocationFailed;
            escaped = false;
            continue;
        }

        if (c == '\\') {
            if (in_single_quotes) {
                current_token.append(allocator, c) catch return error.AllocationFailed;
            } else {
                escaped = true;
            }
        } else if (c == '\"' and !in_single_quotes) {
            in_double_quotes = !in_double_quotes;
            current_token.append(allocator, c) catch return error.AllocationFailed;
        } else if (c == '\'' and !in_double_quotes) {
            in_single_quotes = !in_single_quotes;
            current_token.append(allocator, c) catch return error.AllocationFailed;
        } else if (c == ' ' and !in_double_quotes and !in_single_quotes) {
            if (current_token.items.len > 0) {
                try result.append(allocator, current_token.items);
                current_token = std.ArrayList(u8).empty;
            }
        } else {
            current_token.append(allocator, c) catch return error.AllocationFailed;
        }
    }

    if (current_token.items.len > 0) {
        try result.append(allocator, current_token.items);
    }

    return SliceIterator{ .slice = result.items };
}

fn valid_curl_string(curl_string: []const u8) bool {
    return std.mem.startsWith(u8, curl_string, "curl");
}

test "valid_curl_string" {
    try std.testing.expect(valid_curl_string("curl -X GET https://example.com"));

    try std.testing.expect(valid_curl_string("some random text") == false);

    try std.testing.expect(valid_curl_string("wget https://example.com") == false);
}

test "parse_curl" {
    const allocator = std.heap.page_allocator;
    const curl_string = "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";

    const metadata = try CurlMetadata.parse_curl(curl_string, allocator);

    try std.testing.expect(utils.eql(metadata.method, "POST"));
    try std.testing.expect(utils.eql(metadata.url.url, "https://httpbin.org/post"));
}

test "CurlMetadata.parse_curl with no method" {
    const allocator = std.heap.page_allocator;
    const curl_string = "curl \"https://httpbin.org/get\" -H  \"accept: application/json\" -H 'Authorization: Bearer 123'";

    const metadata = try CurlMetadata.parse_curl(curl_string, allocator);

    try std.testing.expect(utils.eql(metadata.method, "GET"));
    try std.testing.expect(utils.eql(metadata.url.url, "https://httpbin.org/get"));
}

test "Parse Headers" {
    const allocator = std.heap.page_allocator;
    const curl_string = "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";

    const metadata = try CurlMetadata.parse_curl(curl_string, allocator);

    try std.testing.expect(utils.eql(metadata.headers.items[0].name, "accept"));
    try std.testing.expect(utils.eql(metadata.headers.items[1].name, "Authorization"));

    try std.testing.expect(metadata.headers.items.len == 2);
}

test "Error on invalid url" {
    const allocator = std.heap.page_allocator;
    const curl_string = "curl -X POST this_is_not_an_url -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";

    const metadata = CurlMetadata.parse_curl(curl_string, allocator);

    try std.testing.expect(metadata == error.CantFindUrl);
}

test "Error on invalid curl string" {
    const allocator = std.heap.page_allocator;
    const curl_string = "This is not a valid curl command";

    const metadata = CurlMetadata.parse_curl(curl_string, allocator);

    try std.testing.expect(metadata == error.InvalidCurlString);
}

test "Parse Body" {
    const allocator = std.heap.page_allocator;
    const curl_string = "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'";

    const metadata = try CurlMetadata.parse_curl(curl_string, allocator);

    const body = metadata.body;

    try std.testing.expect(utils.eql(body.content, "{\"property1\": \"1\"}"));
}
