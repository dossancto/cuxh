const std = @import("std");
const utils = @import("utils.zig");

pub const URL = struct {
    url: []const u8,
    host: []const u8,
    scheme: []const u8,
    port: ?u16,

    pub fn empty() URL {
        return URL{ .url = "", .host = "", .scheme = "", .port = null };
    }

    pub fn parse(url: []const u8) ?URL {
        const cleaned_url = utils.clean_escape(url);
        const scheme_end = std.mem.indexOf(u8, cleaned_url, ":") orelse return null;
        const host_start = scheme_end + 3;
        const host_end = std.mem.indexOf(u8, cleaned_url[host_start..], ":") orelse
            std.mem.indexOf(u8, cleaned_url[host_start..], "/") orelse cleaned_url.len - host_start;

        var port: ?u16 = null;

        if (std.mem.indexOf(u8, cleaned_url[host_start..], ":") != null) {
            const port_start = host_start + host_end + 1;
            const port_end = std.mem.indexOf(u8, cleaned_url[port_start..], "/") orelse cleaned_url.len - port_start;
            const port_str = cleaned_url[port_start .. port_start + port_end];
            port = std.fmt.parseInt(u16, port_str, 10) catch return null;
        }
        const host = cleaned_url[host_start .. host_start + host_end];

        const scheme = cleaned_url[0..scheme_end];

        return URL{ .url = cleaned_url, .host = host, .scheme = scheme, .port = port };
    }

    pub fn is_localhost(self: URL) bool {
        return utils.eql(self.host, "localhost") or utils.eql(self.host, "127.0.0.1");
    }
};

pub fn is_url(text: []const u8) bool {
    const clean_text = utils.clean_escape(text);
    return std.mem.startsWith(u8, clean_text, "http") or std.mem.startsWith(u8, clean_text, "\"http");
}

test "parse url" {
    const parsed_url = URL.parse("https://localhost:8080/path/to/resource") orelse unreachable;

    try std.testing.expect(utils.eql(parsed_url.url, "https://localhost:8080/path/to/resource"));
    try std.testing.expect(utils.eql(parsed_url.host, "localhost"));
    try std.testing.expect(utils.eql(parsed_url.scheme, "https"));
    try std.testing.expect(parsed_url.port == 8080);
    try std.testing.expect(parsed_url.is_localhost());
}

test "parse without port" {
    const parsed_url = URL.parse("https://localhost/path/to/resource") orelse unreachable;
    try std.testing.expect(parsed_url.port == null);
}

test "Parse non localhost url" {
    const parsed_url = URL.parse("https://example.com/path/to/resource") orelse unreachable;

    try std.testing.expect(utils.eql(parsed_url.url, "https://example.com/path/to/resource"));
    try std.testing.expect(utils.eql(parsed_url.host, "example.com"));
    try std.testing.expect(utils.eql(parsed_url.scheme, "https"));
    try std.testing.expect(parsed_url.is_localhost() == false);
}

test "Is url" {
    try std.testing.expect(is_url("http://example.com"));
    try std.testing.expect(is_url("https://example.com"));
    try std.testing.expect(is_url("\"http://example.com\""));
    try std.testing.expect(is_url("\"https://example.com\""));
    try std.testing.expect(is_url("ftp://example.com") == false);
    try std.testing.expect(is_url("ftp://example.com") == false);
}
