const std = @import("std");
const builtin = @import("builtin");

extern fn init_and_open_window_osx () void;
// extern fn create_window_osxc () void;

pub fn createWindow () void
{
    switch (comptime builtin.os.tag)
    {
        .macos => init_and_open_window_osx(),
        else   => @compileLog("Unsupported OS"),
    }
}