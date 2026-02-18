const std = @import("std");

const Self = @This();

pub const Lexer = @import("Compiler/Lexer.zig");
pub const Parser = @import("Compiler/Parser.zig");
pub const AstNode = @import("Compiler/AstNode.zig");
pub const Token = @import("Compiler/Token.zig");
pub const Scope = @import("Compiler/symtable/Scope.zig");
pub const Symbol = @import("Compiler/symtable/Symbol.zig");
pub const Transpiler = @import("Compiler/Transpiler.zig");

pub const reporter = @import("Compiler/reporter.zig");

const builtins = @import("Compiler/builtins.zig");

allocator: std.mem.Allocator,
parser: Parser,
source: []const u8,
top_scope: *Scope,

pub fn compile(
    source_file: []const u8,
    output_stream: *std.fs.File,
    allocator: std.mem.Allocator,
) !void {
    var compiler = Self{
        .allocator = allocator,
        .parser = undefined,
        .source = undefined,
        .top_scope = undefined,
    };

    var cwd = std.fs.cwd();
    const file = try cwd.openFile(source_file, .{});
    defer file.close();

    const stat = try file.stat();
    const file_data = try allocator.alloc(u8, stat.size);

    _ = try file.read(file_data);
    compiler.source = file_data;

    var lexer = Lexer.init(compiler);
    var parser = try Parser.init(compiler, &lexer);
    compiler.parser = parser;

    var symtable = Scope.init();
    try builtins.populateSymtable(compiler, &symtable);
    compiler.top_scope = &symtable;

    const document = try parser.parse();

    reporter.printErrors(compiler.source);

    std.debug.print("\x1b[36mDocument\x1b[0m:\n", .{});
    for (0..document.items.len) |i| {
        if (i == document.items.len - 1) {
            document.items[i].print(0, 2, 0);
        } else {
            document.items[i].print(0, 1, 1);
        }
    }

    var buffer: [1024]u8 = undefined;
    var writer = output_stream.writer(&buffer);

    var transpiler = Transpiler.init(compiler);

    const tree = try transpiler.transpile(document, &symtable);

    for (tree.items) |inner| {
        try inner.writeHtml(&writer.interface);
    }

    try writer.interface.flush();
}
