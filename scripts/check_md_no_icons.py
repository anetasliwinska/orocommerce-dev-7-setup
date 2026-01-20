#!/usr/bin/env python3
"""
Prosty checker, który wykrywa emoji/„ikonki” w plikach Markdown.
Cel: dokumenty importowane do Confluence bez symboli typu ✅ ❌ ⚠️ itp.

Użycie:
  python3 scripts/check_md_no_icons.py
  python3 scripts/check_md_no_icons.py --path /home/anetk/orocommerce-dev

Domyślnie ignoruje katalog: orocommerce-application/
"""

from __future__ import annotations

import argparse
import os
import sys


IGNORED_DIRS = {
    "orocommerce-application",
    ".git",
    "node_modules",
    "vendor",
}


def is_emoji_or_icon(ch: str) -> bool:
    """
    Heurystyka: blokujemy większość symboli/emoji, ale nie blokujemy liter (w tym PL)
    i nie blokujemy podstawowych znaków interpunkcyjnych.

    Zakresy obejmują m.in. Dingbats, Misc Symbols, Supplemental Symbols, Emoji.
    """
    cp = ord(ch)

    # Dingbats + Misc Symbols (zawiera m.in. ✅ ❌ ⚠️)
    if 0x2600 <= cp <= 0x27BF:
        return True

    # Supplemental Symbols and Pictographs, Emoticons, Transport & Map
    if 0x1F300 <= cp <= 0x1FAFF:
        return True

    # Variation selector (często w emoji, np. ⚠️)
    if cp == 0xFE0F:
        return True

    return False


def iter_md_files(root: str):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in IGNORED_DIRS]
        for fn in filenames:
            if fn.lower().endswith(".md"):
                yield os.path.join(dirpath, fn)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--path", default=os.getcwd(), help="katalog do skanowania (domyślnie bieżący)")
    args = ap.parse_args()

    root = os.path.abspath(args.path)
    bad = []

    for path in iter_md_files(root):
        try:
            with open(path, "r", encoding="utf-8") as f:
                for lineno, line in enumerate(f, start=1):
                    for col, ch in enumerate(line, start=1):
                        if is_emoji_or_icon(ch):
                            bad.append((path, lineno, col, ch, line.rstrip("\n")))
                            break
        except UnicodeDecodeError:
            # jeśli trafi się binarny/inna kodowanie – pomijamy, ale sygnalizujemy
            bad.append((path, 0, 0, "?", "NIE MOŻNA ODCZYTAĆ (błędne kodowanie)"))

    if not bad:
        print("OK: nie znaleziono emoji/ikonek w plikach .md")
        return 0

    print("Znaleziono emoji/ikonki w Markdown (usuń przed importem do Confluence):")
    for path, lineno, col, ch, line in bad:
        if lineno == 0:
            print(f"- {path}: {line}")
        else:
            print(f"- {path}:{lineno}:{col}: {repr(ch)} | {line}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

