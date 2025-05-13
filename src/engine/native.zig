const std = @import("std");
const app = @import("app");

extern fn init_and_open_window_osx () void;

//  init_cb: ?*const fn () callconv(.C) void = null,
pub fn startApp () void
{
    switch (comptime app.platform)
    {
        .mac => init_and_open_window_osx(),
        else   => {},
    }
}