const std = @import("std");
const attacks = @import("attacks.zig");
const tables = @import("tables.zig");

const fen = @import("fen.zig");
const utils = @import("utils.zig");
const Position = @import("position.zig").Position;
const createPositionFromFEN = @import("position.zig").createPositionFromFEN;
const Color = utils.Color;

pub fn main() !void {
    const fen_string = "rnbqk2r/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    tables.initTables();
    const position = try createPositionFromFEN(fen_string);
    try position.generateMoves();
}
