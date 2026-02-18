const std = @import("std");

const Self = @This();

const AstNode = @import("../AstNode.zig");
const Scope = @import("Scope.zig");
const Transpiler = @import("../Transpiler.zig");

name: []const u8,
value: Value,

pub const Value = union(enum) {
    builtin: *const fn (
        ctx: *Transpiler,
        args: std.ArrayList(*AstNode),
        body: ?*AstNode,
        scope: *Scope,
    ) error{OutOfMemory}!*Transpiler.HtmlTree,
    macro: *AstNode,
    str: []const u8,
};
