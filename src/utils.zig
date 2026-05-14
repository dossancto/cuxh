const std = @import("std");

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
