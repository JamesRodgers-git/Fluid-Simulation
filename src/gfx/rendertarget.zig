// const std = @import("std");

// const sokol = @import("sokol");
// const sg = sokol.gfx;

// pub const RenderTarget = struct
// {
//     // var fullscreen_quad_bind: sg.Bindings = .{};

//     attachments_id: sg.Attachments = .{},
//     attachment_desc: sg.AttachmentDesc = .{},
// };

// const Blit = struct
// {
//     // static vars
//     var fullscreen_quad_pip: sg.Pipeline = .{}; // attributs layout and shader
//     var fullscreen_quad_bind: sg.Bindings = .{}; // static var; vertex, index buffers and input rt

//     var default_pass_action: sg.PassAction = .{};
// };

// pub fn initBlit () void
// {
//     var vertex_layout = sg.VertexLayoutState{};
//     vertex_layout.attrs[0].format = .FLOAT2;

//     Blit.fullscreen_quad_pip = sg.makePipeline(.{
//         // .shader = sg.makeShader(shd.fluidShaderDesc(sg.queryBackend())),
//         .layout = vertex_layout,
//         .index_type = .UINT16,
//     });

//     Blit.fullscreen_quad_bind.vertex_buffers[0] = sg.makeBuffer(.{
//         .data = sg.asRange(&[_]f32{ -1, -1, -1, 1, 1, 1, 1, -1 }),
//     });

//     Blit.fullscreen_quad_bind.index_buffer = sg.makeBuffer(.{
//         .type = .INDEXBUFFER,
//         .data = sg.asRange(&[_]u16{ 0, 1, 2, 0, 2, 3 }),
//     });


//     Blit.default_pass_action.colors[0] = .{
//         .load_action = .DONTCARE,
//         .store_action = .STORE,
//         .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
//     };
// }

// pub fn blit (source: RenderTarget, target: RenderTarget, pipeline_id: sg.Pipeline, uniforms: sg.Range) void
// {
//     _ = source;
//     // _ = shader_id;

//     // Blit.fullscreen_quad_pip.

//     sg.beginPass(.{ .action = Blit.default_pass_action, .attachments = target.attachments_id });
//         sg.applyPipeline(pipeline_id);
//         sg.applyBindings(Blit.bind);
//         sg.applyUniforms(0, uniforms);
//         sg.draw(0, 6, 1);
//     sg.endPass();
// }