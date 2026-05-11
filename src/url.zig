const std = @import("std");
const utils = @import("utils.zig");

pub const URL = struct {
    url: []const u8,
    host: []const u8,
    scheme: []const u8,

    pub fn empty() URL {
        return URL{ .url = "", .host = "", .scheme = "" };
    }

    pub fn parse(url: []const u8) ?URL {
        const cleaned_url = utils.clean_escape(url);
        const scheme_end = std.mem.indexOf(u8, cleaned_url, ":") orelse return null;
        const host_start = scheme_end + 3;
        const host_end = std.mem.indexOf(u8, cleaned_url[host_start..], "/") orelse cleaned_url.len - host_start;

        const host = cleaned_url[host_start .. host_start + host_end];

        const scheme = cleaned_url[0..scheme_end];

        return URL{ .url = cleaned_url, .host = host, .scheme = scheme };
    }
};

pub fn is_url(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "http") or std.mem.startsWith(u8, text, "\"http");
}

test "parse url" {
    const parsed_url = URL.parse("https://example.com/path/to/resource") orelse unreachable;

    try std.testing.expect(utils.eql(parsed_url.url, "https://example.com/path/to/resource"));
    try std.testing.expect(utils.eql(parsed_url.host, "example.com"));
    try std.testing.expect(utils.eql(parsed_url.scheme, "https"));
}

test "Is url" {
    try std.testing.expect(is_url("http://example.com"));
    try std.testing.expect(is_url("https://example.com"));
    try std.testing.expect(is_url("\"http://example.com\""));
    try std.testing.expect(is_url("\"https://example.com\""));
    try std.testing.expect(is_url("ftp://example.com") == false);
}
