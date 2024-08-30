const std = @import("std");
const zine = @import("zine");

pub fn build(b: *std.Build) !void {
    zine.website(b, .{
        .title = "Learning Zig UKR",
        .host_url = "https://sonicfromnewyoke.github.io/",
        .url_path_prefix = "learning-zig-ukr",
        .content_dir_path = "content",
        .layouts_dir_path = "layouts",
        .assets_dir_path = "assets",
        .debug = true,
    });
}
