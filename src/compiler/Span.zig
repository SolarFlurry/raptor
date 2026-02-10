const Self = @This();

line: usize,
col: usize,

pub fn getLine(self: *const Self, data: []const u8) []const u8 {
    var line_num: usize = 0;
    var line_start: usize = 0;

    for (0..data.len) |i| {
        if (data[i] == '\n') {
            if (self.line == line_num) {
                return data[line_start..i];
            }
            line_num += 1;
            line_start = i + 1;
        }
    }

    if (self.line == line_num) {
        return data[line_start..data.len];
    }

    return "";
}
