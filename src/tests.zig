//! Just for quick temporary code tests.
//! It is easy in VS Code to run a test as it has buttons near "test" declarations.

const std = @import("std");

test "test"
{
    // std.testing.refAllDecls(@This());

    std.debug.print("Hello \n", .{});
}