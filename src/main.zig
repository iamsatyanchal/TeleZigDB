const std = @import("std");
const memory = std.mem;
const show = std.debug.print;
const fmt = std.fmt.allocPrint;
const heap = std.heap;

pub const Bot = struct {
    bot_token: []const u8,
    base_url: []const u8,
    allocator: memory.Allocator,

    pub fn init(allocator: memory.Allocator, bot_token: []const u8) !Bot {
        const base_url = try fmt(allocator, "https://195.3.220.74/bot{s}", .{bot_token});
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
        const url = try fmt(self.allocator, "{s}/getMe?__cpo=aHR0cHM6Ly9hcGkudGVsZWdyYW0ub3Jn", .{self.base_url});
        show("Calling URL: {s}\n", .{url});
        defer self.allocator.free(url);

        var http = std.http.Client{ .allocator = self.allocator };
        defer http.deinit();

        const url_parse = try std.Uri.parse(url);

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

    var bot = try Bot.init(allocator, "token");
    defer bot.deinit();

    try bot.getbot();
    show("Bot initialized successfully!\n\nCalling URL: {s}\n", .{bot.base_url});
}
