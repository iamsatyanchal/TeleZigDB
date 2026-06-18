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

// All this because telegram is bnanned in india.. custom proxy server, url encoding :/

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

const Method = enum { GET, POST };

fn fetch(allocator: memory.Allocator, method: Method, url: std.Uri) ![]const u8 {
    var http = std.http.Client{ .allocator = allocator };
    defer http.deinit();

    var trace_header: [1024]u8 = undefined;
    var request = switch (method) {
        .GET => try http.open(.GET, url, .{
            .server_header_buffer = &trace_header,
        }),
        .POST => try http.open(.POST, url, .{
            .server_header_buffer = &trace_header,
        }),
    };
    defer request.deinit();

    try request.send();
    try request.finish();
    try request.wait();

    return try request.reader().readAllAlloc(allocator, 8196);
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
        self.allocator.free(self.base_url);
    }

    pub fn getbot(self: Bot) !void {
        const url_raw = try fmt(self.allocator, "{s}/getMe", .{self.base_url});
        show("Calling URL: {s}\n\n", .{url_raw});
        defer self.allocator.free(url_raw);

        const url = try encodeUri(
            self.allocator,
            url_raw,
        );
        defer self.allocator.free(url);

        const final_url = try fmt(
            self.allocator,
            "https://telezigdb-proxy.vercel.app/?url={s}",
            .{url},
        );
        defer self.allocator.free(final_url);
        const url_parse = try std.Uri.parse(final_url);

        const response = try fetch(self.allocator, .GET, url_parse);
        defer self.allocator.free(response);

        show("Bot profile fetched successfully!\n\n{s}\n", .{response});
    }

    pub fn sendMessage(self: Bot, chat_id: i64, text: []const u8) !void {
        const url_raw = try fmt(self.allocator, "{s}/sendMessage?chat_id={d}&text={s}", .{ self.base_url, chat_id, text });
        defer self.allocator.free(url_raw);
        const url = try encodeUri(self.allocator, url_raw);
        defer self.allocator.free(url);

        const final_url = try fmt(self.allocator, "https://telezigdb-proxy.vercel.app/?url={s}", .{url});

        defer self.allocator.free(final_url);

        const url_parsed = try std.Uri.parse(final_url);
        const response = try fetch(self.allocator, .GET, url_parsed);

        defer self.allocator.free(response);

        show("Message sent successfully!\n\n{s}\n", .{response});
    }

    pub fn getUpdates(self: Bot) ![]const u8 {
        const url_raw = try fmt(self.allocator, "{s}/getUpdates?offset=-1&limit=1", .{self.base_url});
        defer self.allocator.free(url_raw);

        const url = try encodeUri(self.allocator, url_raw);
        defer self.allocator.free(url);

        const final_url = try fmt(self.allocator, "https://telezigdb-proxy.vercel.app/?url={s}", .{url});
        defer self.allocator.free(final_url);

        const url_parsed = try std.Uri.parse(final_url);
        const response = try fetch(self.allocator, .GET, url_parsed);

        // show("Updates fetched successfully!\n\n{s}\n", .{response});

        return response;
    }

    // pub fn polling(self: Bot) !void {
    //     while (true) {
    //         const updates = try self.getUpdates();
    //         defer self.allocator.free(updates);
    //         std.Thread.sleep(5 * std.time.ns_per_s);
    //     }
    // }
};

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var database = std.StringHashMap([]const u8).init(allocator);
    defer database.deinit();

    var bot = try Bot.init(allocator, "token");
    defer bot.deinit();

    show("Bot initialized successfully!\n\n", .{});

    // try bot.getbot();

    // try bot.sendMessage("5107456398", "Hello from TeleZigDB!");

    var last_update_id: i64 = 0;

    while (true) {
        const updates = try bot.getUpdates();
        {
            defer bot.allocator.free(updates);

            const parsed_json_response = try std.json.parseFromSlice(std.json.Value, allocator, updates, .{});
            defer parsed_json_response.deinit();

            const root = parsed_json_response.value;
            const result = root.object.get("result").?;
            if (result.array.items.len > 0) {
                if (result.array.items[0].object.get("update_id").?.integer != last_update_id) {
                    if (result.array.items[0].object.get("message").?
                        .object.get("text")) |text|
                    {
                        last_update_id = result.array.items[0].object.get("update_id").?.integer;
                        show("\nNew update received! Update ID: {d}\n", .{last_update_id});
                        show("--> {s} : {s}\n", .{ result.array.items[0]
                            .object.get("message").?
                            .object.get("chat").?
                            .object.get("first_name").?.string, text.string });

                        const message_reply = try fmt(allocator, "{s}", .{text.string});
                        try bot.sendMessage(result.array.items[0]
                            .object.get("message").?
                            .object.get("chat").?
                            .object.get("id").?.integer, message_reply);
                    }
                }
            }
        }
        // std.Thread.sleep(5 * std.time.ns_per_s);
    }
}
