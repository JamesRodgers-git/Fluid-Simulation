const std = @import("std");
const builtin = @import("builtin");

pub const RuntimePlatform = enum
{
    undefined,
    web,
    mac,
    windows,
    linux,
    ios,
    android,

    pub fn isDesktop (comptime self: RuntimePlatform) bool
    {
        return self == .mac or self == .windows or self == .linux;
    }

    pub fn isMobile (comptime self: RuntimePlatform) bool
    {
        return self == .ios or self == .android;
    }

    pub fn supportFileSystem (comptime self: RuntimePlatform) bool
    {
        return self != .web;
    }

    // pub fn tag (comptime self: RuntimePlatform) []const u8 //struct { []const u8 }
    // {
    //     return @tagName(self);
    //     // return .{ @tagName(self) };
    // }
};

pub const GraphicsAPI = enum
{
    undefined,
    webgl2,
    metal,
};

pub const platform = PickPlatform();
pub const graphics_api = PickGraphicsAPI();

fn PickPlatform () RuntimePlatform
{
    if (builtin.target.cpu.arch.isWasm())
        return .web;
    if (builtin.target.abi.isAndroid())
        return .android;

    switch (builtin.target.os.tag)
    {
        .macos => return .mac,
        .windows => return .windows,
        .linux => return .linux,
        .ios => return .ios,
        else => {}
        // .darwin => target.os.tag.isDarwin(),
    }

    return .undefined;
}

fn PickGraphicsAPI () GraphicsAPI
{
    if (builtin.target.cpu.arch.isWasm())
        return .webgl2;
    // if (builtin.target.abi.isAndroid())
    //     return .android;

    switch (builtin.target.os.tag)
    {
        .macos => return .metal,
        // .windows => return .windows,
        // .linux => return .linux,
        // .ios => return .ios,
        else => {}
        // .darwin => target.os.tag.isDarwin(),
    }

    return .undefined;
}

// pub fn init () void
// {
// }