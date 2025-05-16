const std = @import("std");
const app = @import("app");
const debug = @import("debug");
const files = @import("files");

extern fn create_render_pipeline_metal (data: [*]const u8, length: usize) void;

pub fn loadMetalResources () void
{
    loadMetalShader("shader.metallib");
}

fn loadMetalShader (shaderName: []const u8) void
{
    if (comptime app.graphicsAPI == .metal)
    {
        // debug.startTimer();
        const allocator = std.heap.page_allocator;
        const buffer = files.loadFile(allocator, shaderName) catch unreachable;
        // debug.printTimer();

        if (buffer) |buf|
        {
            defer allocator.free(buf);
            create_render_pipeline_metal(buf.ptr, buf.len);
        }
    }
}