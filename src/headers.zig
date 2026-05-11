const std = @import("std");
const utils = @import("utils.zig");

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
