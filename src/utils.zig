const std = @import("std");
const Piece = @import("piece.zig").Piece;

pub const Color = enum(u1) {
    White = 0,
    Black = 1,
    pub inline fn opp(self: Color) Color {
        return @enumFromInt(@intFromEnum(self));
    }
};

pub const Bitboard = u64;

pub fn pieceToSymbol(raw: u8) []const u8 {
    if (raw == 0) return " ";
    const piece: Piece = @bitCast(raw);
    const is_white = piece.white;
    if (piece.king) return if (is_white) "♚" else "♔";
    if (piece.queen) return if (is_white) "♛" else "♕";
    if (piece.rook) return if (is_white) "♜" else "♖";
    if (piece.bishop) return if (is_white) "♝" else "♗";
    if (piece.knight) return if (is_white) "♞" else "♘";
    if (piece.pawn) return if (is_white) "♟" else "♙";
    return "?";
}

pub fn printBoard(mat: [8][8]u8) void {
    std.debug.print("\n    a   b   c   d   e   f   g   h\n", .{});
    std.debug.print("  +---+---+---+---+---+---+---+---+\n", .{});
    for (0..8) |i| {
        const row_idx = 7 - i;
        const row = mat[row_idx];
        const rank_label: u8 = '1' + @as(u8, @intCast(row_idx));
        std.debug.print("{c} |", .{rank_label});
        for (row) |item| {
            std.debug.print(" {s} |", .{pieceToSymbol(item)});
        }
        std.debug.print(" {c}\n", .{rank_label});
        std.debug.print("  +---+---+---+---+---+---+---+---+\n", .{});
    }
    std.debug.print("    a   b   c   d   e   f   g   h\n\n", .{});
}

pub fn printBitboard(bb: Bitboard) void {
    std.debug.print("Bitboard for {b}\n", .{bb});
    std.debug.print("    a   b   c   d   e   f   g   h\n", .{});
    std.debug.print("  +---+---+---+---+---+---+---+---+\n", .{});
    for (0..8) |i| {
        const row_idx = 7 - i;
        std.debug.print("{c} |", .{'1' + @as(u8, @intCast(row_idx))});
        for (0..8) |j| {
            const square_index = row_idx * 8 + j;
            const occupied = (bb & (@as(Bitboard, 1) << @intCast(square_index))) != 0;
            std.debug.print(" {c} |", .{@as(u8, if (occupied) '*' else ' ')});
        }
        std.debug.print(" {c}\n", .{'1' + @as(u8, @intCast(row_idx))});
        std.debug.print("  +---+---+---+---+---+---+---+---+\n", .{});
    }
    std.debug.print("    a   b   c   d   e   f   g   h\n\n", .{});
}

pub fn san2idx(san: []const u8) !u8 {
    if (san.len != 2) return error.InvalidSAN;
    const file = san[0];
    const rank = san[1];
    if (file < 'a' or file > 'h') return error.InvalidSAN;
    if (rank < '1' or rank > '8') return error.InvalidSAN;
    const file_index = file - 'a';
    const rank_index = rank - '1';
    return @as(u8, rank_index * 8 + file_index);
}
