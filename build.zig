const std = @import("std");
// const sokol = @import("sokol");
// const shdc = @import("shdc");

/// Command to run debug
// zig build run
//
/// Command to run optimized release
// zig build --release=fast run
//
/// This is for running in web browser. It also launches local web server:
// http://localhost:6931/fluid.html
// zig build -Dtarget=wasm32-emscripten run
// zig build --release=fast -Dtarget=wasm32-emscripten run
// 
/// Just left over for the future
// --release=small --release=safe  wasm32-freestanding wasm32-wasi

pub fn build (b: *std.Build) !void
{
    // if (b.option(bool, "onefile", "Generate single-file bundle and exit") orelse false)
    // {
    //     std.debug.print("Hey", .{});
    //     return;
    // }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main_exe = b.addExecutable(.{
        .name = "fluid",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        // .root_module = exe_mod,
        // .single_threaded = true,
        // .strip = true,
        // .omit_frame_pointer = false,
        // .unwind_tables = .none,
        // .error_tracing = false
    });

    if (target.result.os.tag == .macos)
    {
        try std.fs.cwd().makePath("zig-out/lib/");

        const cmd_objc = b.addSystemCommand(&.{
            // "swiftc",
            // "window.swift",
            // "-emit-library",
            // "-emit-objc-header",
            // "-emit-clang-header-path",
            // "-static-stdlib",
            // "-static",
            // "-o", "libwindow.a", "window.swift"

            "clang",
            // "-O3",
            "-c", "src/native/cocoa_osx.mm",
            "-o", "zig-out/lib/cocoa_osx.o",
            // "-framework", "Cocoa",
        });

        // cmd_objc.setCwd(b.path("src"));
        cmd_objc.addCheck(.{ .expect_term = .{ .Exited = 0 } });
        cmd_objc.has_side_effects = true;

        main_exe.step.dependOn(&cmd_objc.step);

        // main_exe.linkLibC();
        // main_exe.linkLibCpp();
        // main_exe.linkFramework("Foundation");
        main_exe.linkFramework("Cocoa");
        main_exe.linkFramework("Metal");
        main_exe.linkFramework("QuartzCore");
        main_exe.addObjectFile(b.path("zig-out/lib/cocoa_osx.o"));

        // main_exe.addLibraryPath(std.Build.LazyPath {
        //     .cwd_relative = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx",
        // });
        // main_exe.linkSystemLibrary("swiftCore");

        // lib.installHeadersDirectory(b.path("src"), "", .{});
        // exe.addIncludeDir("/usr/local/include/SDL2");
        // exe.addLibPath("/usr/local/lib");
        
        // main_exe.addFrameworkPath(b.path("/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks"));
        // main_exe.addIncludePath(lazy_path: LazyPath)
    }

    b.installArtifact(main_exe);

    const run = b.addRunArtifact(main_exe);
    run.step.dependOn(b.getInstallStep());
    b.step("run", "Run the app").dependOn(&run.step);

    // const dep_sokol = b.dependency("sokol", .{
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const exe_mod = b.createModule(.{
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     // .imports = &.{
    //     //     .{ .name = "sokol", .module = dep_sokol }
    //     // }
    //     // .unwind_tables = .none,
    //     // .strip = true
    // });
    // exe_mod.addImport("sokol", dep_sokol.module("sokol"));

    // if (target.result.cpu.arch.isWasm())
    // {
    //     // const opt_shd_step = try buildShaders(b);

    //     const main = b.addStaticLibrary(.{
    //         .name = "fluid",
    //         .target = target,
    //         .optimize = optimize,
    //         .root_source_file = b.path("src/main.zig"),
    //     });
    //     main.root_module.addImport("sokol", dep_sokol.module("sokol"));

    //     // if (opt_shd_step) |shd_step|
    //     //     main.step.dependOn(&shd_step.step);

    //     // Emscripten linker
    //     const emsdk = dep_sokol.builder.dependency("emsdk", .{});
    //     const link_step = try sokol.emLinkStep(b, .{
    //         .lib_main = main,
    //         .target = target,
    //         .optimize = optimize,
    //         .emsdk = emsdk,
    //         .use_webgpu = false,
    //         .use_webgl2 = true,
    //         .use_emmalloc = true,
    //         .use_filesystem = false,
    //         // .use_offset_converter = true,
    //         // .extra_args = &.{"-sSTACK_SIZE=512KB"},
    //         .shell_file_path = dep_sokol.path("src/sokol/web/shell.html"),
    //         // // don't run Closure minification for WebGPU, see: https://github.com/emscripten-core/emscripten/issues/20415
    //         // .release_use_closure = options.backend != .wgpu,
    //     });
    //     b.getInstallStep().dependOn(&link_step.step);

    //     // sokol.sha

    //     const run = sokol.emRunStep(b, .{ .name = "fluid", .emsdk = emsdk });
    //     run.addArg("--no_browser"); // comment this line if you want it to focus on web browser after build
    //     run.step.dependOn(&link_step.step);
    //     b.step("run", "Run fluid web").dependOn(&run.step);
    // }



    // const exe_check = b.addExecutable(.{
    //     .name = "fluid",
    //     .root_source_file = b.path("src/main.zig"),
    // });

    // const check = b.step("check", "Check if fluid compiles");
    // check.dependOn(&exe_check.step);
}

// fn buildShaders (b: *std.Build) !?*std.Build.Step.Run
// {
//     // if (!example.has_shader)
//     //     return null;

//     const shaders_dir = "src/shaders/";
//     const input_path = b.fmt("{s}{s}.glsl", .{ shaders_dir, "fluid" });
//     const output_path = b.fmt("{s}{s}.glsl.zig", .{ shaders_dir, "fluid" });
//     return try shdc.compile(b, .{
//         .dep_shdc = b.dependency("shdc", .{}),
//         .input = b.path(input_path),
//         .output = b.path(output_path),
//         .slang = .{
//             // .glsl430 = example.needs_compute,
//             // .glsl410 = !example.needs_compute,
//             // .glsl310es = example.needs_compute,
//             .glsl300es = true,
//             .metal_macos = true,
//             // .hlsl5 = true,
//             // .wgsl = true,
//         },
//         .reflection = true,
//     });
// }



