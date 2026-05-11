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

/// Removes surrounding double quotes from a string slice if present.
///
/// This function is intended for processing text that may be wrapped in double quotes, such as values parsed from configuration files or CSV data. If the input string begins and ends with a double quote character ('"'), the returned slice excludes these quotes. If the input does not have both leading and trailing quotes, the original slice is returned unchanged.
///
/// Parameters:
///   text: []const u8
///     A UTF-8 encoded string slice to process. May be empty.
///
/// Returns:
///   []const u8
///     A slice of the input string with surrounding double quotes removed if both are present; otherwise, the original slice.
///
/// Edge Cases:
///   - If the input is less than two bytes long, or does not start and end with a double quote, the original slice is returned.
///   - No validation is performed on the contents between the quotes.
///
/// Example:
///   const input = "\"hello\"";
///   const result = clean_escape(input);
///   // result == "hello"
///
///   const input2 = "hello";
///   const result2 = clean_escape(input2);
///   // result2 == "hello"
///
pub fn clean_escape(text: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, text, " ");

    if (std.mem.startsWith(u8, trimmed, "\"") and std.mem.endsWith(u8, trimmed, "\"")) {
        return trimmed[1 .. trimmed.len - 1];
    }

    if (std.mem.startsWith(u8, trimmed, "\'") and std.mem.endsWith(u8, trimmed, "\'")) {
        return trimmed[1 .. trimmed.len - 1];
    }

    return trimmed;
}
