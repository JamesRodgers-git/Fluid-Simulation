const app = @import("app");
const debug = @import("debug");
const metal = @import("darwin/metal.zig");

pub fn init () void
{
}

// Combines multiple libraries and shader files under 1 id. No duplicate function names allowed.
pub fn createLibraryGroup (comptime name: []const u8) usize
{
    if (comptime app.graphics_api == .metal)
    {
        return metal.createLibraryGroup(name);
    }

    debug.log("No platform for createLibraryGroup: {s}", .{ @tagName(app.platform) });
    return 0;
}

pub fn createLibrary (data: []const u8, library_group: usize) void
{
    if (comptime app.graphics_api == .metal)
    {
        metal.createLibrary(data, library_group);
    }
}

// pub fn setFunctionKeywords (name: []const u8, library_group: usize, const[] const[] u8 keywords) void
// {

// }

pub fn blit () void
{
    // switch (comptime app.graphicsAPI)
    // {
    //     .metal => init_and_open_window_osx(),
    //     else   => {},
    // }
}

// material is 1 vert + 1 frag + keywords + blending + uniforms
// TODO union with platform's implementation of Material
pub const Material = struct
{
    // metal.Material   
};

pub const RenderTarget = struct
{
    // var static_var: sometype = .{};

    // member_var: sometype = .{};
};

pub const DoubleRenderTarget = struct
{
    // var static_var: sometype = .{};

    // member_var: sometype = .{};
};

// &[_]f32{ -1, -1, -1, 1, 1, 1, 1, -1 }
// &[_]u16{ 0, 1, 2, 0, 2, 3 }