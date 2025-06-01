const graphics = @import("graphics");

pub const common_group: usize = graphics.createLibraryGroup("common");
pub const fluid_group: usize = graphics.createLibraryGroup("fluid");

pub const Common = struct
{
    // downsample: graphics.Material = ();
    // upsample: graphics.Material = ();
};

pub const Bloom = struct
{
    // prefilter: graphics.Material = ();
};

pub fn init () void
{
}

// pub fn create_material (library_group: usize, []const u8 ) void
// {

// }