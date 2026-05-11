const std = @import("std");

pub const HttpHeader = struct {
    name: []const u8,
    value: []const u8,

    pub fn parse(header_string: []const u8) ?HttpHeader {
        const separator_index = std.mem.indexOf(u8, header_string, ":") orelse return null;

        const name = std.mem.trim(u8, header_string[0..separator_index], " ");
        const value = std.mem.trim(u8, header_string[separator_index + 1 ..], " ");

        return HttpHeader{ .name = name, .value = value };
    }
};

test "parse header" {
    const header = HttpHeader.parse("Content-Type: application/json") orelse unreachable;

    try std.testing.expect(std.mem.eql(u8, header.name, "Content-Type"));
    try std.testing.expect(std.mem.eql(u8, header.value, "application/json"));
}
