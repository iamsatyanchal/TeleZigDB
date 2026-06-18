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
        const base_url = try fmt(allocator, "https://api.telegram.com/bot{s}", .{bot_token});
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
        const url = fmt.allocPrint(self.allocator, "{s}/getMe", .{self.bot_token});
        defer self.allocator.free(url);

        var http = std.http.Client{ .allocator = self.allocator };
        defer http.deinit();

        const url_parse = try std.Uri.parse(url);

        var trace_header: [1024]u8 = undefined;
    }
};

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var bot = try Bot.init(allocator, "this_is_a_token");
    defer bot.deinit();

    show("{any}", .{bot});
}
