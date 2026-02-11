const std = @import("std");
const r = @import("reporter.zig");

const Lexer = @import("Lexer.zig");
const Token = @import("Token.zig");
const AstNode = @import("AstNode.zig");

const AllocError = std.mem.Allocator.Error;

const Self = @This();

lexer: *Lexer,
current: *Token,
context: Context,
allocator: std.mem.Allocator,

pub const Context = enum {
    Document,
    Macro,
};

fn makeNode(self: *Self, value: AstNode.Data) AllocError!*AstNode {
    const node = try self.allocator.create(AstNode);
    node.token = self.current;
    node.data = value;
    return node;
}

pub fn init(lexer: *Lexer, allocator: std.mem.Allocator) AllocError!Self {
    return .{
        .lexer = lexer,
        .allocator = allocator,
        .current = try lexer.nextToken(allocator, .Document),
        .context = .Document,
    };
}

pub fn parse(self: *Self) AllocError!AstNode.Root {
    var document = AstNode.Root.empty;

    while (true) {
        switch (self.current.type) {
            .Eof => {
                break;
            },
            else => {
                const slot = try document.addOne(self.allocator);
                slot.* = try self.parseParagraph();
                if (self.current.type == .Eof) {
                    break;
                }
                try self.consume(.ParaSep, "Expected paragraph seperator", .{});
            },
        }
    }

    return document;
}

fn parseParagraph(self: *Self) AllocError!*AstNode {
    const paragraph = try self.makeNode(.{ .paragraph = .empty });

    while (true) {
        const slot = try paragraph.data.paragraph.addOne(self.allocator);
        slot.* = switch (self.current.type) {
            .Backslash => try self.parseMacro(),
            .Eof, .ParaSep => {
                _ = paragraph.data.paragraph.pop();
                break;
            },
            else => try self.parseRaw(.Eof),
        };
    }

    return paragraph;
}
fn parseRaw(self: *Self, stop_token: Token.Type) AllocError!*AstNode {
    const node = try self.allocator.create(AstNode);
    node.token = try self.allocator.create(Token);
    node.token.* = .{
        .data = self.current.data,
        .type = .Raw,
        .location = self.current.location,
    };
    node.token.data.len = 0;
    node.data = .raw;

    while (true) {
        if (self.current.type == stop_token) {
            return node;
        }
        switch (self.current.type) {
            .Raw,
            .LeftBrace,
            .RightBrace,
            => node.token.data.len += self.current.data.len,
            else => return node,
        }
        try self.next();
    }
}

fn parseMacro(self: *Self) AllocError!*AstNode {
    self.context = .Macro;
    try self.consume(.Backslash, "Expected '\\'", .{});

    const name = self.current.data;
    try self.consume(.Ident, "Expected an identifier", .{});

    const node = try self.makeNode(.{ .macro = .{
        .args = .empty,
        .body = null,
        .name = name,
    } });

    if (self.current.type == .LeftParen) {
        try self.next();
        try self.consume(.RightParen, "Expected matching ')'", .{});
    }

    self.context = .Document;
    if (self.current.type == .LeftBrace) {
        try self.next();
        node.data.macro.body = try self.parseRaw(.RightBrace);
        try self.consume(.RightBrace, "Expected matching '}}'", .{});
    }

    return node;
}

fn next(self: *Self) AllocError!void {
    self.current = try self.lexer.nextToken(self.allocator, self.context);
}

fn consume(self: *Self, expected: Token.Type, comptime message: []const u8, args: anytype) AllocError!void {
    if (self.current.type != expected) {
        try r.reportError(
            self.current.location,
            self.allocator,
            message,
            args,
        );
        return;
    }
    try self.next();
}
