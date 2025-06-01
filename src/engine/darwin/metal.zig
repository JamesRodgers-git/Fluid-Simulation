const std = @import("std");
const app = @import("app");
const math = @import("math");
const debug = @import("debug");

extern fn createLibraryFromData_metal (data_ptr: [*]const u8, data_len: usize) ?*anyopaque;
extern fn createFunction_metal (name: [*:0]const u8, library: ?*anyopaque) ?*anyopaque;
extern fn createPipelineVertFrag_metal (name: [*:0]const u8, vert: ?*anyopaque, frag: ?*anyopaque) ?*anyopaque;

// TODO perfect hashing of every state
// TODO do all the hashing comptime

pub const Material = struct
{
    mtl_pipeline: *anyopaque,
    pipeline: *Pipelines, // only invoked when keywords or blending changes, so no cache misses most of the time

    // uniforms

    // pub fn setVertKeywords (self: Material, const[] const[] u8 keywords) void
    // {
    // }

    // pub fn setFragKeywords (self: Material, const[] const[] u8 keywords) void
    // {
    // }
};

const Metal = struct
{
    // var libraries: [] *anyopaque = undefined;
    // var functions: [] Function = undefined;
    // var pipelines: [] Function = undefined;

    // TODO
    // functions: std.AutoHashMap(usize, []Functions), // k: library_group, v: 
};

pub fn createLibraryGroup (comptime name: []const u8) usize
{
    // TODO is it too much of comptime?
    return comptime math.perfectHash(name);
}

pub fn createLibrary (data: []const u8, library_group: usize) void
{
    _ = library_group;

    const library = createLibraryFromData_metal(data.ptr, data.len);
    const vert = createFunction_metal("vertexShader", library);
    const frag = createFunction_metal("fragmentShader", library);
    _ = createPipelineVertFrag_metal("Simple Pipeline", vert, frag);
}

pub fn createPipeline (vert: FunctionParam, frag: FunctionParam) void
{
    _ = vert;
    _ = frag;
}

// TODO figure out how to have a comptime FunctionParam. It is for commonly used shaders
const FunctionParam = struct
{
    function_name: []const u8,
    library_group: usize = 0,
    // hash comptime computed from name + library_group
};

const Pipelines = struct
{
    // mtl_pipeline: *anyopaque,

    vert: *Functions,
    frag: *Functions,
    // compute: *ComputeFunction,

    // blending, etc...

    // all mtlpipeline combos
    mtl_pipelines: [] *anyopaque,

    // hash computed from unique vert + frag combo
    // and hash computed to identify unique mtl_pipeline from keywords + blending
};

// TODO setKeyword func
// MTLFunction with all its keywords combination
const Functions = struct
{
    // library_group: usize = 0,
    mtl_functions: [] *anyopaque,

    // hash from FunctionParam
};