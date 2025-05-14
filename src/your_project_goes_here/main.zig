// I will write here something to give you motivation to make your own project.

const std = @import("std");
const app = @import("app");
const debug = @import("debug");
const native = @import("native");

// Platforms with no-entry like web do not call main
pub fn main () void
{
    native.startApp();
    // On mac code doesn't execute here after [app run] from obj-c
}

// these parameters are not yet available in init call:
// - view render size
// -
export fn init () void
{
    debug.log("Platform: {s}", .{ @tagName(app.platform) });
}

// update and draw are synchronised at the same refresh rate but sometimes draw can be skipped

export fn update () void
{

}

export fn draw () void
{

}