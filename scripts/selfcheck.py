#!/usr/bin/env python3
"""
Self-check of the skill: the docs, the linter and the example app must agree.

Steps:
  1. linter unit tests            python3 -m unittest discover -s tests
  2. package versions             scripts/check_versions.py (report; --strict-versions fails on outdated)
  3. code in the docs vs example  every ```dart block whose line above is a `lib/core/...dart` or
                                  `lib/features/api_server/...dart` path must equal the example's file
  4. example app                  copy of assets/example_app → flutter pub get, analyze, test, linter --strict
  5. auth template from the docs  every ```dart block under a `lib/features/auth/...dart` path is written
                                  into the copy of the example app and must pass flutter analyze and the linter

Usage:
  python3 scripts/selfcheck.py              # everything
  python3 scripts/selfcheck.py --no-flutter # steps 1-3 only
  python3 scripts/selfcheck.py --keep       # keep the temp project and print its path
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
EXAMPLE = SKILL_ROOT / "assets" / "example_app"
LINTER = SKILL_ROOT / "scripts" / "dart_clean_arch_linter.py"
DOC_FILES = [SKILL_ROOT / "SKILL.md", *sorted((SKILL_ROOT / "references").glob("*.md"))]

# Docs use this package name in imports; the example app uses its own
DOCS_PACKAGE = "your_app"
EXAMPLE_PACKAGE = "example_app"

# Doc code blocks checked by compiling: core files and the auth template
DOC_PATH_PREFIXES = ("lib/core/", "lib/features/auth/", "lib/features/api_server/")

# Doc blocks that must equal the example app file by file
EXAMPLE_PATH_PREFIXES = ("lib/core/", "lib/features/api_server/")

# A file block: a line that starts with `lib/....dart`, a blank line, then ```dart
DOC_FILE_BLOCK = re.compile(r"^`(lib/[^`]+\.dart)`[^\n]*\n\n```dart\n(.*?)```", re.M | re.S)

_failures: list[str] = []


def step(title: str) -> None:
    print(f"\n── {title}")


def check(ok: bool, label: str, details: str = "") -> bool:
    print(f"  {'✓' if ok else '✗'} {label}")
    if not ok:
        _failures.append(label)
        if details:
            print("    " + details.strip().replace("\n", "\n    ")[-3000:])
    return ok


def run(cmd: list[str], cwd: Path) -> tuple[bool, str]:
    proc = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return proc.returncode == 0, proc.stdout + proc.stderr


def doc_blocks() -> dict[str, str]:
    """Return {lib path: code} of doc file blocks for core and the auth template."""
    blocks: dict[str, str] = {}
    for doc in DOC_FILES:
        for path, code in DOC_FILE_BLOCK.findall(doc.read_text(encoding="utf-8")):
            if not path.startswith(DOC_PATH_PREFIXES):
                continue
            code = code.replace(f"package:{DOCS_PACKAGE}/", f"package:{EXAMPLE_PACKAGE}/")
            if path in blocks and blocks[path] != code:
                check(False, f"{path} is defined twice in the docs with different code ({doc.name})")
            blocks[path] = code
    return blocks


def compare_core(blocks: dict[str, str]) -> None:
    for path, code in sorted(blocks.items()):
        if not path.startswith(EXAMPLE_PATH_PREFIXES):
            continue
        example_file = EXAMPLE / path
        same = example_file.is_file() and example_file.read_text(encoding="utf-8") == code
        check(same, f"docs {path} == example app", "" if same else "the docs and assets/example_app differ — update one of them")


def flutter_checks(project: Path, label: str) -> None:
    ok, out = run(["flutter", "pub", "get"], project)
    if not ok:
        ok, out = run(["flutter", "pub", "get", "--offline"], project)
    if not check(ok, f"{label}: flutter pub get", out):
        return
    ok, out = run(["flutter", "analyze"], project)
    check(ok, f"{label}: flutter analyze", out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--no-flutter", action="store_true", help="skip steps that need the Flutter SDK")
    parser.add_argument("--strict-versions", action="store_true", help="fail when a package is outdated")
    parser.add_argument("--keep", action="store_true", help="keep the temp project")
    args = parser.parse_args()

    step("1. Linter unit tests")
    ok, out = run([sys.executable, "-m", "unittest", "discover", "-s", "tests"], SKILL_ROOT)
    check(ok, "tests/test_linter.py", out)

    step("2. Package versions")
    cmd = [sys.executable, str(SKILL_ROOT / "scripts" / "check_versions.py")]
    ok, out = run(cmd + (["--strict"] if args.strict_versions else []), SKILL_ROOT)
    print("  " + out.strip().replace("\n", "\n  "))
    check(ok, "versions" + (" (strict)" if args.strict_versions else " (report only)"))

    step("3. Code in the docs vs the example app")
    blocks = doc_blocks()
    check(bool(blocks), f"found {len(blocks)} file blocks in the docs")
    compare_core(blocks)

    if not args.no_flutter:
        tmp = Path(tempfile.mkdtemp(prefix="clean_arch_selfcheck_"))
        project = tmp / EXAMPLE_PACKAGE
        shutil.copytree(EXAMPLE, project, ignore=shutil.ignore_patterns(".dart_tool", "build", "pubspec.lock"))

        step("4. Example app")
        flutter_checks(project, "example app")
        ok, out = run(["flutter", "test"], project)
        check(ok, "example app: flutter test", out)
        ok, out = run([sys.executable, str(LINTER), "lib", "--strict"], project)
        check(ok, "example app: linter --strict", out)

        step("5. Auth template from the docs, compiled inside the example app")
        for path, code in blocks.items():
            target = project / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(code, encoding="utf-8")
        ok, out = run(["flutter", "analyze"], project)
        check(ok, "docs: flutter analyze", out)
        ok, out = run([sys.executable, str(LINTER), "lib/features/auth", "--strict", "--ignore", "folder_naming"], project)
        check(ok, "docs: linter --strict (auth template)", out)

        if args.keep:
            print(f"\n  temp project: {project}")
        else:
            shutil.rmtree(tmp, ignore_errors=True)

    print()
    if _failures:
        print(f"✗ {len(_failures)} check(s) failed")
        return 1
    print("✓ all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
