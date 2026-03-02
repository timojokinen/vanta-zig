const Color = @import("utils.zig").Color;

pub const PieceType = enum(u8) {
    Pawn = 0,
    Knight = 1,
    Bishop = 2,
    Rook = 3,
    Queen = 4,
    King = 5,
};

pub const Piece = packed struct(u8) {
    pub inline fn color(self: Piece) Color {
        if (self.white) return Color.White;
        if (self.black) return Color.Black;
        unreachable;
    }

    pub inline fn @"type"(self: Piece) PieceType {
        if (self.pawn) return PieceType.Pawn;
        if (self.knight) return PieceType.Knight;
        if (self.bishop) return PieceType.Bishop;
        if (self.rook) return PieceType.Rook;
        if (self.queen) return PieceType.Queen;
        if (self.king) return PieceType.King;
        unreachable;
    }

    white: bool = false,
    black: bool = false,
    pawn: bool = false,
    knight: bool = false,
    bishop: bool = false,
    rook: bool = false,
    queen: bool = false,
    king: bool = false,
};

pub fn makePiece(piece_color: Color, piece_type: PieceType) Piece {
    return .{
        .pawn = piece_type == PieceType.Pawn,
        .knight = piece_type == PieceType.Knight,
        .bishop = piece_type == PieceType.Bishop,
        .rook = piece_type == PieceType.Rook,
        .queen = piece_type == PieceType.Queen,
        .king = piece_type == PieceType.King,
        .white = piece_color == Color.White,
        .black = piece_color == Color.Black,
    };
}
