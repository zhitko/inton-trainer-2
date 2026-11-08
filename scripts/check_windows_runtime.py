#!/usr/bin/env python3
"""Reject missing MinGW runtime entry points before publishing a Windows zip."""

import os
from pathlib import Path
import re
import subprocess
import sys


RUNTIMES = {
    "libstdc++-6.dll", "libgcc_s_seh-1.dll", "libwinpthread-1.dll",
    "libgomp-1.dll", "libssp-0.dll", "libatomic-1.dll",
}


def check_runtime(root, objdump):
    environment = dict(os.environ, LC_ALL="C")

    def inspect(path):
        return subprocess.check_output(
            [objdump, "-p", str(path)], text=True, env=environment,
        )

    exports = {}
    for path in root.iterdir():
        if path.is_file() and path.name.lower() in RUNTIMES:
            exports[path.name.lower()] = set(re.findall(
                r"^\s*\[\s*\d+\]\s+(\S+)\s*$", inspect(path), re.MULTILINE,
            ))
            if not exports[path.name.lower()]:
                raise ValueError(f"Cannot read runtime exports: {path}")

    errors = []
    checked = 0
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in {".exe", ".dll"}:
            continue
        checked += 1
        for block in inspect(path).split("DLL Name: ")[1:]:
            name, _, body = block.partition("\n")
            name = name.strip().lower()
            if name not in RUNTIMES:
                continue
            # Import members end at the first blank line after the table.
            members = body.strip().split("\n\n", 1)[0]
            symbols = set(re.findall(
                r"^\s*[0-9a-fA-F]+\s+\d+\s+(\S+)\s*$",
                members, re.MULTILINE,
            ))
            if name not in exports:
                errors.append(f"{path.relative_to(root)}: missing runtime {name}")
            else:
                for symbol in sorted(symbols - exports[name]):
                    errors.append(f"{path.relative_to(root)} -> {name}: missing {symbol}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print("Use a MinGW compiler matching the Qt kit; DLL presence alone does "
              "not ensure runtime compatibility.", file=sys.stderr)
        return 1
    print(f"MinGW runtime entry points validated ({checked} PE files).")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: check_windows_runtime.py PACKAGE_DIR OBJDUMP")
    try:
        sys.exit(check_runtime(Path(sys.argv[1]), sys.argv[2]))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(f"ERROR: Runtime validation failed: {error}")
