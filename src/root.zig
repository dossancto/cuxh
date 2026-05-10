//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const url = @import("url.zig");
const utils = @import("utils.zig");
const curl_handler = @import("curl_handler.zig");
const Io = std.Io;

test {
    _ = curl_handler;
    _ = url;
    _ = utils;
}

/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
