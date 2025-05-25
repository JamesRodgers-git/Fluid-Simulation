const std = @import("std");
const app = @import("app");
const debug = @import("debug");
const files = @import("files");

extern fn createLibraryFromData_metal (data: [*]const u8, length: usize) usize;
extern fn createPipelineVertFrag_metal (library_idx: usize) usize;

pub fn loadMetalResources () void
{
    loadMetalShader("shader.metallib");
}

fn loadMetalShader (shaderName: []const u8) void
{
    if (comptime app.graphics_api == .metal)
    {
        // debug.startTimer();
        const allocator = std.heap.page_allocator;
        const buffer = files.loadFile(allocator, shaderName) catch unreachable;
        // debug.printTimer();

        if (buffer) |value|
        {
            defer allocator.free(value);
            const library_idx = createLibraryFromData_metal(value.ptr, value.len);
            _ = createPipelineVertFrag_metal(library_idx);
        }
    }
}