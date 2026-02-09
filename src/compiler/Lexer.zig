const std = @import("std");

const Token = @import("Token.zig");
const Parser = @import("Parser.zig");

const AllocError = std.mem.Allocator.Error;

const Self = @This();

data: []const u8,
start: usize,
current: usize,

fn makeToken(self: *Self, token_type: Token.Type, allocator: std.mem.Allocator) AllocError!*Token {
    const token = try allocator.create(Token);
    token.* = .{
        .type = token_type,
        .data = self.data[self.start..self.current],
    };
    return token;
}

pub inline fn isEnd(self: *Self) bool {
    return self.current >= self.data.len;
}

fn peek(self: *Self, index: usize) u8 {
    if (self.isEnd()) {
        return 0;
    }
    return self.data[self.current + index];
}

fn next(self: *Self) void {
    if (self.isEnd()) {
        return;
    }
    self.current += 1;
}

pub fn nextToken(self: *Self, allocator: std.mem.Allocator, context: Parser.Context) AllocError!*Token {
    self.start = self.current;
    if (self.isEnd()) {
        return self.makeToken(.Eof, allocator);
    }
    switch (context) {
        .Document => {
            if (self.peek(0) == '\\') {
                self.next();
                return try self.makeToken(.Backslash, allocator);
            }
            outer: while (!self.isEnd()) {
                switch (self.peek(0)) {
                    '\\' => break :outer,
                    else => {},
                }
                self.next();
            }
            return self.makeToken(.Document, allocator);
        },
        .Macro => return self.makeToken(.Eof, allocator),
    }
}

pub fn init(buffer: []const u8) Self {
    return .{
        .data = buffer,
        .start = 0,
        .current = 0,
    };
}
