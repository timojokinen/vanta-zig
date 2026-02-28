const utils = @import("utils.zig");
const BoardState = @import("fen.zig").BoardState;
const parseFen = @import("fen.zig").parseFen;
const std = @import("std");
const Piece = @import("piece.zig").Piece;
const PieceType = @import("piece.zig").PieceType;
const printBitboard = utils.printBitboard;

const Color = utils.Color;
const Bitboard = utils.Bitboard;

pub fn generate_bbs_from_board_state(board_state: BoardState) [12]Bitboard {
    var bbs: [12]Bitboard = .{0} ** 12;
    for (0..8) |rank| {
        for (0..8) |file| {
            const square_occupancy = board_state.mat_8x8[rank][file];
            if (square_occupancy == 0) continue;
            const piece: Piece = @bitCast(square_occupancy);
            const bb_idx = @intFromEnum(piece.type()) + (@as(u4, (if (piece.white) 0 else 6)));
            std.debug.print("bb_idx: {d}, piece type {?s}\n", .{ bb_idx, std.enums.tagName(PieceType, piece.type()) });
            bbs[bb_idx] |= @as(u64, 1) << @intCast(rank * 8 + file);
        }
    }
    return bbs;
}

pub const Position = struct {
    board_state: BoardState,
    bbs: [12]Bitboard = .{0} ** 12,

    pub fn fromFEN(fen: []const u8) !Position {
        const board_state = try parseFen(fen);
        const bbs = generate_bbs_from_board_state(board_state);

        const pos = Position{ .board_state = board_state, .bbs = bbs };
        return pos;
    }
};
