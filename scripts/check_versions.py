#!/usr/bin/env python3
"""
Compare the package versions pinned by this skill with the latest ones on pub.dev.

The single source of pinned versions is assets/example_app/pubspec.yaml.
`--update` rewrites the outdated constraints there and in every reference that
shows a pubspec snippet, so docs and the example stay in sync.

Usage:
  python3 scripts/check_versions.py            # report; exit 0
  python3 scripts/check_versions.py --strict   # exit 1 when something is outdated
  python3 scripts/check_versions.py --update   # bump constraints to the latest versions
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
PUBSPEC = SKILL_ROOT / "assets" / "example_app" / "pubspec.yaml"
DOC_FILES = [SKILL_ROOT / "SKILL.md", *sorted((SKILL_ROOT / "references").glob("*.md"))]

# Packages whose versions the skill prescribes
TRACKED = ("get_it", "watch_it", "logger", "uuid", "flutter_lints")

PUB_API = "https://pub.dev/api/packages/{name}"
CONSTRAINT = r"(^\s*{name}:\s*\^)(\d+\.\d+\.\d+)"


def pinned_versions() -> dict[str, str]:
    """Return {package: version} pinned in the example pubspec."""
    text = PUBSPEC.read_text(encoding="utf-8")
    found: dict[str, str] = {}
    for name in TRACKED:
        m = re.search(CONSTRAINT.format(name=name), text, re.M)
        if m:
            found[name] = m.group(2)
    return found


def latest_version(name: str) -> str | None:
    """Return the latest stable version on pub.dev, or None when offline."""
    try:
        with urllib.request.urlopen(PUB_API.format(name=name), timeout=15) as resp:
            return json.load(resp)["latest"]["version"]
    except Exception as e:  # network errors must not break offline work
        print(f"  ! {name}: cannot reach pub.dev ({e})", file=sys.stderr)
        return None


def _key(version: str) -> tuple[int, ...]:
    return tuple(int(p) for p in re.findall(r"\d+", version)[:3])


def update(outdated: dict[str, str]) -> list[Path]:
    """Rewrite `name: ^old` to `name: ^new` in the pubspec and docs; return changed files."""
    changed: list[Path] = []
    for path in [PUBSPEC, *DOC_FILES]:
        text = path.read_text(encoding="utf-8")
        new = text
        for name, version in outdated.items():
            new = re.sub(CONSTRAINT.format(name=name), rf"\g<1>{version}", new, flags=re.M)
        if new != text:
            path.write_text(new, encoding="utf-8")
            changed.append(path)
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--strict", action="store_true", help="exit 1 when a package is outdated")
    parser.add_argument("--update", action="store_true", help="bump outdated constraints in the pubspec and docs")
    args = parser.parse_args()

    pinned = pinned_versions()
    outdated: dict[str, str] = {}
    print("Package versions (pinned → latest on pub.dev):")
    for name in TRACKED:
        current = pinned.get(name)
        latest = latest_version(name)
        if current is None:
            print(f"  ? {name}: not pinned in {PUBSPEC.relative_to(SKILL_ROOT)}")
            continue
        if latest is None:
            continue
        if _key(latest) > _key(current):
            outdated[name] = latest
            print(f"  ↑ {name}: ^{current} → {latest} available")
        else:
            print(f"  ✓ {name}: ^{current}")

    if outdated and args.update:
        for path in update(outdated):
            print(f"  updated {path.relative_to(SKILL_ROOT)}")
        print("Run scripts/selfcheck.py to verify the example app with the new versions.")
        return 0

    return 1 if (outdated and args.strict) else 0


if __name__ == "__main__":
    sys.exit(main())
