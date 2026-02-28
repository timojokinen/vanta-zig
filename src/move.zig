pub const MoveFlags = enum(u4) {
    QUIET = 0, // 0
    DOUBLE_PAWN_PUSH = 0b0001, // 1
    KING_CASTLE = 0b0010, // 2
    QUEEN_CASTLE = 0b0011, // 3
    CAPTURE = 0b0100, // 4
    EP_CAPTURE = 0b0101, // 5
    KNIGHT_PROMOTION = 0b1000, // 8
    BISHOP_PROMOTION = 0b1001, // 9
    ROOK_PROMOTION = 0b1010, // 10
    QUEEN_PROMOTION = 0b1011, // 11
    KNIGHT_PROMOTION_CAPTURE = 0b1100, // 12
    BISHOP_PROMOTION_CAPTURE = 0b1101, // 13
    ROOK_PROMOTION_CAPTURE = 0b1110, // 14
    QUEEN_PROMOTION_CAPTURE = 0b1111, // 15
};

pub const Move = packed struct(u16) {
    from_sq: u6,
    to_sq: u6,
    flags: MoveFlags,
};
