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
            .bot_toke = bot_token,
            .base_url = base_url,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Bot) void {
        defer self.allocator.free(self.base_url);
    }
};

pub fn main() !void {}
