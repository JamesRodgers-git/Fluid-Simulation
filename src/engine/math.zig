

pub fn perfectHash (comptime str: []const u8) u32
{
    // FNV-1a hash - good distribution for small sets
    var hash: u32 = 2166136261;
    for (str) |byte|
    {
        hash ^= byte;
        hash *%= 16777619;
    }
    return hash;
}