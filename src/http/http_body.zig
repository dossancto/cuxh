const std = @import("std");
const utils = @import("../utils.zig");
const http_field = @import("./http_body_field.zig");

pub const HttpBody = struct {
    content: []const u8,

    pub fn from_string(content: []const u8) ?HttpBody {
        const clean_content = utils.clean_escape(content);
        return HttpBody{ .content = clean_content };
    }

    pub fn is_empty(self: HttpBody) bool {
        return self.content.len == 0;
    }

    pub fn empty() HttpBody {
        return HttpBody{
            .content = "",
        };
    }

    pub fn has_nested_properties(self: HttpBody, allocator: std.mem.Allocator) !bool {
        return try http_field.has_any_neasted_property(allocator, self.content);
    }

    pub fn get_fields(self: HttpBody, allocator: std.mem.Allocator) ![]http_field.HttpBodyField {
        return try http_field.HttpBodyField.from_string(allocator, self.content);
    }
};

test "HttpBody from string" {
    const body = HttpBody.from_string("Hello, World!").?;
    try std.testing.expect(std.mem.eql(u8, body.content, "Hello, World!"));
}

test "HttpBody from json string" {
    const body = HttpBody.from_string("'{\"property1\": \"1\"}'").?;
    try std.testing.expect(std.mem.eql(u8, body.content, "{\"property1\": \"1\"}"));
}
