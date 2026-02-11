const std = @import("std");
const compiler = @import("compiler.zig");

fn printError(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print(fmt, args);
    std.process.exit(1);
}

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    const allocator = gpa.allocator();

    const cwd = std.fs.cwd();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 2 or args.len > 3) {
        printError("Expected 1 or 2 arguments\n", .{});
    }
    const file_path = args[1];

    var output: std.fs.File = undefined;
    defer output.close();

    if (args.len == 3) {
        output = try cwd.createFile(args[2], .{});
    } else {
        output = std.fs.File.stdout();
    }

    compiler.compile(file_path, &output, allocator) catch |err| {
        if (err == error.FileNotFound) {
            printError("Could not open file {s}", .{file_path});
        }
        printError("Error compiling {s}", .{file_path});
    };
}
