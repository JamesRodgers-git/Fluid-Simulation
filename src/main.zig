const std = @import("std");

const app = @import("app");
const debug = @import("debug");
const native = @import("native/native.zig");

// Platforms with no-entry like web does not call main
pub fn main () void
{
    native.startApp();
    // On mac code doesn't execute here after [app run] from obj-c
}

export fn init () void
{
    debug.log("Platform: {s}", .{ @tagName(app.platform) });

    // build size grows quickly with every log
    // debug.init();
    debug.log("hi", .{});
    debug.log("hii", .{});
    debug.log("hiii", .{});
    debug.log("hi {}", .{5});
}


// const sokol = @import("sokol");
// const slog = sokol.log;
// const sg = sokol.gfx;
// const sapp = sokol.app;
// const sglue = sokol.glue;

// const shd = @import("shaders/fluid.glsl.zig");

// const State = struct
// {
//     var pip: sg.Pipeline = .{}; // shader, attributes
//     var bind: sg.Bindings = .{}; // vertex and index data
//     var pass_action: sg.PassAction = .{}; // global
//     // pass_action: sg.PassAction // local
// };

// var pass_action: sg.PassAction = .{}; // global
// const pass_action: sg.PassAction = .{}; // global const

// export fn init () void
// {
//     sg.setup(.{
//         .environment = sglue.environment(),
//         .logger = .{ .func = slog.func },
//     });
//     State.pass_action.colors[0] = .{
//         .load_action = .CLEAR,
//         .clear_value = .{ .r = 1, .g = 1, .b = 0, .a = 1 },
//     };

//     // var atts_desc = sg.AttachmentsDesc{};
//     // atts_desc.colors[0].image = color_img;
//     // atts_desc.depth_stencil.image = depth_img;
//     // state.offscreen.attachments = sg.makeAttachments(atts_desc);


//     // a shader and pipeline state object
//     State.pip = sg.makePipeline(.{
//         .shader = sg.makeShader(shd.fluidShaderDesc(sg.queryBackend())),
//         .layout = init: {
//             var l = sg.VertexLayoutState{};
//             l.attrs[shd.ATTR_fluid_position].format = .FLOAT3;
//             l.attrs[shd.ATTR_fluid_color0].format = .FLOAT4;
//             break :init l;
//         },
//         .index_type = .UINT16,
//     });
    

//     // a vertex buffer
//     State.bind.vertex_buffers[0] = sg.makeBuffer(.{
//         .data = sg.asRange(&[_]f32{
//             // positions      colors
//             -0.5, 0.5,  0.5, 1.0, 0.0, 0.0, 1.0,
//             0.5,  0.5,  0.5, 0.0, 1.0, 0.0, 1.0,
//             0.5,  -0.5, 0.5, 0.0, 0.0, 1.0, 1.0,
//             -0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0,
//         }),
//     });

//     // an index buffer
//     State.bind.index_buffer = sg.makeBuffer(.{
//         .type = .INDEXBUFFER,
//         .data = sg.asRange(&[_]u16{ 0, 1, 2, 0, 2, 3 }),
//     });


//     std.debug.print("Backend: {}\n", .{sg.queryBackend()});

//     // std.debug.panic("Fake NullReferenceException\n", .{});
// }

// export fn frame () void
// {
//     // const g = State.pass_action.colors[0].clear_value.g + 0.01;
//     // State.pass_action.colors[0].clear_value.g = if (g > 1.0) 0.0 else g;
//     sg.beginPass(.{ .action = State.pass_action, .swapchain = sglue.swapchain() });
//         sg.applyPipeline(State.pip);
//         sg.applyBindings(State.bind);
//         sg.draw(0, 6, 1);
//     sg.endPass();
//     sg.commit();
// }

// export fn cleanup () void
// {
//     sg.shutdown();
// }