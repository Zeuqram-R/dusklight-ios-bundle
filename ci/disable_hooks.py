#!/usr/bin/env python3
"""Disable specific by-name hook records in a mod's iOS library (Mach-O arm64).

Dusklight mods describe their hooks as records in the __DATA,__modmeta section. On iOS every
hook is applied at build time (prepatch), and a single hook that cannot be applied aborts the
whole app build. On macOS/PC the same hook simply fails at runtime and the mod carries on.

This script turns the listed MOD_META_HOOK_NAME records into an unknown record kind. Both the
prepatch tool and the runtime loader skip unknown kinds, so on iOS those hooks end up exactly
as on desktop when they fail to resolve: the slot stays null and installing that hook fails.

Usage: disable_hooks.py <mod.so> <names.txt>
"""
import struct
import sys

MOD_META_HOOK_NAME = 6
DISABLED_KIND = 0xEE  # not a ModMetaKind; parsers must skip unknown kinds
HOOK_NAME_HEADER = 16  # sizeof(ModMetaHookName)

LC_SEGMENT_64 = 0x19
MH_MAGIC_64 = 0xFEEDFACF


def find_modmeta(data: bytes):
    magic, _cpu, _sub, _ftype, ncmds, _size, _flags, _res = struct.unpack_from("<IiiIIIII", data, 0)
    if magic != MH_MAGIC_64:
        sys.exit("not a 64-bit little-endian Mach-O file")
    off = 32
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", data, off)
        if cmd == LC_SEGMENT_64:
            nsects = struct.unpack_from("<I", data, off + 64)[0]
            sect = off + 72
            for _ in range(nsects):
                sectname = data[sect:sect + 16].rstrip(b"\0").decode()
                segname = data[sect + 16:sect + 32].rstrip(b"\0").decode()
                _addr, size, fileoff = struct.unpack_from("<QQI", data, sect + 32)
                if segname == "__DATA" and sectname == "__modmeta":
                    return fileoff, size
                sect += 80
        off += cmdsize
    sys.exit("__DATA,__modmeta section not found")


def main():
    lib_path, names_path = sys.argv[1], sys.argv[2]
    wanted = set()
    for line in open(names_path, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#"):
            wanted.add(line)

    data = bytearray(open(lib_path, "rb").read())
    start, size = find_modmeta(data)
    cursor, end = start, start + size
    disabled, seen = 0, set()
    while cursor + 8 <= end:
        if data[cursor:cursor + 8] == b"\0" * 8:  # linker padding
            cursor += 8
            continue
        rec_size, kind = struct.unpack_from("<HB", data, cursor)
        if rec_size < 8 or rec_size % 8 or cursor + rec_size > end:
            sys.exit(f"malformed record at file offset {cursor:#x}")
        if kind == MOD_META_HOOK_NAME:
            raw = data[cursor + HOOK_NAME_HEADER:cursor + rec_size]
            name = raw.split(b"\0", 1)[0].decode("utf-8", "replace")
            if name in wanted:
                data[cursor + 2] = DISABLED_KIND
                disabled += 1
                seen.add(name)
        cursor += rec_size

    missing = wanted - seen
    for name in sorted(missing):
        print(f"::warning::{lib_path}: hook '{name}' not found (already fixed upstream?)")
    open(lib_path, "wb").write(data)
    print(f"{lib_path}: disabled {disabled} hook record(s) ({len(seen)} distinct names)")


if __name__ == "__main__":
    main()
