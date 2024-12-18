const std = @import("std");

const version: std.SemanticVersion = .{ .major = 2, .minor = 13, .patch = 5 };

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("libxml2", .{});
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Most of these config options have not been tested.

    const minimum = b.option(bool, "minimum", "build a minimally sized library (default=false)") orelse false;
    const legacy = b.option(bool, "legacy", "maximum ABI compatibility (default=false)") orelse false;
    const tls = b.option(bool, "tls", "thread-local storage (default=false)") orelse false;

    var c14n = b.option(bool, "c14n", "Canonical XML 1.0 support (default=true)") orelse !minimum;
    const catalog = b.option(bool, "catalog", "XML Catalogs support (default=true)") orelse !minimum;
    const debug = b.option(bool, "debug", "debugging module (default=true)") orelse !minimum;
    const ftp = b.option(bool, "ftp", "FTP support (default=false)") orelse false;
    const history = b.option(bool, "history", "history support for xmllint shell (default=false)") orelse false;
    var readline = b.option(bool, "readline", "use readline in DIR for shell (default=off)") orelse !minimum and history;
    const html = b.option(bool, "html", "HTML parser (default=true)") orelse !minimum;
    const http = b.option(bool, "http", "HTTP support (default=false)") orelse legacy;
    const iconv = b.option(bool, "iconv", "iconv support (default=on)") orelse !minimum;
    const icu = b.option(bool, "icu", "ICU support (default=false)") orelse false;
    const iso8859x = b.option(bool, "iso8859x", "ISO-8859-X support if no iconv (default=true)") orelse !minimum;
    const lzma = b.option(bool, "lzma", "use liblzma in DIR (default=off)") orelse legacy;
    // const modules = b.option(bool, "modules", "dynamic modules support (default=true)") orelse !minimum;
    var output = b.option(bool, "output", "serialization support (default=true)") orelse !minimum;
    var pattern = b.option(bool, "pattern", "xmlPattern selection interface (default=true)") orelse !minimum;
    var push = b.option(bool, "push", "push parser interfaces (default=true)") orelse !minimum;
    // const python = b.option(bool, "python", "Python bindings (default=true)") orelse !minimum;
    var reader = b.option(bool, "reader", "xmlReader parsing interface (default=true)") orelse !minimum;
    var regexps = b.option(bool, "regexps", "regular expressions support (default=true)") orelse !minimum;
    const sax1 = b.option(bool, "sax1", "older SAX1 interface (default=true)") orelse !minimum;
    var schemas = b.option(bool, "schemas", "XML Schemas 1.0 and RELAX NG support (default=true)") orelse !minimum;
    var schematron = b.option(bool, "schematron", "Schematron support (default=true)") orelse !minimum;
    const threads = b.option(bool, "threads", "multithreading support (default=true)") orelse !minimum;
    const thread_alloc = b.option(bool, "thread-alloc", "per-thread malloc hooks (default=false)") orelse false;
    const valid = b.option(bool, "valid", "DTD validation support (default=true)") orelse !minimum;
    var writer = b.option(bool, "writer", "xmlWriter serialization interface (default=true)") orelse !minimum;
    var xinclude = b.option(bool, "xinclude", "XInclude 1.0 support (default=true)") orelse !minimum;
    var xpath = b.option(bool, "xpath", "XPath 1.0 support (default=true)") orelse !minimum;
    var xptr = b.option(bool, "xptr", "XPointer support (default=true)") orelse !minimum;
    const xptr_locs = b.option(bool, "xptr-locs", "XPointer ranges and points (default=false)") orelse false;
    const zlib = b.option(bool, "zlib", "use libz in DIR") orelse legacy;

    if (c14n) {
        if (!output) {
            std.log.warn("-Dc14n overrides -Doutput=false", .{});
            output = true;
        }
        if (!xpath) {
            std.log.warn("-Dc14n overrides -Dxpath=false", .{});
            xpath = true;
        }
    }
    if (schemas) {
        if (!pattern) {
            std.log.warn("-Dschemas overrides -Dpattern=false", .{});
            pattern = true;
        }
        if (!regexps) {
            std.log.warn("-Dschemas overrides -Dregexps=false", .{});
            regexps = true;
        }
    }
    if (schematron) {
        if (!pattern) {
            std.log.warn("-Dschematron overrides -Dpattern=false", .{});
            pattern = true;
        }
        if (!xpath) {
            std.log.warn("-Dschematron overrides -Dxpath=false", .{});
            xpath = true;
        }
    }
    if (reader) {
        if (!push) {
            std.log.warn("-Dreader overrides -Dpush=false", .{});
            push = true;
        }
    }
    if (writer) {
        if (!output) {
            std.log.warn("-Dwriter overrides -Doutput=false", .{});
            output = true;
        }
        if (!push) {
            std.log.warn("-Dwriter overrides -Dpush=false", .{});
            push = true;
        }
    }
    if (xinclude) {
        if (!xpath) {
            std.log.warn("-Dxinclude overrides -Dxpath=false", .{});
            xpath = true;
        }
    }
    if (xptr_locs) {
        if (!xpath) {
            std.log.warn("-Dxptr-locs overrides -Dxptr=false", .{});
            xpath = true;
        }
    }
    if (xptr) {
        if (!xpath) {
            std.log.warn("-Dxptr overrides -Dxpath=false", .{});
            xpath = true;
        }
    }
    if (history) {
        if (!readline) {
            std.log.warn("-Dhistory overrides -Dreadline=false", .{});
            readline = true;
        }
    }

    if (!minimum) {
        if (!output) {
            c14n = false;
            writer = false;
        }
        if (!pattern) {
            schemas = false;
            schematron = false;
        }
        if (!push) {
            reader = false;
            writer = false;
        }
        if (!regexps) {
            schemas = false;
        }
        if (!xpath) {
            c14n = false;
            schematron = false;
            xinclude = false;
            xptr = false;
        }
    }

    const xml_version_header = b.addConfigHeader(.{
        .include_path = "libxml/xmlversion.h",
        .style = .{ .cmake = upstream.path("include/libxml/xmlversion.h.in") },
    }, .{
        .VERSION = b.fmt("{}", .{version}),
        .LIBXML_VERSION_NUMBER = @as(i64, version.major * 10000 + version.major * 100 + version.patch),
        .LIBXML_VERSION_EXTRA = "",
        .WITH_THREADS = threads,
        .WITH_THREAD_ALLOC = threads and thread_alloc,
        .WITH_TREE = true,
        .WITH_OUTPUT = output,
        .WITH_PUSH = push,
        .WITH_READER = reader,
        .WITH_PATTERN = pattern,
        .WITH_WRITER = writer,
        .WITH_SAX1 = sax1,
        .WITH_FTP = ftp,
        .WITH_HTTP = http,
        .WITH_VALID = valid,
        .WITH_HTML = html,
        .WITH_LEGACY = legacy,
        .WITH_C14N = c14n,
        .WITH_CATALOG = catalog,
        .WITH_XPATH = xpath,
        .WITH_XPTR = xptr,
        .WITH_XPTR_LOCS = xptr_locs,
        .WITH_XINCLUDE = xinclude,
        .WITH_ICONV = iconv,
        .WITH_ICU = icu,
        .WITH_ISO8859X = iso8859x,
        .WITH_DEBUG = debug,
        .WITH_REGEXPS = regexps,
        .WITH_SCHEMAS = schemas,
        .WITH_SCHEMATRON = schematron,
        .WITH_MODULES = false,
        .MODULE_EXTENSION = null,
        .WITH_ZLIB = zlib,
        .WITH_LZMA = lzma,
    });

    const config_header = b.addConfigHeader(.{}, .{
        .HAVE_STDINT_H = true,
        .HAVE_FCNTL_H = true,
        .HAVE_UNISTD_H = true,
        .HAVE_SYS_STAT_H = true,
        .HAVE_SYS_MMAN_H = true,
        .HAVE_SYS_TIME_H = true,
        .HAVE_SYS_TIMEB_H = true,
        .HAVE_SYS_RANDOM_H = true,
        .HAVE_DL_H = true,
        .HAVE_DLFCN_H = true,
        .HAVE_GLOB_H = true,
        .HAVE_DECL_GETENTROPY = true,
        .HAVE_DECL_GLOB = true,
        .HAVE_DECL_MMAP = true,
        .HAVE_POLL_H = true,
        .HAVE_ATTRIBUTE_DESTRUCTOR = true,
        .ATTRIBUTE_DESTRUCTOR = .@"__attribute__((destructor))",
    });
    if (tls) {
        config_header.addValues(.{ .XML_THREAD_LOCAL = ._Thread_local });
    }

    const xml_lib = b.addStaticLibrary(.{
        .name = "xml",
        .target = target,
        .optimize = optimize,
        .version = version,
        .link_libc = true,
    });
    b.installArtifact((xml_lib));
    xml_lib.addConfigHeader(config_header);
    xml_lib.addConfigHeader(xml_version_header);
    xml_lib.installHeader(xml_version_header.getOutput(), "libxml/xmlversion.h");
    xml_lib.addIncludePath(upstream.path("include"));
    xml_lib.addCSourceFiles(.{ .files = xml_src, .root = upstream.path(""), .flags = xml_flags });
    xml_lib.installHeadersDirectory(upstream.path("include/libxml"), "libxml", .{});
    if (target.result.os.tag != .windows) xml_lib.root_module.addCMacro("HAVE_PTHREAD_H", "1");
    if (target.result.os.tag == .windows) xml_lib.root_module.addCMacro("LIBXML_STATIC", "1");
    if (c14n) xml_lib.addCSourceFile(.{ .file = upstream.path("c14n.c"), .flags = xml_flags });
    if (catalog) xml_lib.addCSourceFile(.{ .file = upstream.path("catalog.c"), .flags = xml_flags });
    if (debug) xml_lib.addCSourceFile(.{ .file = upstream.path("debugXML.c"), .flags = xml_flags });
    if (ftp) xml_lib.addCSourceFile(.{ .file = upstream.path("nanoftp.c"), .flags = xml_flags });
    if (html) xml_lib.addCSourceFiles(.{ .files = &.{ "HTMLparser.c", "HTMLtree.c" }, .root = upstream.path(""), .flags = xml_flags });
    if (http) xml_lib.addCSourceFile(.{ .file = upstream.path("nanohttp.c"), .flags = xml_flags });
    if (legacy) xml_lib.addCSourceFile(.{ .file = upstream.path("legacy.c"), .flags = xml_flags });
    if (lzma) xml_lib.addCSourceFile(.{ .file = upstream.path("xzlib.c"), .flags = xml_flags });
    // if (modules) xml_lib.addCSourceFile(.{ .file = upstream.path("xmlmodule.c"), .flags = xml_flags });
    if (output) xml_lib.addCSourceFile(.{ .file = upstream.path("xmlsave.c"), .flags = xml_flags });
    if (pattern) xml_lib.addCSourceFile(.{ .file = upstream.path("pattern.c"), .flags = xml_flags });
    if (reader) xml_lib.addCSourceFile(.{ .file = upstream.path("xmlreader.c"), .flags = xml_flags });
    if (regexps) xml_lib.addCSourceFiles(.{ .files = &.{ "xmlregexp.c", "xmlunicode.c" }, .root = upstream.path(""), .flags = xml_flags });
    if (schemas) xml_lib.addCSourceFiles(.{ .files = &.{ "relaxng.c", "xmlschemas.c", "xmlschemastypes.c" }, .root = upstream.path(""), .flags = xml_flags });
    if (schematron) xml_lib.addCSourceFile(.{ .file = upstream.path("schematron.c"), .flags = xml_flags });
    if (writer) xml_lib.addCSourceFile(.{ .file = upstream.path("xmlwriter.c"), .flags = xml_flags });
    if (xinclude) xml_lib.addCSourceFile(.{ .file = upstream.path("xinclude.c"), .flags = xml_flags });
    if (xpath) xml_lib.addCSourceFile(.{ .file = upstream.path("xpath.c"), .flags = xml_flags });
    if (xptr) xml_lib.addCSourceFiles(.{ .files = &.{ "xlink.c", "xpointer.c" }, .root = upstream.path(""), .flags = xml_flags });
    if (readline) {
        xml_lib.linkSystemLibrary("readline");
        xml_lib.root_module.addCMacro("HAVE_LIBREADLINE", "1");
    }
    if (history) {
        xml_lib.linkSystemLibrary("history");
        xml_lib.root_module.addCMacro("HAVE_LIBHISTORY", "1");
    }
    if (zlib) xml_lib.linkSystemLibrary("zlib");
    if (lzma) xml_lib.linkSystemLibrary("lzma");
    if (icu) xml_lib.linkSystemLibrary("icu-i18n");
    if (iconv) xml_lib.linkSystemLibrary("iconv");
    if (target.result.os.tag == .windows) xml_lib.linkSystemLibrary("bcrypt");
    if (http and target.result.os.tag == .windows) xml_lib.linkSystemLibrary("ws2_32");
}

pub const xml_src: []const []const u8 = &.{
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

pub const xml_flags: []const []const u8 = &.{
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
