const std = @import("std");
const attacks = @import("attacks.zig");
const tables = @import("tables.zig");
// const Move = @import("move.zig").Move;

// const fen = @import("fen.zig");
const utils = @import("utils.zig");
// const Position = @import("position.zig").Position;
// const createPositionFromFEN = @import("position.zig").createPositionFromFEN;
// const Color = utils.Color;
const perft = @import("perft.zig").perft;

pub fn main() !void {
    // const fen_string = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1";
    // const fen_string = "8/8/6r1/1b6/8/8/4P3/4K3 w - - 0 1";
    // var move_list_buf: [256]Move = undefined;
    tables.initTables();
    // var position = try createPositionFromFEN(fen_string);
    // const move_count = try position.generateMoves(&move_list_buf);
    // std.debug.print("move count {d}\n", .{move_count});

    // var prng = std.Random.DefaultPrng.init(seed: {
    //     var seed: u64 = undefined;
    //     // get random seed from OS
    //     try std.posix.getrandom(std.mem.asBytes(&seed));
    //     break :seed seed;
    // });
    // // get interface
    // const rand = prng.random();

    // while (move_count > 0) {
    //     const n = rand.intRangeAtMost(u8, 0, @intCast(move_count - 1));
    //     const move = move_list_buf[n];
    //     try position.makeMove(move);
    //     move_count = try position.generateMoves(&move_list_buf);
    // }

    // for (move_list_buf[0..move_count]) |move| {
    //     std.debug.print("from {d} to {d}\n", .{ move.from_sq, move.to_sq });
    //     try position.makeMove(move);
    //     try position.unmakeMove(move);
    // }

    // for (1..5) |depth| {
    _ = try perft(7);
    // utils.printBitboard(@as(u64, 1) << 54);
    // utils.printBitboard(attacks.pawnAttacks(54, .Black));
    // _ = attacks.pawnAttacks(54, .Black);
    // }
}
