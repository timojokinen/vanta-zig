const std = @import("std");

const Color = @import("utils.zig").Color;
const pieceToSymbol = @import("utils.zig").pieceToSymbol;
const san2idx = @import("utils.zig").san2idx;
const printBoard = @import("utils.zig").printBoard;
const Piece = @import("piece.zig").Piece;
const makePiece = @import("piece.zig").makePiece;

const FENParsingError = error{
    InvalidPartCount,
};

pub const CastlingRights = packed struct(u4) {
    white_kingside: bool,
    white_queenside: bool,
    black_kingside: bool,
    black_queenside: bool,
};

pub const BoardState = struct {
    mat_8x8: [8][8]u8,
    side_to_move: Color,
    castling_rights: CastlingRights,
    en_passant_square: ?u6,
    halfmove_clock: u32,
    fullmove_number: u32,
};

pub fn parseFen(fen: []const u8) !BoardState {
    var iterator = std.mem.splitAny(u8, fen, " ");
    var mat_8x8: [8][8]u8 = .{.{0} ** 8} ** 8;

    const piece_placement = iterator.next() orelse return FENParsingError.InvalidPartCount;

    var ranks = std.mem.splitAny(u8, piece_placement, "/");
    for (0..8) |fen_rank_idx| {
        const rank = ranks.next() orelse return FENParsingError.InvalidPartCount;
        const row_idx = 7 - fen_rank_idx;
        var col: usize = 0;
        for (rank) |char| {
            if (char >= '1' and char <= '8') {
                const empty_squares = char - '0';
                col += empty_squares;
                continue;
            }
            const piece: Piece = switch (char) {
                'P' => makePiece(.White, .Pawn),
                'N' => makePiece(.White, .Knight),
                'B' => makePiece(.White, .Bishop),
                'R' => makePiece(.White, .Rook),
                'Q' => makePiece(.White, .Queen),
                'K' => makePiece(.White, .King),
                'p' => makePiece(.Black, .Pawn),
                'n' => makePiece(.Black, .Knight),
                'b' => makePiece(.Black, .Bishop),
                'r' => makePiece(.Black, .Rook),
                'q' => makePiece(.Black, .Queen),
                'k' => makePiece(.Black, .King),
                else => {
                    std.debug.print("Invalid character in FEN: {c}\n", .{char});
                    return FENParsingError.InvalidPartCount;
                },
            };
            mat_8x8[row_idx][col] = @bitCast(piece);
            col += 1;
        }
    }

    const side_to_move_str = iterator.next() orelse return FENParsingError.InvalidPartCount;
    const side_to_move: Color = switch (side_to_move_str[0]) {
        'w' => .White,
        'b' => .Black,
        else => {
            std.debug.print("Invalid side to move in FEN: {c}\n", .{side_to_move_str[0]});
            return FENParsingError.InvalidPartCount;
        },
    };

    const castling_rights_str = iterator.next() orelse return FENParsingError.InvalidPartCount;
    const castling_rights: CastlingRights = .{
        .white_kingside = std.mem.containsAtLeast(u8, castling_rights_str, 1, "K"),
        .white_queenside = std.mem.containsAtLeast(u8, castling_rights_str, 1, "Q"),
        .black_kingside = std.mem.containsAtLeast(u8, castling_rights_str, 1, "k"),
        .black_queenside = std.mem.containsAtLeast(u8, castling_rights_str, 1, "q"),
    };

    const en_passant_target = iterator.next() orelse return FENParsingError.InvalidPartCount;
    const en_passant_sqidx: ?u6 = if (en_passant_target[0] != '-')
        try san2idx(en_passant_target)
    else
        null;

    const halfmove_clock_str = iterator.next() orelse return FENParsingError.InvalidPartCount;
    const halfmove_clock = try std.fmt.parseInt(u32, halfmove_clock_str, 10);

    const fullmove_number_str = iterator.next() orelse return FENParsingError.InvalidPartCount;
    const fullmove_number = try std.fmt.parseInt(u32, fullmove_number_str, 10);

    return .{
        .mat_8x8 = mat_8x8,
        .side_to_move = side_to_move,
        .castling_rights = castling_rights,
        .en_passant_square = en_passant_sqidx,
        .halfmove_clock = halfmove_clock,
        .fullmove_number = fullmove_number,
    };
}
