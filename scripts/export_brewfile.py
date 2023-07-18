#!/usr/bin/env python3

"""
This script exports a Brewfile with formula/cask descriptions.

Usage: export_brewfile.py > Brewfile
"""

import json
import subprocess


def main() -> None:
    dump = subprocess.run(
        ["brew", "bundle", "dump", "--file=-"],
        check=True,
        text=True,
        capture_output=True,
    )

    for line in dump.stdout.splitlines():
        kind, name = line.split()

        match kind:
            case "brew":
                group = "formulae"
            case "cask":
                group = "casks"
            case _:
                print(line)
                continue

        info = subprocess.run(
            ["brew", "info", "--json=v2", "--" + group, name.strip('"')],
            check=True,
            text=True,
            capture_output=True,
        )

        obj = json.loads(info.stdout)[group][0]
        print(f"{line:<30} # {obj['desc']} ({obj['homepage'].removesuffix('/')})")


if __name__ == "__main__":
    main()
