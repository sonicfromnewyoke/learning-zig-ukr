const std = @import("std");
const zine = @import("zine");

pub fn build(b: *std.Build) !void {
    zine.website(b, .{
        .title = "Learn Zig UKR",
        .host_url = "https://sample.com",
        .content_dir_path = "content",
        .layouts_dir_path = "layouts",
        .assets_dir_path = "assets",
    });
}
