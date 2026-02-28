const std = @import("std");

const fen = @import("fen.zig");
const utils = @import("utils.zig");
const Position = @import("position.zig").Position;
const Color = utils.Color;

pub fn main() !void {
    const fen_string = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    _ = try Position.fromFEN(fen_string);
}
