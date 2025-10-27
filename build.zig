const std = @import("std");

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("libxml2", .{});
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // get version from zon file
    const versionString = @import("./build.zig.zon").version;
    const version = std.SemanticVersion.parse(versionString) catch @panic("OOM");
    const versionNumber = version.major * 1_00_00 + version.minor * 1_00 + version.patch;

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link mode") orelse .static;
    const strip = b.option(bool, "strip", "Omit debug information");
    const pic = b.option(bool, "pie", "Produce Position Independent Code");

    // Most of these config options have not been tested.

    const minimum = b.option(bool, "minimum", "build a minimally sized library (default=false)") orelse false;
    const legacy = b.option(bool, "legacy", "maximum ABI compatibility (default=false)") orelse false;

    const http = b.option(bool, "http", "HTTP support (default=false)") orelse false;
    const icu = b.option(bool, "icu", "ICU support (default=false)") orelse false;
    const lzma = b.option(bool, "lzma", "use liblzma in DIR (default=false)") orelse false;
    // const python = b.option(bool, "python", "Python bindings (default=false)") orelse false;
    const thread_alloc = b.option(bool, "thread-alloc", "per-thread malloc hooks (default=false)") orelse false;
    const tls = b.option(bool, "tls", "thread-local storage (default=false)") orelse false;

    const catalog = b.option(bool, "catalog", "XML Catalogs support (default=true)") orelse !minimum;
    const debug = b.option(bool, "debug", "debugging module (default=true)") orelse !minimum;
    const html = b.option(bool, "html", "HTML parser (default=true)") orelse !minimum;
    const iconv = b.option(bool, "iconv", "iconv support (default=true)") orelse !minimum;
    const iso8859x = b.option(bool, "iso8859x", "ISO-8859-X support if no iconv (default=true)") orelse !minimum;
    // const modules = b.option(bool, "modules", "dynamic modules support (default=true)") orelse !minimum;
    const sax1 = b.option(bool, "sax1", "older SAX1 interface (default=true)") orelse !minimum;
    const threads = b.option(bool, "threads", "multithreading support (default=true)") orelse !minimum;
    const valid = b.option(bool, "valid", "DTD validation support (default=true)") orelse !minimum;
    const xinclude = b.option(bool, "xinclude", "XInclude 1.0 support (default=true)") orelse !minimum;

    const zlib = b.option(bool, "zlib", "use libz in DIR") orelse legacy;

    const want_c14n = b.option(bool, "c14n", "Canonical XML 1.0 support (default=true)");
    const want_history = b.option(bool, "history", "history support for xmllint shell (default=false)");
    const want_readline = b.option(bool, "readline", "readline support for xmllint shell (default=false)");
    const want_output = b.option(bool, "output", "serialization support (default=true)");
    const want_pattern = b.option(bool, "pattern", "xmlPattern selection interface (default=true)");
    const want_push = b.option(bool, "push", "push parser interfaces (default=true)");
    const want_reader = b.option(bool, "reader", "xmlReader parsing interface (default=true)");
    const want_regexps = b.option(bool, "regexps", "regular expressions support (default=true)");
    const want_relaxng = b.option(bool, "relaxng", "RELAX NG support (default=true)");
    const want_schemas = b.option(bool, "schemas", "XML Schemas 1.0 and RELAX NG support (default=true)");
    const want_schematron = b.option(bool, "schematron", "Schematron support (default=true)");
    const want_writer = b.option(bool, "writer", "xmlWriter serialization interface (default=true)");
    const want_xpath = b.option(bool, "xpath", "XPath 1.0 support (default=true)");
    const want_xptr = b.option(bool, "xptr", "XPointer support (default=true)");

    const output = want_output orelse (!minimum or want_c14n == true or want_writer == true);
    const pattern = want_pattern orelse (!minimum or want_schemas == true or want_schematron == true);
    const regexps = want_regexps orelse (!minimum or want_relaxng == true or want_schemas == true);
    const push = want_push orelse (!minimum or want_reader == true or want_writer == true);
    const readline = want_readline orelse (want_history == true);
    const xpath = want_xpath orelse (!minimum or want_c14n == true or want_schematron == true or want_xptr == true);

    const c14n = want_c14n orelse (!minimum and output and xpath);
    const history = want_history orelse false;
    const reader = want_reader orelse (!minimum and push);
    const schemas = want_schemas orelse (!minimum and pattern and regexps);
    const relaxng = want_relaxng orelse (!minimum and schemas);
    const schematron = want_schematron orelse (!minimum and pattern and xpath);
    const writer = want_writer orelse (!minimum and output and push);
    const xptr = want_xptr orelse (!minimum and xpath);

    if (c14n and !output) std.debug.panic("c14n requires output", .{});
    if (c14n and !xpath) std.debug.panic("c14n requires xpath", .{});
    if (history and !readline) std.debug.panic("history requires readline", .{});
    if (reader and !push) std.debug.panic("reader requires push", .{});
    if (schemas and !pattern) std.debug.panic("schemas requires pattern", .{});
    if (schemas and !regexps) std.debug.panic("schemas requires regexps", .{});
    if (relaxng and !schemas) std.debug.panic("relaxng requires schemas", .{});
    if (schematron and !pattern) std.debug.panic("schematron requires pattern", .{});
    if (schematron and !xpath) std.debug.panic("schematron requires xpath", .{});
    if (writer and !output) std.debug.panic("writer requires output", .{});
    if (writer and !push) std.debug.panic("writer requires push", .{});
    if (xptr and !xpath) std.debug.panic("xptr requires xpath", .{});

    const xml_version_header = b.addConfigHeader(.{
        .include_path = "libxml/xmlversion.h",
        .style = .{ .cmake = upstream.path("include/libxml/xmlversion.h.in") },
    }, .{
        .VERSION = b.fmt("{f}", .{std.SemanticVersion{ .major = version.major, .minor = version.minor, .patch = version.patch }}),
        .LIBXML_VERSION_NUMBER = @as(i64, @intCast(versionNumber)),
        .LIBXML_VERSION_EXTRA = "",
        .WITH_THREADS = threads,
        .WITH_THREAD_ALLOC = thread_alloc,
        .WITH_OUTPUT = output,
        .WITH_PUSH = push,
        .WITH_READER = reader,
        .WITH_PATTERN = pattern,
        .WITH_WRITER = writer,
        .WITH_SAX1 = sax1,
        .WITH_HTTP = http,
        .WITH_VALID = valid,
        .WITH_HTML = html,
        .WITH_LEGACY = legacy,
        .WITH_C14N = c14n,
        .WITH_CATALOG = catalog,
        .WITH_XPATH = xpath,
        .WITH_XPTR = xptr,
        .WITH_XINCLUDE = xinclude,
        .WITH_ICONV = iconv,
        .WITH_ICU = icu,
        .WITH_ISO8859X = iso8859x,
        .WITH_DEBUG = debug,
        .WITH_REGEXPS = regexps,
        .WITH_RELAXNG = relaxng,
        .WITH_SCHEMAS = schemas,
        .WITH_SCHEMATRON = schematron,
        .WITH_MODULES = false,
        .MODULE_EXTENSION = null,
        .WITH_ZLIB = zlib,
        .WITH_LZMA = lzma,
    });

    const config_header = b.addConfigHeader(.{
        .include_path = "config.h",
        .style = .{ .cmake = upstream.path("config.h.cmake.in") },
    }, .{
        .HAVE_DECL_GETENTROPY = switch (target.result.os.tag) {
            .linux => target.result.isGnuLibC() and target.result.os.version_range.linux.glibc.order(.{ .major = 2, .minor = 25, .patch = 0 }) != .lt,
            .freebsd, .openbsd => true,
            else => target.result.os.tag.isDarwin(),
        },
        .HAVE_DECL_GLOB = target.result.os.tag != .windows,
        .HAVE_DECL_MMAP = target.result.os.tag != .windows and target.result.os.tag != .wasi,
        .HAVE_DLOPEN = false, // only present if `WITH_MODULES`
        .HAVE_FUNC_ATTRIBUTE_DESTRUCTOR = true,
        .HAVE_LIBHISTORY = history,
        .HAVE_LIBREADLINE = readline,
        .HAVE_POLL_H = http and target.result.os.tag != .windows,
        .HAVE_SHLLOAD = false, // only present if `WITH_MODULES`
        .HAVE_STDINT_H = true,
        .XML_SYSCONFDIR = "/", // TODO
        .XML_THREAD_LOCAL = @as(?enum { _Thread_local }, if (tls) ._Thread_local else null),
    });

    const xml_lib = b.addLibrary(.{
        .linkage = linkage,
        .name = "xml",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .strip = strip,
            .pic = pic,
        }),
    });
    b.installArtifact((xml_lib));
    xml_lib.installHeader(xml_version_header.getOutput(), "libxml/xmlversion.h");
    xml_lib.installHeadersDirectory(upstream.path("include/libxml"), "libxml", .{});
    xml_lib.root_module.addConfigHeader(config_header);
    xml_lib.root_module.addConfigHeader(xml_version_header);
    xml_lib.root_module.addIncludePath(upstream.path("include"));
    xml_lib.root_module.addCSourceFiles(.{ .files = xml_src, .root = upstream.path(""), .flags = xml_flags });
    if (target.result.os.tag == .windows and linkage == .static) xml_lib.root_module.addCMacro("LIBXML_STATIC", "1");
    if (c14n) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("c14n.c"), .flags = xml_flags });
    if (catalog) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("catalog.c"), .flags = xml_flags });
    if (debug) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("debugXML.c"), .flags = xml_flags });
    if (html) xml_lib.root_module.addCSourceFiles(.{ .files = &.{ "HTMLparser.c", "HTMLtree.c" }, .root = upstream.path(""), .flags = xml_flags });
    if (http) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("nanohttp.c"), .flags = xml_flags });
    if (lzma) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("xzlib.c"), .flags = xml_flags });
    // if (modules) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("xmlmodule.c"), .flags = xml_flags });
    if (output) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("xmlsave.c"), .flags = xml_flags });
    if (pattern) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("pattern.c"), .flags = xml_flags });
    if (reader) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("xmlreader.c"), .flags = xml_flags });
    if (regexps) xml_lib.root_module.addCSourceFiles(.{ .files = &.{ "xmlregexp.c", "xmlunicode.c" }, .root = upstream.path(""), .flags = xml_flags });
    if (relaxng) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("relaxng.c"), .flags = xml_flags });
    if (schemas) xml_lib.root_module.addCSourceFiles(.{ .files = &.{ "xmlschemas.c", "xmlschemastypes.c" }, .root = upstream.path(""), .flags = xml_flags });
    if (schematron) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("schematron.c"), .flags = xml_flags });
    if (writer) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("xmlwriter.c"), .flags = xml_flags });
    if (xinclude) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("xinclude.c"), .flags = xml_flags });
    if (xpath) xml_lib.root_module.addCSourceFile(.{ .file = upstream.path("xpath.c"), .flags = xml_flags });
    if (xptr) xml_lib.root_module.addCSourceFiles(.{ .files = &.{ "xlink.c", "xpointer.c" }, .root = upstream.path(""), .flags = xml_flags });
    if (lzma) xml_lib.root_module.linkSystemLibrary("lzma", .{});
    if (icu) xml_lib.root_module.linkSystemLibrary("icu-i18n", .{});
    if (target.result.os.tag == .windows) xml_lib.root_module.linkSystemLibrary("bcrypt", .{});
    if (http and target.result.os.tag == .windows) xml_lib.root_module.linkSystemLibrary("ws2_32", .{});

    if (iconv) {
        if (b.systemIntegrationOption("iconv", .{})) {
            xml_lib.root_module.linkSystemLibrary("iconv", .{});
        } else {
            const IconvImpl = enum { libc, libiconv, win_iconv };
            const impl: IconvImpl = b.option(
                IconvImpl,
                "iconv-impl",
                "Set the iconv implementation (default=libc except for win_iconv on windows)",
            ) orelse switch (target.result.os.tag) {
                .windows => .win_iconv,
                else => .libc,
            };
            switch (impl) {
                .libc => {},
                .libiconv => {
                    if (b.lazyDependency("libiconv", .{
                        .target = target,
                        .optimize = optimize,
                    })) |libiconv_dependency| {
                        xml_lib.root_module.linkLibrary(libiconv_dependency.artifact("iconv"));
                    }
                },
                .win_iconv => {
                    if (b.lazyDependency("win_iconv", .{
                        .target = target,
                        .optimize = optimize,
                    })) |win_iconv_dependency| {
                        xml_lib.root_module.linkLibrary(win_iconv_dependency.artifact("iconv"));
                    }
                },
            }
        }
    }

    if (zlib) {
        if (b.systemIntegrationOption("zlib", .{})) {
            xml_lib.root_module.linkSystemLibrary("zlib", .{});
        } else if (b.lazyDependency("zlib", .{
            .target = target,
            .optimize = optimize,
        })) |zlib_dependency| {
            xml_lib.root_module.linkLibrary(zlib_dependency.artifact("z"));
        }
    }

    const xmllint = b.addExecutable(.{
        .name = "xmllint",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .strip = strip,
            .pic = pic,
        }),
    });
    b.installArtifact(xmllint);
    xmllint.root_module.addCSourceFiles(.{
        .files = xmllint_src,
        .root = upstream.path("."),
        .flags = xml_flags,
    });
    xmllint.root_module.linkLibrary(xml_lib);
    xmllint.root_module.addConfigHeader(config_header);
    xmllint.root_module.addIncludePath(upstream.path("include"));
    if (target.result.os.tag == .windows and linkage == .static) xmllint.root_module.addCMacro("LIBXML_STATIC", "1");
    if (readline) xmllint.root_module.linkSystemLibrary("readline", .{});
    if (history) xmllint.root_module.linkSystemLibrary("history", .{});

    if (catalog and output) {
        const xmlcatalog = b.addExecutable(.{
            .name = "xmlcatalog",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .strip = strip,
                .pic = pic,
            }),
        });
        b.installArtifact(xmlcatalog);
        xmlcatalog.root_module.addCSourceFile(.{
            .file = upstream.path("xmlcatalog.c"),
            .flags = xml_flags,
        });
        xmlcatalog.root_module.linkLibrary(xml_lib);
        xmlcatalog.root_module.addConfigHeader(config_header);
        if (target.result.os.tag == .windows and linkage == .static) xmlcatalog.root_module.addCMacro("LIBXML_STATIC", "1");
        if (readline) xmlcatalog.root_module.linkSystemLibrary("readline", .{});
        if (history) xmlcatalog.root_module.linkSystemLibrary("history", .{});
    }
}

const xml_src: []const []const u8 = &.{
    "buf.c",
    "chvalid.c",
    "dict.c",
    "entities.c",
    "encoding.c",
    "error.c",
    "globals.c",
    "hash.c",
    "list.c",
    "parser.c",
    "parserInternals.c",
    "SAX2.c",
    "threads.c",
    "tree.c",
    "uri.c",
    "valid.c",
    "xmlIO.c",
    "xmlmemory.c",
    "xmlstring.c",
};

const xmllint_src: []const []const u8 = &.{
    "xmllint.c",
    "shell.c",
    "lintmain.c",
};

const xml_flags: []const []const u8 = &.{
    "-pedantic",
    "-Wall",
    "-Wextra",
    "-Wshadow",
    "-Wpointer-arith",
    "-Wcast-align",
    "-Wwrite-strings",
    "-Wstrict-prototypes",
    "-Wmissing-prototypes",

    "-Wno-long-long",
    "-Wno-format-extra-args",
    "-Wno-array-bounds",
};
