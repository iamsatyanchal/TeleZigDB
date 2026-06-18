const std = @import("std");
const memory = std.mem;
const show = std.debug.print;
const fmt = std.fmt.allocPrint;
const heap = std.heap;

fn isValidUriChar(c: u8) bool {
    return switch (c) {
        'A'...'Z', 'a'...'z', '0'...'9', '-', '_', '.', '~' => true,
        else => false,
    };
}

fn encodeUri(allocator: memory.Allocator, url: []const u8) ![]const u8 {
    var encoded = std.ArrayList(u8).init(allocator);
    defer encoded.deinit();

    try std.Uri.Component.percentEncode(
        encoded.writer(),
        url,
        isValidUriChar,
    );

    return try encoded.toOwnedSlice();
}

pub const Bot = struct {
    bot_token: []const u8,
    base_url: []const u8,
    allocator: memory.Allocator,

    pub fn init(allocator: memory.Allocator, bot_token: []const u8) !Bot {
        const base_url = try fmt(allocator, "https://api.telegram.org/bot{s}", .{bot_token});
        return Bot{
            .bot_token = bot_token,
            .base_url = base_url,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Bot) void {
        defer self.allocator.free(self.base_url);
    }

    pub fn getbot(self: Bot) !void {
        const url_raw = try fmt(self.allocator, "{s}/getMe", .{self.base_url});
        show("Calling URL: {s}\n", .{url_raw});
        defer self.allocator.free(url_raw);

        const url = try encodeUri(
            self.allocator,
            url_raw,
        );
        defer self.allocator.free(url);

        show("Encoded URL: {s}\n", .{url});

        var http = std.http.Client{ .allocator = self.allocator };
        defer http.deinit();

        const final_url = try fmt(
            self.allocator,
            "https://telezigdb-proxy.vercel.app/?url={s}",
            .{url},
        );
        defer self.allocator.free(final_url);
        const url_parse = try std.Uri.parse(final_url);
        var trace_header: [1024]u8 = undefined;

        var request = try http.open(.GET, url_parse, .{ .server_header_buffer = &trace_header });

        try request.send();
        try request.finish();
        try request.wait();

        const response = try request.reader().readAllAlloc(self.allocator, 8196);

        defer self.allocator.free(response);

        show("Bot profile fetched successfully!\n\n{s}\n", .{response});

        defer request.deinit();
    }
};

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var bot = try Bot.init(allocator, "5323632422:AAGq5yRXfblJclgg-jElc65PHvH3KJn2wO4");
    defer bot.deinit();

    show("Bot initialized successfully!\n\n", .{});

    try bot.getbot();
}
