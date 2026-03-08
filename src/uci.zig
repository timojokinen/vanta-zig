const std = @import("std");
const Position = @import("position.zig").Position;
const createPositionFromFEN = @import("position.zig").createPositionFromFEN;
const perft = @import("perft.zig").perft;

const SupportedCommands = enum {
    uci,
    ucinewgame,
    position,
    go,
    isready,
    stop,
    ponderhit,
    setoption,
    quit,
};

const GoArguments = enum { perft };

const PositionArguments = enum { startpos, fen };

pub fn uci_interface() !void {
    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout: *std.io.Writer = &stdout_writer.interface;

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const stdin: *std.io.Reader = &stdin_reader.interface;

    var position: Position = try createPositionFromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");

    while (true) {
        defer stdout.flush() catch {};

        const bare_line = try stdin.takeDelimiter('\n') orelse unreachable;
        const line = std.mem.trim(u8, bare_line, "\n");

        var cmd_parts = std.mem.splitAny(u8, line, " ");
        const raw_cmd = cmd_parts.next() orelse continue;
        const cmd = std.meta.stringToEnum(SupportedCommands, raw_cmd) orelse {
            var buf: [256]u8 = undefined;
            const result = try std.fmt.bufPrint(&buf, "Unknown command '{s}'.\n", .{raw_cmd});
            try stdout.writeAll(result);
            continue;
        };
        switch (cmd) {
            .quit => {
                break;
            },
            .uci => {
                try stdout.writeAll("id name Vanta 0.1\n");
                try stdout.writeAll("id author Timo Jokinen\n");
                try stdout.writeAll("uciok\n");
            },
            .go => {
                const raw_arg1 = cmd_parts.next() orelse return error.NotImplemented;
                const arg1 = std.meta.stringToEnum(GoArguments, raw_arg1) orelse return error.NotImplemented;

                switch (arg1) {
                    .perft => {
                        const raw_depth = cmd_parts.next() orelse return error.NotImplemented;
                        const depth: usize = try std.fmt.parseInt(usize, raw_depth, 10);
                        _ = try perft(&position, depth);
                    },
                }
            },
            .isready => {
                try stdout.writeAll("readyok\n");
            },
            .ponderhit => {},
            .position => {
                const raw_arg1 = cmd_parts.next() orelse return error.MissingArgument;
                const arg1 = std.meta.stringToEnum(PositionArguments, raw_arg1) orelse return error.NotImplemented;

                switch (arg1) {
                    .fen => {
                        const raw_fen = cmd_parts.rest();
                        position = try createPositionFromFEN(raw_fen);
                    },
                    .startpos => {
                        position = try createPositionFromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
                    },
                }
            },
            .setoption => {},
            .stop => {},
            .ucinewgame => {},
        }
    }
}
