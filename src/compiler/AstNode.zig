const std = @import("std");

const Token = @import("Token.zig");

const Self = @This();

token: *Token,
data: Data,

pub const Data = union(enum) {
    document: std.ArrayList(*Self),
    macro: struct {
        name: []const u8,
        args: std.ArrayList(*Self),
        body: *Self,
    },
};
