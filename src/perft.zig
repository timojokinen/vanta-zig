const Move = @import("move.zig").Move;
const std = @import("std");
const Position = @import("position.zig").Position;
const createPositionFromFEN = @import("position.zig").createPositionFromFEN;
const utils = @import("utils.zig");

pub fn perft(depth: usize) !usize {
    const fen_string = "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10";
    var position = try createPositionFromFEN(fen_string);

    var move_list_buf: [256]Move = undefined;
    const move_count = try position.generateMoves(&move_list_buf);

    var total: usize = 0;
    for (move_list_buf[0..move_count]) |move| {
        try position.makeMove(move);
        const nodes = try perftInner(&position, depth - 1);
        try position.unmakeMove(move);

        std.debug.print("{s}{s}: {d}\n", .{ utils.idx2san(move.from_sq), utils.idx2san(move.to_sq), nodes });
        total += nodes;
    }

    std.debug.print("Total: {d}\n", .{total});
    return total;
}

fn perftInner(position: *Position, depth: usize) !usize {
    var move_list_buf: [256]Move = undefined;
    const move_count = try position.generateMoves(&move_list_buf);

    if (depth == 1) return move_count;
    if (depth == 0) return 1;
    var nodes: usize = 0;
    for (move_list_buf[0..move_count]) |move| {
        try position.makeMove(move);
        nodes += try perftInner(position, depth - 1);
        try position.unmakeMove(move);
    }

    return nodes;
}
