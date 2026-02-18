const std = @import("std");

const Token = @import("Token.zig");
const Scope = @import("symtable/Scope.zig");
const Symbol = @import("symtable/Symbol.zig");
const reporter = @import("reporter.zig");

const Self = @This();

const WriteError = error{WriteFailed};

token: *Token,
data: Data,

pub const Data = union(enum) {
    section: struct {
        elements: std.ArrayList(*Self),
        is_paragraph: bool,
    },
    raw,
    macro: struct {
        name: []const u8,
        args: std.ArrayList(*Self),
        body: ?*Self,
    },
};

pub fn writeHtml(self: *Self, writer: *std.io.Writer, scope: *Scope) WriteError!void {
    switch (self.data) {
        .section => |doc| {
            try writer.writeAll("<p>");
            for (doc.items) |node| {
                try node.writeHtml(writer, scope);
            }
            try writer.writeAll("</p>\n");
        },
        .macro => |macro| {
            if (scope.findSymbol(macro.name)) |symbol| {
                switch (symbol.value) {
                    .builtin => |builtin| {
                        try builtin(
                            writer,
                            macro.args,
                            macro.body,
                            scope,
                        );
                    },
                    else => {},
                }
            }
        },
        .raw => try writer.writeAll(self.token.data),
    }
}
fn printIndent(indent: u32, has_lines: u64) void {
    for (0..indent) |i| {
        if (((@as(u64, 1) << @as(u6, @intCast(indent - i))) & has_lines) > 0) {
            std.debug.print("│  ", .{});
        } else {
            std.debug.print("   ", .{});
        }
    }
}

pub fn print(self: *Self, indent: u32, indent_type: u32, has_lines: u64) void {
    printIndent(indent, has_lines);
    switch (indent_type) {
        0 => std.debug.print("   ", .{}),
        1 => std.debug.print("├─ ", .{}),
        2 => std.debug.print("╰─ ", .{}),
        else => unreachable,
    }
    std.debug.print("\x1b[36m", .{});
    switch (self.data) {
        .section => |doc| {
            const len = doc.elements.items.len;
            std.debug.print("{s}\x1b[0m[\x1b[94m{}\x1b[0m]:\n", .{
                if (doc.is_paragraph) "Paragraph" else "Section",
                len,
            });
            for (0..len) |i| {
                const node = doc.elements.items[i];
                if (i < len - 1) {
                    node.print(indent + 1, 1, (has_lines << 1) | 1);
                } else {
                    node.print(indent + 1, 2, (has_lines << 1));
                }
            }
        },
        .macro => |macro| {
            std.debug.print("Macro\x1b[0m -> \x1b[35m\\{s}\x1b[0m\n", .{self.data.macro.name});
            if (macro.body) |body| {
                const elements = body.data.section.elements.items;
                for (0..elements.len) |i| {
                    const node = elements[i];
                    if (i < elements.len - 1) {
                        node.print(indent + 1, 1, (has_lines << 1) | 1);
                    } else {
                        node.print(indent + 1, 2, (has_lines << 1));
                    }
                }
            }
        },
        .raw => std.debug.print("Raw\x1b[0m   -> \x1b[93m'{s}'\x1b[0m\n", .{self.token.data}),
    }
}
