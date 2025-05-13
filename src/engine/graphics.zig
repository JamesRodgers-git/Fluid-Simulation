const app = @import("app");

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

pub fn init () void
{
}

pub fn blit () void
{
    // switch (comptime app.graphicsAPI)
    // {
    //     .metal => init_and_open_window_osx(),
    //     else   => {},
    // }
}