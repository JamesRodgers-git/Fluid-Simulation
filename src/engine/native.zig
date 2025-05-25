const std = @import("std");
const app = @import("app");

// extern fn start_osx (initFn: *const fn () callconv(.C) void) void;
extern fn start_osx () void;

// pub fn startApp (init: *const fn () callconv(.C) void) void
pub fn startApp () void
{
    switch (comptime app.platform)
    {
        .mac => start_osx(), // (init)
        else   => {},
    }
}