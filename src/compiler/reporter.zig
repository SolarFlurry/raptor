const std = @import("std");

const Span = @import("Span.zig");

var errors: std.ArrayList(Error) = .empty;

pub const Error = struct {
    message: []const u8,
    location: Span,

    pub fn print(self: *const Error, file_data: []const u8) void {
        std.debug.print(
            \\[Error] {s}:
            \\ -> {}:{}
            \\ {1d: >4} | {s} 
            \\        
        , .{
            self.message,
            self.location.line,
            self.location.col,
            self.location.getLine(file_data),
        });
        for (0..self.location.col - 1) |_| {
            std.debug.print(" ", .{});
        }
        std.debug.print("╰──┤ Error occurred here\n\n", .{});
    }
};

pub fn printErrors(file_data: []const u8) void {
    for (errors.items) |err| {
        err.print(file_data);
    }
}

pub fn reportError(
    location: Span,
    allocator: std.mem.Allocator,
    comptime message: []const u8,
    args: anytype,
) error{OutOfMemory}!void {
    const slot = try errors.addOne(allocator);

    slot.* = .{
        .location = location,
        .message = try std.fmt.allocPrint(allocator, message, args),
    };
}
