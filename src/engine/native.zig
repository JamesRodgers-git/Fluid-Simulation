const std = @import("std");
const app = @import("app");

extern fn initAndOpenWindow_osx () void;

//  init_cb: ?*const fn () callconv(.C) void = null,
pub fn startApp () void
{
    switch (comptime app.platform)
    {
        .mac => initAndOpenWindow_osx(),
        else   => {},
    }
}