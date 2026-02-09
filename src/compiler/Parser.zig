const std = @import("std");

const Lexer = @import("Lexer.zig");
const Token = @import("Token.zig");
const AstNode = @import("AstNode.zig");

const AllocError = std.mem.Allocator.Error;

const Self = @This();

lexer: Lexer,
current: *Token,
context: Context,
allocator: std.mem.Allocator,

pub const Context = enum {
    Document,
    Macro,
};

pub fn init(lexer: Lexer, allocator: std.mem.Allocator) Self {
    return .{
        .lexer = lexer,
        .allocator = allocator,
        .current = lexer.nextToken(allocator),
        .context = .Document,
    };
}

pub fn parse() AllocError!*AstNode {}

fn next(self: *Self) AllocError!void {
    self.current = try self.lexer.nextToken(self.allocator, self.context);
}

fn consume(self: *Self, expected: Token.Type, comptime message: []const u8, args: anytype) AllocError!void {
    if (self.current.type != expected) {
        std.debug.print(message, args);
    }
    try self.next();
}
