const std = @import("std");
const compiler = @import("compiler.zig");
const reporter = @import("compiler/reporter.zig");

fn printError(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print(fmt, args);
    std.process.exit(1);
}

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len != 2) {
        printError("Expected 1 argument\n", .{});
    }
    const file_path = args[1];

    var cwd = std.fs.cwd();
    const file = cwd.openFile(file_path, .{}) catch {
        printError("Error opening {s}\n", .{file_path});
    };
    defer file.close();

    const stat = try file.stat();
    const buffer = try allocator.alloc(u8, stat.size);

    _ = try file.read(buffer);

    var lexer = compiler.Lexer.init(buffer);
    var parser = try compiler.Parser.init(&lexer, allocator);

    const node = try parser.parse();

    reporter.printErrors(buffer);

    node.print(0, 0, 0);
}
