const std = @import("std");
const app = @import("app");
const debug = @import("debug");
const files = @import("files");
const graphics = @import("graphics");
const materials = @import("materials");

// TODO async file loading
// TODO arena allocator
// TODO fast stack allocator for small files
pub fn load () void
{
    if (comptime app.graphics_api == .metal)
    {
        loadShaderFile("shader.metallib", materials.fluid_group);
    }
}

fn loadShaderFile (shaderName: []const u8, library_group: usize) void
{
    // debug.startTimer();
    const allocator = std.heap.page_allocator;
    const buffer = files.loadFile(allocator, shaderName) catch unreachable;
    // debug.printTimer();

    if (buffer) |buf|
    {
        defer allocator.free(buf);
        graphics.createLibrary(buf, library_group);
    }
}