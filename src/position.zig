const std = @import("std");

const tables = @import("tables.zig");
const attacks = @import("attacks.zig");
const BoardState = @import("fen.zig").BoardState;
const Move = @import("move.zig").Move;
const MoveFlags = @import("move.zig").MoveFlags;
const parseFen = @import("fen.zig").parseFen;
const Piece = @import("piece.zig").Piece;
const PieceType = @import("piece.zig").PieceType;
const utils = @import("utils.zig");
const printBitboard = utils.printBitboard;
const Color = utils.Color;
const Bitboard = utils.Bitboard;
const enumerateBitboard = utils.enumerateBitboard;

pub fn boardStateToPieceBitboards(board_state: BoardState) [12]Bitboard {
    var bbs: [12]Bitboard = .{0} ** 12;
    for (0..8) |rank| {
        for (0..8) |file| {
            const square_occupancy = board_state.mat_8x8[rank][file];
            if (square_occupancy == 0) continue;
            const piece: Piece = @bitCast(square_occupancy);
            const bb_idx = @intFromEnum(piece.type()) + (@as(u4, (if (piece.white) 0 else 6)));
            bbs[bb_idx] |= @as(u64, 1) << @intCast(rank * 8 + file);
        }
    }
    return bbs;
}

pub fn createPositionFromFEN(fen: []const u8) !Position {
    const board_state = try parseFen(fen);
    const bbs = boardStateToPieceBitboards(board_state);
    const pos = Position{ .board_state = board_state, .bbs = bbs };
    return pos;
}

