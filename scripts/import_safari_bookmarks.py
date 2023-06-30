#!/usr/bin/env python3

"""
Import bookmarks to Safari from a Netscape Bookmark file.
Currently, does not support folders.
"""

import plistlib
import re
import sys
import uuid
from pathlib import Path

USER_BOOKMARKS_INDEX = 3
SAFARI_BOOKMARKS_LOCATION = "Library/Safari/Bookmarks.plist"


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: import_safari_bookmarks.py <path/to/bookmarks.html>")
        sys.exit(1)

    input_file = sys.argv[1]
    text = Path(input_file).read_text()

    bookmarks: list[object] = []
    for match in re.finditer(r'<DT><A HREF="(.*?)".*>(.*)</A>', text):
        bookmarks.append(
            {
                "ReadingListNonSync": {"neverFetchMetadata": 0},
                "URIDictionary": {"title": match.group(2)},
                "URLString": match.group(1),
                "WebBookmarkType": "WebBookmarkTypeLeaf",
                "WebBookmarkUUID": random_uuid(),
            }
        )

    if len(bookmarks) == 0:
        print(f"no bookmarks found in {input_file}")
        sys.exit(0)

    output_file = Path.home().joinpath(SAFARI_BOOKMARKS_LOCATION)
    with open(output_file, mode="r+b") as f:
        data = plistlib.load(f, fmt=plistlib.FMT_BINARY)
        f.seek(0)

        data["WebBookmarkUUID"] = random_uuid()
        data["Children"][USER_BOOKMARKS_INDEX:] = bookmarks

        plistlib.dump(data, f, fmt=plistlib.FMT_BINARY, sort_keys=False)
        f.truncate()


def random_uuid() -> str:
    return str(uuid.uuid4()).upper()


if __name__ == "__main__":
    main()
