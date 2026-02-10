const std = @import("std");

const Span = @import("Span.zig");

const Self = @This();

type: Type,
data: []const u8,
location: Span,

pub const Type = enum {
    Eof,
    Raw,
    Backslash,
    RightBrace,
    LeftBrace,

    Ident,
    RightParen,
    LeftParen,
};

pub fn print(self: *Self) void {
    std.debug.print("{s}: '{s}'\n", .{ @tagName(self.type), self.data });
}
