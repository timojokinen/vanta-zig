const std = @import("std");
const attacks = @import("attacks.zig");
const tables = @import("tables.zig");

const fen = @import("fen.zig");
const utils = @import("utils.zig");
const Position = @import("position.zig").Position;
const createPositionFromFEN = @import("position.zig").createPositionFromFEN;
const Color = utils.Color;

pub fn main() !void {
    const fen_string = "8/8/8/1q6/8/8/4K3/8 w - - 0 1";
    // const fen_string = "8/8/6r1/1b6/8/8/4P3/4K3 w - - 0 1";
    tables.initTables();
    const position = try createPositionFromFEN(fen_string);
    try position.generateMoves();
}
