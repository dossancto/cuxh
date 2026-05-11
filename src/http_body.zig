const utils = @import("utils.zig");

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

    pub fn has_nested_properties(self: HttpBody) bool {
        _ = self;
        // TODO: Implement a more robust check for nested properties, possibly by checking for JSON or XML structures
        return false;
    }
};
