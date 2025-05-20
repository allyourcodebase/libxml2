[![CI](https://github.com/allyourcodebase/libxml2/actions/workflows/ci.yaml/badge.svg)](https://github.com/allyourcodebase/libxml2/actions)

# libxml2

This is [libxml2](https://gitlab.gnome.org/GNOME/libxml2), packaged for [Zig](https://ziglang.org/).

## Installation

First, update your `build.zig.zon`:

```
# Initialize a `zig build` project if you haven't already
zig init
zig fetch --save git+https://github.com/allyourcodebase/libxml2.git#2.14.3
```

You can then import `libxml2` in your `build.zig` with:

```zig
const libxml2_dependency = b.dependency("libxml2", .{
    .target = target,
    .optimize = optimize,
});
your_exe.linkLibrary(libxml2_dependency.artifact("libxml2"));
```
