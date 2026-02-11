const std = @import("std");

const Token = @import("Token.zig");
const reporter = @import("reporter.zig");

const Self = @This();

pub const Root = std.ArrayList(*Self);

const WriteError = error{WriteFailed};

token: *Token,
data: Data,

pub const Data = union(enum) {
    paragraph: std.ArrayList(*Self),
    raw,
    macro: struct {
        name: []const u8,
        args: std.ArrayList(*Self),
        body: ?*Self,
    },
};

pub fn writeHtml(self: *Self, writer: *std.io.Writer) WriteError!void {
    switch (self.data) {
        .paragraph => |doc| {
            try writer.writeAll("<p>");
            for (doc.items) |node| {
                try node.writeHtml(writer);
            }
            try writer.writeAll("</p>\n");
        },
        .macro => |macro| {
            if (std.mem.eql(u8, macro.name, "b")) {
                if (macro.body) |body| {
                    try writer.writeAll("<b>");
                    try body.writeHtml(writer);
                    try writer.writeAll("</b>");
                }
            } else if (std.mem.eql(u8, macro.name, "i")) {
                if (macro.body) |body| {
                    try writer.writeAll("<i>");
                    try body.writeHtml(writer);
                    try writer.writeAll("</i>");
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
        .paragraph => |doc| {
            const len = doc.items.len;
            std.debug.print("Paragraph\x1b[0m[{}]:\n", .{len});
            for (0..len) |i| {
                const node = doc.items[i];
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
                body.print(indent + 1, 2, (has_lines << 1) | 1);
            }
        },
        .raw => std.debug.print("Raw\x1b[0m   -> \x1b[93m'{s}'\x1b[0m\n", .{self.token.data}),
    }
}
