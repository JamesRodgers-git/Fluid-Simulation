const std = @import("std");
const app = @import("app");

extern fn wasmConsoleLog (ptr: u32, len: u32) void;

// const allocator = std.heap.wasm_allocator;

// var log_wasm_buffer: []u8 = undefined;
// var log_wasm_buffer: [1024]u8 = undefined; // check if this affects build size on non wasm platforms

pub fn init () void
{
    // log_wasm_buffer = allocator.alloc(u8, 1024) catch return;
}

pub fn log (comptime format: []const u8, args: anytype) void
{
    switch (comptime app.platform)
    {
        .web =>
        {
            // stack allocated buffer
            // var log_wasm_buffer: [format.len]u8 = undefined;

            // heap allocated locally
            // const log_wasm_buffer = allocator.alloc(u8, format.len) catch { return; };

            const message = std.fmt.comptimePrint(format, args);
            // const message = std.fmt.bufPrint(&log_wasm_buffer, format, args) catch return;
            // const ptr = @intFromPtr(&log_wasm_buffer[0]);
            const ptr = @intFromPtr(message);
            const len = message.len;
            wasmConsoleLog(ptr, len);

            // defer allocator.free(log_wasm_buffer);
        },
        .mac, .windows, .linux, .ios, .android =>
        {
            std.log.debug(format, args); // emited in release, adds "debug: " and a newline
            // std.debug.print(format, args); // kept in release, no newline
        },
        else => {}
    }
}