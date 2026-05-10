const std = @import("std");

/// Compares two byte slices for equality.
///
/// Returns `true` if both slices contain the same bytes in the same order and are of equal length; otherwise, returns `false`.
///
/// # Parameters
/// - `a`: The first slice to compare. Must be a valid slice of bytes (`[]const u8`).
/// - `b`: The second slice to compare. Must be a valid slice of bytes (`[]const u8`).
///
/// # Returns
/// - `bool`: `true` if the slices are equal in length and content; `false` otherwise.
///
/// # Edge Cases
/// - Returns `true` if both slices are empty.
/// - Returns `false` if the slices differ in length or any byte differs.
///
/// # Example
/// ```zig
/// const result = eql("hello", "hello"); // result == true
/// const result2 = eql("hello", "world"); // result2 == false
/// const result3 = eql("", ""); // result3 == true
/// ```
pub fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
