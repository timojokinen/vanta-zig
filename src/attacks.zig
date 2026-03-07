const utils = @import("utils.zig");
const Color = utils.Color;
const FILES = utils.FILES;
const Bitboard = utils.Bitboard;
const tables = @import("tables.zig");
const PieceType = @import("piece.zig").PieceType;

pub fn pawnEastAttack(sq: u6, color: Color) Bitboard {
    const occ = @as(u64, 1) << sq;
    return switch (color) {
        Color.White => (occ << 9) & ~FILES[0],
        Color.Black => (occ >> 7) & ~FILES[0],
    };
}

pub fn pawnWestAttack(sq: u6, color: Color) Bitboard {
    const occ = @as(u64, 1) << sq;
    return switch (color) {
        Color.White => (occ << 7) & ~FILES[7],
        Color.Black => (occ >> 9) & ~FILES[7],
    };
}

pub fn pawnAttacks(sq: u6, color: Color) Bitboard {
    return pawnEastAttack(sq, color) | pawnWestAttack(sq, color);
}

pub fn knightAttacks(sq: u6) Bitboard {
    const occupancy: Bitboard = @as(u64, 1) << sq;
    var bb: Bitboard = 0;
    const file: u8 = sq & 7;
    const rank: u8 = sq >> 3;

    if (file < 6 and rank < 7) bb |= occupancy << 10;
    if (file < 6 and rank > 0) bb |= occupancy >> 6;
    if (file < 7 and rank < 6) bb |= occupancy << 17;
    if (file < 7 and rank > 1) bb |= occupancy >> 15;
    if (file > 0 and rank < 6) bb |= occupancy << 15;
    if (file > 0 and rank > 1) bb |= occupancy >> 17;
    if (file > 1 and rank < 7) bb |= occupancy << 6;
    if (file > 1 and rank > 0) bb |= occupancy >> 10;

    return bb;
}

pub fn kingAttacks(sq: u6) Bitboard {
    var king_bb = @as(u64, 1) << sq;
    var attacks: Bitboard = (king_bb << 1 & ~utils.FILES[0]) | (king_bb >> 1 & ~utils.FILES[7]);
    king_bb |= attacks;
    attacks |= (king_bb << 8) | (king_bb >> 8);
    return attacks;
}

pub fn hyperbolaQuintessence(piece_bb: Bitboard, occupancy: Bitboard, attack_mask: Bitboard) Bitboard {
    const occupancy_mask = occupancy & attack_mask;
    const forward = occupancy_mask -% (piece_bb *% 2);
    const backward = @bitReverse(@bitReverse(occupancy_mask) -% (@bitReverse(piece_bb) *% 2));
    return (forward ^ backward) & attack_mask;
}

pub fn bishopAttacks(square: u6, occupancy: Bitboard) Bitboard {
    const piece_bb = @as(u64, 1) << square;
    return hyperbolaQuintessence(piece_bb, occupancy, utils.maskDiag(square)) |
        hyperbolaQuintessence(piece_bb, occupancy, utils.maskAntiDiag(square));
}

pub fn rookAttacks(square: u6, occupancy: Bitboard) Bitboard {
    const piece_bb = @as(u64, 1) << square;
    return hyperbolaQuintessence(piece_bb, occupancy, utils.maskFile(square)) |
        hyperbolaQuintessence(piece_bb, occupancy, utils.maskRank(square));
}

pub fn pieceAttacks(color: Color, bbs: [12]Bitboard, occupancy: Bitboard) Bitboard {
    const color_offset: usize = if (color == Color.White) 0 else 6;

    const pawns = bbs[color_offset + @intFromEnum(PieceType.Pawn)];
    const knights = bbs[color_offset + @intFromEnum(PieceType.Knight)];
    const bishops_queens = bbs[color_offset + @intFromEnum(PieceType.Bishop)] | bbs[color_offset + @intFromEnum(PieceType.Queen)];
    const rooks_queens = bbs[color_offset + @intFromEnum(PieceType.Rook)] | bbs[color_offset + @intFromEnum(PieceType.Queen)];
    const kings = bbs[color_offset + @intFromEnum(PieceType.King)];

    var attacked: Bitboard = switch (color) {
        Color.White => ((pawns << 9) & ~FILES[0]) | ((pawns << 7) & ~FILES[7]),
        Color.Black => ((pawns >> 7) & ~FILES[0]) | ((pawns >> 9) & ~FILES[7]),
    };

    var bb = knights;
    while (bb != 0) : (bb &= bb - 1) {
        attacked |= tables.lookupKnightAttacks(@intCast(@ctz(bb)));
    }

    bb = bishops_queens;
    while (bb != 0) : (bb &= bb - 1) {
        attacked |= tables.lookupBishopAttacks(@intCast(@ctz(bb)), occupancy);
    }

    bb = rooks_queens;
    while (bb != 0) : (bb &= bb - 1) {
        attacked |= tables.lookupRookAttacks(@intCast(@ctz(bb)), occupancy);
    }

    if (kings != 0) {
        attacked |= tables.lookupKingAttacks(@intCast(@ctz(kings)));
    }

    return attacked;
}

pub fn squareAttackers(square: u6, color: Color, bbs: [12]Bitboard, occupancy: Bitboard) Bitboard {
    const off: usize = if (color == .White) 0 else 6;

    // Pawn attacks: look up attacks from square as the *opposite* color
    const pawn_attackers = tables.lookupPawnAttacks(square, color.opp()) & bbs[off + @intFromEnum(PieceType.Pawn)];
    const knight_attackers = tables.lookupKnightAttacks(square) & bbs[off + @intFromEnum(PieceType.Knight)];
    const bishop_attacks = tables.lookupBishopAttacks(square, occupancy);
    const rook_attacks = tables.lookupRookAttacks(square, occupancy);
    const bq = bbs[off + @intFromEnum(PieceType.Bishop)] | bbs[off + @intFromEnum(PieceType.Queen)];
    const rq = bbs[off + @intFromEnum(PieceType.Rook)] | bbs[off + @intFromEnum(PieceType.Queen)];
    const king_attackers = tables.lookupKingAttacks(square) & bbs[off + @intFromEnum(PieceType.King)];

    return pawn_attackers | knight_attackers | (bishop_attacks & bq) | (rook_attacks & rq) | king_attackers;
}

pub fn xRayRookAttacks(rook_sq: u6, occupancy: Bitboard, blockers: Bitboard) Bitboard {
    var blockers_copy = blockers;
    const attacks = tables.lookupRookAttacks(rook_sq, occupancy);
    blockers_copy &= attacks;
    return attacks ^ tables.lookupRookAttacks(rook_sq, occupancy ^ blockers_copy);
}

pub fn xRayBishopAttacks(bishop_sq: u6, occupancy: Bitboard, blockers: Bitboard) Bitboard {
    var blockers_copy = blockers;
    const attacks = tables.lookupBishopAttacks(bishop_sq, occupancy);
    blockers_copy &= attacks;
    return attacks ^ tables.lookupBishopAttacks(bishop_sq, occupancy ^ blockers_copy);
}
