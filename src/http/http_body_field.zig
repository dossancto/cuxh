const std = @import("std");
const utils = @import("../utils.zig");

pub fn has_any_neasted_property(allocator: std.mem.Allocator, text: []const u8) !bool {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, text, .{});
    defer parsed.deinit();

    var iter = parsed.value.object.iterator();

    while (iter.next()) |entry| {
        const val = entry.value_ptr.*;

        switch (val) {
            .array => return true,
            .object => return true,
            else => {
                continue;
            },
        }
    }

    return false;
}

pub const HttpBodyField = struct {
    field: []const u8,
    value: []const u8,
    raw: bool,
    encoded: bool,

    pub fn from_string(allocator: std.mem.Allocator, text: []const u8) ![]HttpBodyField {
        const clean_text = utils.clean_escape(text);
        const parsed = try std.json.parseFromSlice(std.json.Value, allocator, clean_text, .{});

        var items = std.ArrayList(HttpBodyField).empty;
        errdefer items.deinit(allocator);

        var iter = parsed.value.object.iterator();

        while (iter.next()) |entry| {
            const key = entry.key_ptr.*;
            const val = entry.value_ptr.*;

            switch (val) {
                .array => |a| {
                    const values_array = a.items;
                    const res = try std.json.Stringify.valueAlloc(allocator, values_array, .{});

                    try items.append(allocator, HttpBodyField{
                        .field = key,
                        .value = res,
                        .raw = true,
                        .encoded = true,
                    });
                },
                .object => |o| {
                    const values_array = o.get(".");
                    const res = try std.json.Stringify.valueAlloc(allocator, values_array, .{});

                    try items.append(allocator, HttpBodyField{
                        .field = key,
                        .value = res,
                        .raw = true,
                        .encoded = true,
                    });
                },
                .string => |s| {
                    try items.append(allocator, HttpBodyField{
                        .field = key,
                        .value = s,
                        .raw = false,
                        .encoded = true,
                    });
                },
                .null => {
                    try items.append(allocator, HttpBodyField{
                        .field = key,
                        .value = "null",
                        .raw = true,
                        .encoded = false,
                    });
                },
                .bool => |b| {
                    try items.append(allocator, HttpBodyField{
                        .field = key,
                        .value = if (b) "true" else "false",
                        .raw = true,
                        .encoded = false,
                    });
                },
                .integer => |i| {
                    const i_string = try std.fmt.allocPrint(allocator, "{d}", .{i});
                    try items.append(allocator, HttpBodyField{
                        .field = key,
                        .value = i_string,
                        .raw = true,
                        .encoded = false,
                    });
                },
                .float => |f| {
                    const f_string = try std.fmt.allocPrint(allocator, "{d}", .{f});
                    try items.append(allocator, HttpBodyField{
                        .field = key,
                        .value = f_string,
                        .raw = true,
                        .encoded = false,
                    });
                },
                .number_string => |s| {
                    try items.append(allocator, HttpBodyField{
                        .field = key,
                        .value = s,
                        .raw = false,
                        .encoded = false,
                    });
                },
            }
        }

        return items.items;
    }

    pub fn get_value_as_string(self: HttpBodyField, allocator: std.mem.Allocator) ![]const u8 {
        if (self.raw) {
            return self.value;
        }

        const formated_body = try std.fmt.allocPrint(
            allocator,
            "'{s}'",
            .{self.value},
        );
        return formated_body;
    }
};

test "False when no neasted properties" {
    const allocator = std.testing.allocator;
    const json_text =
        \\{
        \\  "name": "Ziggy",
        \\  "version": 0.16,
        \\  "is_fun": true
        \\}
    ;

    try std.testing.expect(try has_any_neasted_property(allocator, json_text) == false);
}

test "True when neasted properties" {
    const allocator = std.testing.allocator;
    const json_text =
        \\{
        \\  "name": "Ziggy",
        \\  "version": 0.16,
        \\  "is_fun": true,
        \\  "tags": ["fast", "safe"]
        \\}
    ;

    try std.testing.expect(try has_any_neasted_property(allocator, json_text));
}

test "Parse properties" {
    const allocator = std.heap.page_allocator;
    const json_text =
        \\{
        \\  "name": "Ziggy",
        \\  "version": 0.16,
        \\  "is_fun": true,
        \\  "nothing": null,
        \\  "number": 12
        \\}
    ;

    const items = try HttpBodyField.from_string(allocator, json_text);
    defer allocator.free(items);

    try std.testing.expect(items.len == 5);

    const name_field = items[0];

    try std.testing.expect(std.mem.eql(u8, name_field.field, "name"));
    try std.testing.expect(std.mem.eql(u8, name_field.value, "Ziggy"));

    const version_field = items[1];

    try std.testing.expect(std.mem.eql(u8, version_field.field, "version"));
    try std.testing.expect(std.mem.eql(u8, version_field.value, "0.16"));

    const is_fun_field = items[2];
    try std.testing.expect(std.mem.eql(u8, is_fun_field.field, "is_fun"));
    try std.testing.expect(std.mem.eql(u8, is_fun_field.value, "true"));

    const nothing_field = items[3];
    try std.testing.expect(std.mem.eql(u8, nothing_field.field, "nothing"));
    try std.testing.expect(std.mem.eql(u8, nothing_field.value, "null"));

    const number_field = items[4];
    try std.testing.expect(std.mem.eql(u8, number_field.field, "number"));
    try std.testing.expect(std.mem.eql(u8, number_field.value, "12"));
}

test "Parse complex object" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const json_text =
        \\{
        \\  "title": "My title",
        \\  "items": [
        \\    {
        \\      "name": "Item 1",
        \\      "description": "lorem"
        \\    }
        \\  ]
        \\}
    ;

    try std.testing.expect(try has_any_neasted_property(allocator, json_text) == true);

    const properties = try HttpBodyField.from_string(allocator, json_text);

    try std.testing.expect(properties.len == 2);

    const title_field = properties[0];
    try std.testing.expect(std.mem.eql(u8, title_field.field, "title"));
    try std.testing.expect(std.mem.eql(u8, title_field.value, "My title"));
}