pub const Position = struct {
    board_state: BoardState,
    bbs: [12]Bitboard = .{0} ** 12,

    pub fn generateMoves(self: Position) !void {
        const ally_color: Color = self.board_state.side_to_move;
        const color_offset: usize = if (ally_color == Color.Black) 6 else 0;
        const all_pieces_bb: Bitboard = utils.combineBitboards(&self.bbs);
        const ally_pieces_bb: Bitboard = utils.combineBitboards(self.bbs[color_offset..][0..6]);
        const opp_pieces_bb: Bitboard = utils.combineBitboards(self.bbs[(color_offset + 6) % 12 ..][0..6]);
        const king_bb: Bitboard = self.bbs[@intFromEnum(PieceType.King) + color_offset];
        const opp_attacks: Bitboard = attacks.pieceAttacks(ally_color.opp(), self.bbs, all_pieces_bb ^ king_bb);

        var move_list_buf: [256]Move = undefined;
        var move_list: std.ArrayListUnmanaged(Move) = .initBuffer(&move_list_buf);

        var pawns_bb: Bitboard = self.bbs[@intFromEnum(PieceType.Pawn) + color_offset];
        const pawn_direction: i8 = if (ally_color == Color.White) 1 else -1;
        const promotion_rank: Bitboard = utils.relativeRank(7, ally_color);

        while (pawns_bb != 0) : (pawns_bb &= pawns_bb - 1) {
            const from_sq: u6 = @intCast(@ctz(pawns_bb));
            const from_bb: Bitboard = @as(u64, 1) << from_sq;
            var to_sq: u6 = @intCast(@as(i8, from_sq) + 8 * pawn_direction);
            const to_bb: Bitboard = @as(u64, 1) << to_sq;

            if (to_bb & ~all_pieces_bb != 0) {
                if (to_bb & promotion_rank != 0) {
                    move_list.appendAssumeCapacity(.{ .flags = MoveFlags.KNIGHT_PROMOTION, .to_sq = to_sq, .from_sq = from_sq });
                    move_list.appendAssumeCapacity(.{ .flags = MoveFlags.BISHOP_PROMOTION, .to_sq = to_sq, .from_sq = from_sq });
                    move_list.appendAssumeCapacity(.{ .flags = MoveFlags.ROOK_PROMOTION, .to_sq = to_sq, .from_sq = from_sq });
                    move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUEEN_PROMOTION, .to_sq = to_sq, .from_sq = from_sq });
                } else {
                    move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUIET, .to_sq = to_sq, .from_sq = from_sq });
                }

                to_sq = @intCast(@as(i8, to_sq) + 8 * pawn_direction);
                if (@as(u64, 1) << to_sq & ~all_pieces_bb != 0 and from_bb & utils.relativeRank(1, ally_color) != 0) {
                    move_list.appendAssumeCapacity(.{ .flags = MoveFlags.DOUBLE_PAWN_PUSH, .from_sq = from_sq, .to_sq = to_sq });
                }
            }

            const att: Bitboard = tables.lookupPawnAttacks(from_sq, ally_color) & opp_pieces_bb;
            var captures: Bitboard = att & ~promotion_rank;
            var prom_captures: Bitboard = att & promotion_rank;

            while (captures != 0) : (captures &= captures - 1) {
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.CAPTURE, .from_sq = from_sq, .to_sq = @intCast(@ctz(captures)) });
            }
            while (prom_captures != 0) : (prom_captures &= prom_captures - 1) {
                to_sq = @intCast(@ctz(prom_captures));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.KNIGHT_PROMOTION_CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.BISHOP_PROMOTION_CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.ROOK_PROMOTION_CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUEEN_PROMOTION_CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
            }

            if (self.board_state.en_passant_square) |ep_sq| {
                const raw_att = tables.lookupPawnAttacks(from_sq, ally_color);
                if (raw_att & (@as(u64, 1) << ep_sq) != 0) {
                    move_list.appendAssumeCapacity(.{ .flags = MoveFlags.EP_CAPTURE, .from_sq = from_sq, .to_sq = ep_sq });
                }
            }
        }

        var knights_bb = self.bbs[@intFromEnum(PieceType.Knight) + color_offset];
        while (knights_bb != 0) : (knights_bb &= knights_bb - 1) {
            const from_sq: u6 = @intCast(@ctz(knights_bb));
            const att: Bitboard = tables.lookupKnightAttacks(from_sq) & ~ally_pieces_bb;

            var quiet: Bitboard = att & ~opp_pieces_bb;
            var capture: Bitboard = att & opp_pieces_bb;

            while (quiet != 0) : (quiet &= quiet - 1) {
                const to_sq: u6 = @intCast(@ctz(quiet));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUIET, .from_sq = from_sq, .to_sq = to_sq });
            }

            while (capture != 0) : (capture &= capture - 1) {
                const to_sq: u6 = @intCast(@ctz(capture));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
            }
        }

        var bishops_bb = self.bbs[@intFromEnum(PieceType.Bishop) + color_offset];
        while (bishops_bb != 0) : (bishops_bb &= bishops_bb - 1) {
            const from_sq: u6 = @intCast(@ctz(bishops_bb));
            const att: Bitboard = tables.lookupBishopAttacks(from_sq, all_pieces_bb) & ~ally_pieces_bb;

            var quiet: Bitboard = att & ~opp_pieces_bb;
            var capture: Bitboard = att & opp_pieces_bb;

            while (quiet != 0) : (quiet &= quiet - 1) {
                const to_sq: u6 = @intCast(@ctz(quiet));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUIET, .from_sq = from_sq, .to_sq = to_sq });
            }

            while (capture != 0) : (capture &= capture - 1) {
                const to_sq: u6 = @intCast(@ctz(capture));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
            }
        }

        var rooks_bb = self.bbs[@intFromEnum(PieceType.Rook) + color_offset];
        while (rooks_bb != 0) : (rooks_bb &= rooks_bb - 1) {
            const from_sq: u6 = @intCast(@ctz(rooks_bb));
            const att: Bitboard = tables.lookupRookAttacks(from_sq, all_pieces_bb) & ~ally_pieces_bb;

            var quiet: Bitboard = att & ~opp_pieces_bb;
            var capture: Bitboard = att & opp_pieces_bb;

            while (quiet != 0) : (quiet &= quiet - 1) {
                const to_sq: u6 = @intCast(@ctz(quiet));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUIET, .from_sq = from_sq, .to_sq = to_sq });
            }

            while (capture != 0) : (capture &= capture - 1) {
                const to_sq: u6 = @intCast(@ctz(capture));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
            }
        }

        var queens_bb = self.bbs[@intFromEnum(PieceType.Queen) + color_offset];
        while (queens_bb != 0) : (queens_bb &= queens_bb - 1) {
            const from_sq: u6 = @intCast(@ctz(queens_bb));
            const att: Bitboard = tables.lookupQueenAttacks(from_sq, all_pieces_bb) & ~ally_pieces_bb;

            var quiet: Bitboard = att & ~opp_pieces_bb;
            var capture: Bitboard = att & opp_pieces_bb;

            while (quiet != 0) : (quiet &= quiet - 1) {
                const to_sq: u6 = @intCast(@ctz(quiet));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUIET, .from_sq = from_sq, .to_sq = to_sq });
            }

            while (capture != 0) : (capture &= capture - 1) {
                const to_sq: u6 = @intCast(@ctz(capture));
                move_list.appendAssumeCapacity(.{ .flags = MoveFlags.CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
            }
        }

        const from_sq: u6 = @intCast(@ctz(king_bb));
        const att: Bitboard = tables.lookupKingAttacks(from_sq) & ~ally_pieces_bb & ~opp_attacks;

        var quiet: Bitboard = att & ~opp_pieces_bb;
        var capture: Bitboard = att & opp_pieces_bb;

        while (quiet != 0) : (quiet &= quiet - 1) {
            const to_sq: u6 = @intCast(@ctz(quiet));
            move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUIET, .from_sq = from_sq, .to_sq = to_sq });
        }

        while (capture != 0) : (capture &= capture - 1) {
            const to_sq: u6 = @intCast(@ctz(capture));
            move_list.appendAssumeCapacity(.{ .flags = MoveFlags.CAPTURE, .from_sq = from_sq, .to_sq = to_sq });
        }

        const wk_attacked = 0b111 << 4;
        const wk_blocked = 0b11 << 5;
        const wq_attacked = 0b111 << 2;
        const wq_blocked = 0b111 << 1;
        const bk_attacked = 0b111 << 60;
        const bk_blocked = 0b11 << 61;
        const bq_attacked = 0b111 << 58;
        const bq_blocked = 0b111 << 57;

        if (ally_color == Color.White and
            self.board_state.castling_rights.white_kingside and
            wk_attacked & opp_attacks == 0 and
            wk_blocked & all_pieces_bb == 0)
        {
            move_list.appendAssumeCapacity(.{ .flags = MoveFlags.KING_CASTLE, .from_sq = from_sq, .to_sq = 6 });
        }

        if (ally_color == Color.White and
            self.board_state.castling_rights.white_queenside and
            wq_attacked & opp_attacks == 0 and
            wq_blocked & all_pieces_bb == 0)
        {
            move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUEEN_CASTLE, .from_sq = from_sq, .to_sq = 2 });
        }

        if (ally_color == Color.Black and
            self.board_state.castling_rights.black_kingside and
            bk_attacked & opp_attacks == 0 and
            bk_blocked & all_pieces_bb == 0)
        {
            move_list.appendAssumeCapacity(.{ .flags = MoveFlags.KING_CASTLE, .from_sq = from_sq, .to_sq = 62 });
        }

        if (ally_color == Color.Black and
            self.board_state.castling_rights.black_queenside and
            bq_attacked & opp_attacks == 0 and
            bq_blocked & all_pieces_bb == 0)
        {
            move_list.appendAssumeCapacity(.{ .flags = MoveFlags.QUEEN_CASTLE, .from_sq = from_sq, .to_sq = 58 });
        }
    }
};
