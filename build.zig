const std = @import("std");
// const sokol = @import("sokol");
// const shdc = @import("shdc");

/// Command to run debug
//~ zig build run

/// Command to run optimized build
//~ zig build --release=fast run

/// You can add --watch to always build on code changes. Very convenient btw.

/// This is for building web version
//~ zig build -Dtarget=wasm32-freestanding -p projects/web --watch
/// Then run local server and open in web browser http://localhost:1369/
//~ python3 -m http.server 1369 --directory projects/web

/// Just left over for the future
// --release=small --release=safe  wasm32-freestanding wasm32-wasi wasm32-emscripten
// --verbose

pub fn build (b: *std.Build) !void
{
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //const target = b.resolveTargetQuery(.{ .os_tag = .macos });

    if (target.result.cpu.arch.isWasm())
    {
        const exe = b.addExecutable(.{
            .name = "fluid",
            .target = target,
            .optimize = .ReleaseSmall, // .Debug .ReleaseFast
            .root_source_file = b.path("src/fluid/main.zig"),
        });
        exe.entry = .disabled;
        exe.rdynamic = true;

        // exe.root_module.export_symbol_names

        addCommonImports(b, exe.root_module);
        b.installArtifact(exe);
    }
    else if (target.result.os.tag == .macos)
    {
        try std.fs.cwd().makePath("zig-out/lib/");

        const exe = b.addExecutable(.{
            .name = "fluid",
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/fluid/main.zig"),
            // .root_module = exe_mod,
            // .single_threaded = true,
            // .strip = true,
            // .omit_frame_pointer = false,
            // .unwind_tables = .none,
            // .error_tracing = false
        });
        // exe.entry = .{ .symbol_name = "init" };
        // exe.entry = .disabled;

        // const exe_lib = b.addStaticLibrary(.{
        //     .name = "fluid",
        //     .target = target,
        //     .optimize = optimize,
        //     .root_source_file = b.path("src/fluid/main.zig"),
        // });
        // exe_lib.entry = .disabled;

        const cmd_metalir = b.addSystemCommand(&.{
            "xcrun", "-sdk", "macosx", "metal",
            "-o", "zig-out/bin/shader.ir",
            "-c", "src/fluid/shaders/shader.metal",
        });

        const cmd_metallib = b.addSystemCommand(&.{
            "xcrun", "-sdk", "macosx", "metallib",
            "-o", "zig-out/bin/shader.metallib",
            "zig-out/bin/shader.ir",
        });
        // cmd_metallib.addCheck(.{ .expect_term = .{ .Exited = 0 } });
        // cmd_metallib.has_side_effects = true;

        // const cmd_objc = b.addSystemCommand(&.{
        //     "clang",
        //     // "-O3",
        //     "-o", "zig-out/lib/cocoa_osx.o",
        //     "-c", "src/engine/darwin/cocoa_osx.mm",
        // });

        const cmd_swift = b.addSystemCommand(&.{
            "xcrun", "swiftc",
            "-emit-object",
            // "-emit-library", // this one also exports _main and use linker magic
            "-static", // does it work?
            "-parse-as-library", // removes _main

            "-I", "src/engine/darwin/",
            "-o", "zig-out/lib/cocoa_osx.o",

            // sources:
            "src/engine/darwin/cocoa_osx.swift",

            if (optimize == .Debug) "-Onone" else "-O",

            // for the future
            // "-target-cpu"
            // "-target",
            // b.fmt("{s}-apple-macosx{}", .{
            //     @tagName(target.result.cpu.arch),
            //     target.result.os.version_range.semver.min,
            // }),
        });
        if (optimize == .Debug) cmd_swift.addArgs(&.{ "-D", "DEBUG" });
        // exe.addArg("-mmacos-version-min=11.0"); // sets minimum macos version

        const install_exe = b.addInstallArtifact(exe, .{});

        addLibrariesOSX(b, target, exe);
        addCommonImports(b, exe.root_module);
        exe.addObjectFile(b.path("zig-out/lib/cocoa_osx.o"));

        sequence(b, &.{
            &cmd_metalir.step,
            &cmd_metallib.step,
        });

        sequence(b, &.{
            &cmd_swift.step,
            &install_exe.step,
        });

        const run = b.addRunArtifact(exe);
        run.step.dependOn(b.getInstallStep());
        b.step("run", "Run the app").dependOn(&run.step);
    }
}

