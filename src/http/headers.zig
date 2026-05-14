const std = @import("std");
const utils = @import("../utils.zig");

pub const HttpHeader = struct {
    name: []const u8,
    value: []const u8,

    pub fn parse(header_string: []const u8) ?HttpHeader {
        const cleaned_header = utils.clean_escape(header_string);
        const separator_index = std.mem.indexOf(u8, cleaned_header, ":") orelse return null;

        const name = std.mem.trim(u8, cleaned_header[0..separator_index], " ");
        const value = std.mem.trim(u8, cleaned_header[separator_index + 1 ..], " ");

        return HttpHeader{
            .name = utils.clean_escape(name),
            .value = utils.clean_escape(value),
        };
    }

    pub fn is_browser_only_header(self: HttpHeader, allocator: std.mem.Allocator) !bool {
        const lower_case_name = try std.ascii.allocLowerString(allocator, self.name);
        defer allocator.free(lower_case_name);

        return std.mem.containsAtLeast(u8, lower_case_name, 1, "user-agent") or std.mem.containsAtLeast(u8, lower_case_name, 1, "referer") or std.mem.containsAtLeast(u8, lower_case_name, 1, "accept-language") or std.mem.containsAtLeast(u8, lower_case_name, 1, "sec-gpc") or std.mem.containsAtLeast(u8, lower_case_name, 1, "connection") or std.mem.containsAtLeast(u8, lower_case_name, 1, "sec-fetch") or std.mem.containsAtLeast(u8, lower_case_name, 1, "priority") or std.mem.containsAtLeast(u8, lower_case_name, 1, "te") or std.mem.containsAtLeast(u8, lower_case_name, 1, "origin") or std.mem.containsAtLeast(u8, lower_case_name, 1, "accept-encoding");
    }

    pub fn is_auth_header(self: HttpHeader) bool {
        return std.mem.containsAtLeast(u8, self.name, 1, "Authorization");
    }

    pub fn is_bearer_auth(self: HttpHeader) bool {
        return self.is_auth_header() and std.mem.containsAtLeast(u8, self.value, 1, "Bearer");
    }

    pub fn get_bearer_token(self: HttpHeader) ?[]const u8 {
        if (self.is_bearer_auth() == false) return null;

        var parts = std.mem.splitScalar(u8, self.value, ' ');

        const allocator = std.heap.page_allocator;

        var result = std.ArrayList(u8).empty;
        defer result.deinit(allocator);

        while (parts.next()) |part| {
            if (std.mem.eql(u8, part, "Bearer")) {
                continue;
            }

            result.appendSlice(allocator, part) catch {
                return null;
            };

            result.appendSlice(allocator, part) catch {
                return null;
            };
        }
        const formated_token = std.fmt.allocPrint(
            allocator,
            "'{s}'",
            .{result.items},
        ) catch {
            return null;
        };

        return formated_token;
    }
};

test "parse header" {
    const header = HttpHeader.parse("Content-Type: application/json") orelse unreachable;

    try std.testing.expect(std.mem.eql(u8, header.name, "Content-Type"));
    try std.testing.expect(std.mem.eql(u8, header.value, "application/json"));
}

test "parse header with spaces" {
    const header = HttpHeader.parse("  \"Content-Type  :  application/json\"  ") orelse unreachable;

    try std.testing.expect(std.mem.eql(u8, header.name, "Content-Type"));
    try std.testing.expect(std.mem.eql(u8, header.value, "application/json"));
}

test "Check if should filter the header" {
    const header = HttpHeader.parse("Origin:some.site") orelse unreachable;
    const allocator = std.testing.allocator;

    try std.testing.expect(try header.is_browser_only_header(allocator) == true);
}
