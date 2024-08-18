---
{
    .title = "Огляд Мови, частина 1",
    .date = "2024-08-17T00:00:00",
    .author = "Sonic",
    .draft = false,
    .layout = "learning_zig.shtml",
    .tags = [],
}  
--- 
Zig is a strongly typed compiled language. It supports generics, has powerful compile-time metaprogramming capabilities and __does not__ include a garbage collector. Many people consider Zig a modern alternative to C. As such, the language's syntax is C-like. We're talking semicolon terminated statements and curly brace delimited blocks

Here's what Zig code looks like:

<figure>
<figcaption class="zig-cap">learning.zig</figcaption>

```zig
const std = @import("std");

// This code won't compile if `main` isn't `pub` (public)
pub fn main() void {
  const user = User{
    .power = 9001,
    .name = "Goku",
  };

  std.debug.print("{s}'s power is {d}\n", .{user.name, user.power});
}

pub const User = struct {
  power: u64,
  name: []const u8,
};
```
</figure>