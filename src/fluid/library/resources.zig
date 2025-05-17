const std = @import("std");
const app = @import("app");
const debug = @import("debug");
const files = @import("files");

extern fn create_library_from_data_metal (data: [*]const u8, length: usize) usize;
extern fn create_pipeline_vertfrag_metal (library_idx: usize) usize;

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

        if (buffer) |value|
        {
            defer allocator.free(value);
            const library_idx = create_library_from_data_metal(value.ptr, value.len);
            _ = create_pipeline_vertfrag_metal(library_idx);
        }
    }
}