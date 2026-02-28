const utils = @import("utils.zig");
const Color = utils.Color;
const FILES = utils.FILES;
const Bitboard = utils.Bitboard;

pub fn pawnEastAttack(sq: u6, color: Color) Bitboard {
    const occ = @as(u64, 1) << sq;
    return switch (color) {
        Color.White => (occ << 9) & ~FILES[0],
        Color.Black => (occ >> 7) & ~FILES[7],
    };
}

pub fn pawnWestAttack(sq: u6, color: Color) Bitboard {
    const occ = @as(u64, 1) << sq;
    return switch (color) {
        Color.White => (occ << 7) & ~FILES[7],
        Color.Black => (occ >> 9) & ~FILES[0],
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
