const std = @import("std");

const Scope = @import("symtable/Scope.zig");
const Symbol = @import("symtable/Symbol.zig");
const AstNode = @import("AstNode.zig");
const Transpiler = @import("Transpiler.zig");

const Compiler = @import("../Compiler.zig");

pub fn boldBuiltin(
    ctx: *Transpiler,
    _: std.ArrayList(*AstNode),
    body: ?*AstNode,
    scope: *Scope,
) error{OutOfMemory}!*Transpiler.HtmlTree {
    const tree = try ctx.allocator.create(Transpiler.HtmlTree);

    tree.* = if (body) |value| .{
        .kind = .{ .tag = .{
            .first_child = try ctx.transpileNode(value, scope),
            .name = "b",
        } },
        .sibling = null,
    } else .{
        .kind = .{ .leaf = "" },
        .sibling = null,
    };

    return tree;
}

pub fn italicBuiltin(
    ctx: *Transpiler,
    _: std.ArrayList(*AstNode),
    body: ?*AstNode,
    scope: *Scope,
) error{OutOfMemory}!*Transpiler.HtmlTree {
    const tree = try ctx.allocator.create(Transpiler.HtmlTree);

    tree.* = if (body) |value| .{
        .kind = .{ .tag = .{
            .first_child = try ctx.transpileNode(value, scope),
            .name = "i",
        } },
        .sibling = null,
    } else .{
        .kind = .{ .leaf = "" },
        .sibling = null,
    };

    return tree;
}

pub fn populateSymtable(compiler: Compiler, symtable: *Scope) !void {
    const num_builtins = comptime @typeInfo(@This()).@"struct".decls.len - 1;

    const slots = try symtable.symbols.addManyAsArray(compiler.allocator, num_builtins);
    slots.* = [_]*const Symbol{
        &Symbol{ .name = "b", .value = .{ .builtin = boldBuiltin } },
        &Symbol{ .name = "i", .value = .{ .builtin = italicBuiltin } },
    };
}
