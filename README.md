<p align="center">
<img src="TeleZigDB_icon.png" alt="TeleZig" />
	<h1 align="center">TeleZigDB</h1>
</p>

TeleZigDB is a small Telegram bot project written in Zig. It works like redis (a simple key-value database) where you can store and retrieve values directly from Telegram chat commands...

## What it does

TeleZigDB lets you:

* store values using a `set` command
* retrieve values using a `get` command
* interact with the HashMap database directly from your Telegram bot..

## Motivation

I built this project while learning Zig. I wanted to understand how a Redis like key value database works internally and then implement a simplified version of it myself.

## Tech Stack

* Zig
* Telegram Bot API

## How To Start

After cloning the project, open `src/main.zig` and place your Telegram bot token in the source code.

Then run:

```bash
zig run src/main.zig
```

Once the program starts, open your Telegram bot and begin sending commands.

## Command Syntax

### Store a value

```text
set key value
```

Example:

```text
set username satya
```

This stores `satya` under the key `username`..

### Get a value

```text
get key
```

Example:

```text
get username
```

Output:

```text
satya
```

This retrieves the value associated with the key..

## How It Works

1. The program connects to Telegram using your bot token.
2. Messages sent to the bot are treated as database commands.
3. `set key value` stores a value in memory.
4. `get key` looks up the key and returns the stored value.
5. The database remains available as long as the program is running.

## Note

This is an in memory database, so all data is lost when the application stops. The current version is intentionally simple and focuses on the core Redis style key value concept rather than persistence or advanced database features :)
