const std = @import("std");
const tables = @import("tables.zig");
const uci_interface = @import("uci.zig").uci_interface;

pub fn main() !void {
    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout: *std.io.Writer = &stdout_writer.interface;

    try stdout.writeAll("Vanta 0.1 by Timo Jokinen\n");
    try stdout.flush();

    tables.initTables();
    try uci_interface();
}
