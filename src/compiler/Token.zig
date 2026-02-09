const std = @import("std");
const Self = @This();

type: Type,
data: []const u8,

pub const Type = enum {
    Eof,
    Document,
    Backslash,
};

pub fn print(self: *Self) void {
    std.debug.print("{s}: '{s}'\n", .{ @tagName(self.type), self.data });
}
