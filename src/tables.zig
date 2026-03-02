const attacks = @import("attacks.zig");
const utils = @import("utils.zig");

const BISHOP_TABLE_SIZE: usize = 5248;
const ROOK_TABLE_SIZE: usize = 102400;

var bishop_table: [BISHOP_TABLE_SIZE]u64 = undefined;
var bishop_offsets: [64]u64 = undefined;
var rook_table: [ROOK_TABLE_SIZE]u64 = undefined;
var rook_offsets: [64]u64 = undefined;

var bishop_masks: [64]u64 = undefined;
var rook_masks: [64]u64 = undefined;
var knight_masks: [64]u64 = undefined;
var king_masks: [64]u64 = undefined;
var white_pawns_masks: [64]u64 = undefined;
var black_pawns_masks: [64]u64 = undefined;

pub fn initTables() void {
    var curr_bishop_offset: usize = 0;
    // var curr_rook_offset = 0;
    // bishop masks
    for (0..64) |sq| {
        const edges =
            ((utils.RANKS[0] | utils.RANKS[7]) & ~utils.maskRank(@intCast(sq))) |
            ((utils.FILES[0] | utils.FILES[7]) & ~utils.maskFile(@intCast(sq)));

        const piece_bb = @as(u64, 1) << @intCast(sq);

        // BISHOP MASKS
        const diag = utils.maskDiag(@intCast(sq));
        const anti_diag = utils.maskAntiDiag(@intCast(sq));
        const bishop_mask = (diag | anti_diag) & ~(edges) & ~(piece_bb);
        bishop_masks[sq] = bishop_mask;

        // BISHOP TABLE
        const relevant_bishop_bits = @popCount(bishop_mask);
        const table_size = @as(u64, 1) << @intCast(relevant_bishop_bits);
        bishop_offsets[sq] = curr_bishop_offset;

        var bishop_subset: u64 = 0;
        while (true) {
            const bishop_attacks = attacks.bishopAttacks(@intCast(sq), bishop_subset);
            utils.printBitboard(bishop_attacks);
            const index = utils.pext(bishop_subset, bishop_mask);
            bishop_table[curr_bishop_offset + index] = bishop_attacks;
            bishop_subset = (bishop_subset -% bishop_mask) & bishop_mask;
            if (bishop_subset == 0) break;
        }
        curr_bishop_offset += table_size;

        // ROOK MASKS
        const rank = utils.maskRank(@intCast(sq));
        const file = utils.maskFile(@intCast(sq));
        const rook_mask = (rank | file) & ~(edges) & ~(piece_bb);
        rook_masks[sq] = rook_mask;

        knight_masks[sq] = attacks.knightAttacks(@intCast(6));
        king_masks[sq] = attacks.kingAttacks(@intCast(6));
        white_pawns_masks[sq] = attacks.pawnAttacks(@intCast(6), utils.Color.White);
        black_pawns_masks[sq] = attacks.pawnAttacks(@intCast(6), utils.Color.Black);
    }
}
