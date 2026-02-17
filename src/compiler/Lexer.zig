const std = @import("std");

const Token = @import("Token.zig");
const Parser = @import("Parser.zig");
const Span = @import("Span.zig");
const Compiler = @import("../Compiler.zig");

const AllocError = std.mem.Allocator.Error;

const Self = @This();

data: []const u8,
start: usize,
current: usize,
location: Span,

fn makeToken(self: *Self, token_type: Token.Type, allocator: std.mem.Allocator) AllocError!*Token {
    const token = try allocator.create(Token);
    token.* = .{
        .type = token_type,
        .data = self.data[self.start..self.current],
        .location = self.location,
    };
    return token;
}

pub inline fn isEnd(self: *Self) bool {
    return self.current >= self.data.len;
}

fn peek(self: *Self, index: usize) u8 {
    if (self.current + index >= self.data.len) {
        return 0;
    }
    return self.data[self.current + index];
}

fn next(self: *Self) void {
    if (self.isEnd()) {
        return;
    }
    self.location.col += 1;
    self.current += 1;
    if (self.peek(0) == '\n') {
        self.location.line += 1;
        self.location.col = 0;
    }
}

fn match(self: *Self, c: u8) bool {
    if (self.isEnd()) return false;
    if (self.peek(0) != c) return false;
    self.next();
    return true;
}

pub fn nextToken(self: *Self, allocator: std.mem.Allocator, context: Parser.Context) AllocError!*Token {
    self.start = self.current;
    if (self.isEnd()) {
        return self.makeToken(.Eof, allocator);
    }
    const c = self.peek(0);
    switch (context) {
        .Document => {
            if (c == '\\') {
                self.next();
                return try self.makeToken(.Backslash, allocator);
            }
            if (c == '{') {
                self.next();
                return try self.makeToken(.LeftBrace, allocator);
            }
            if (c == '}') {
                self.next();
                return try self.makeToken(.RightBrace, allocator);
            }
            if (c == '\n' and self.peek(1) == '\n') {
                self.next();
                self.next();
                return try self.makeToken(.ParaSep, allocator);
            }
            outer: while (!self.isEnd()) {
                switch (self.peek(0)) {
                    '\\', '{', '}' => break :outer,
                    '\n' => {
                        if (self.peek(1) == '\n') break :outer;
                    },
                    else => {},
                }
                self.next();
            }
            return self.makeToken(.Raw, allocator);
        },
        .Macro => {
            if (std.ascii.isAlphabetic(c)) {
                while (!self.isEnd() and (std.ascii.isAlphanumeric(self.peek(0)) or self.peek(0) == '_'))
                    self.next();
                return try self.makeToken(.Ident, allocator);
            }
            self.next();
            return switch (c) {
                '{' => self.makeToken(.LeftBrace, allocator),
                '}' => self.makeToken(.RightBrace, allocator),
                '(' => self.makeToken(.LeftParen, allocator),
                ')' => self.makeToken(.RightParen, allocator),
                else => {
                    std.debug.panic("Unexpected character '{}'", .{c});
                },
            };
        },
    }
}

pub fn init(compiler: Compiler) Self {
    return .{
        .data = compiler.source,
        .start = 0,
        .current = 0,
        .location = .{ .col = 0, .line = 0 },
    };
}