fn addCommonImports (b: *std.Build, root_module: *std.Build.Module) void
{
    const app = b.createModule(.{ .root_source_file = b.path("src/engine/application.zig") });
    const native = b.createModule(.{ .root_source_file = b.path("src/engine/native.zig") });
        // native.addImport("app", app);
    const debug = b.createModule(.{ .root_source_file = b.path("src/engine/debug.zig") });
        // debug.addImport("app", app);
    const files = b.createModule(.{ .root_source_file = b.path("src/engine/files.zig") });
        // files.addImport("app", app);
        // files.addImport("debug", debug);

    importModulesToEachOtherAndToRoot(root_module, &.{
        .{ .name = "app", .module = app },
        .{ .name = "native", .module = native },
        .{ .name = "debug", .module = debug },
        .{ .name = "files", .module = files },
    });

    // root_module.addImport("app", app);
    // root_module.addImport("native", native);
    // root_module.addImport("debug", debug);
    // root_module.addImport("files", files);

    // module.addAnonymousImport("utils", "src/utils.zig");
}

fn addLibrariesOSX (b: *std.Build, target: std.Build.ResolvedTarget, exe: *std.Build.Step.Compile) void
{
    //~ xcrun --show-sdk-path
    const sdk = std.zig.system.darwin.getSdk(b.allocator, target.result).?;
    // std.log.debug("{s}", .{ sdk.? });

    // obj-c libraries
    // exe.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/usr/include/", .{sdk}) });
    // exe.addFrameworkPath(.{ .cwd_relative = b.fmt("{s}/System/Library/Frameworks/", .{sdk}) });
    // exe.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/usr/lib/", .{sdk}) });

    // swift libraries
    exe.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/usr/lib/swift/", .{sdk}) });
    // exe.addRPath(.{ .cwd_relative = b.fmt("{s}/usr/lib/swift/", .{sdk}) }); // what the hell is RPath?

    // exe.linkLibC();
    // exe.linkLibCpp();

    exe.linkFramework("Foundation");
    exe.linkFramework("Cocoa");
    exe.linkFramework("Metal");
    exe.linkFramework("QuartzCore");
    // exe.linkFramework("CoreGraphics");

    // force static linking, can be useful in a future
    // exe.addObjectFile(.{ .cwd_relative = b.fmt("{s}/usr/lib/swift_static/macosx/libswiftCore.a", .{sdk}) });
    // or bundle swift runtime when releasing
    // TODO

    // shows system libraries that library use
    //~ nm -u zig-out/lib/cocoa_osx.o | grep swift

    // show all dynamically linked libraries of exe
    //~ otool -L zig-out/bin/fluid

    // shows runtime search paths of exe
    //~ otool -l zig-out/bin/fluid | grep -A2 LC_RPATH

    exe.linkSystemLibrary("swiftCore");
    exe.linkSystemLibrary("swiftFoundation");
    exe.linkSystemLibrary("swift_Concurrency");
    exe.linkSystemLibrary("swiftDispatch");
    exe.linkSystemLibrary("swiftObjectiveC");
    exe.linkSystemLibrary("swiftCoreGraphics");
    exe.linkSystemLibrary("swiftMetal");
    exe.linkSystemLibrary("swiftQuartzCore");
    exe.linkSystemLibrary("swiftIOKit");
    exe.linkSystemLibrary("swiftXPC");
    exe.linkSystemLibrary("swiftos");
    exe.linkSystemLibrary("swiftCoreFoundation");
    exe.linkSystemLibrary("swiftCoreImage");
    exe.linkSystemLibrary("swiftDarwin");
    exe.linkSystemLibrary("swiftUniformTypeIdentifiers");
}

fn importModulesToEachOtherAndToRoot (root_module: *std.Build.Module, modules: []const struct { name: []const u8, module: *std.Build.Module }) void
{
    for (modules) |group|
    {
        for (modules) |tuple|
        {
            if (group.module != tuple.module)
                group.module.addImport(tuple.name, tuple.module);
        }
    }

    for (modules) |tuple|
        root_module.addImport(tuple.name, tuple.module);
}

fn sequence (b: *std.Build, steps: []const *std.Build.Step) void
{
    if (steps.len == 0) return;
    if (steps.len == 1)
    {
        b.default_step.dependOn(steps[0]);
        return;
    }

    for (steps[1..], 0..) |step, i|
    {
        step.dependOn(steps[i]);
    }
    b.default_step.dependOn(steps[steps.len - 1]);
}



// const exe_check = b.addExecutable(.{
//     .name = "fluid",
//     .root_source_file = b.path("src/main.zig"),
// });

// const check = b.step("check", "Check if fluid compiles");
// check.dependOn(&exe_check.step);