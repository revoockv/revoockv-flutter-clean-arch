#!/usr/bin/env python3
"""
Self-check of the skill: for every template, its rules, the linter and its example must agree.

Steps:
  1. linter unit tests            python3 -m unittest discover -s tests
  For each template version (or --template):
  2. template                     scripts/templates.py validate (files, keys, sizes)
  3. package versions             scripts/check_versions.py (report; --strict-versions fails on outdated)
  4. code in the rules vs example every ```dart block whose line above is a path under `[example] same_as_example`
                                  must equal the example's file
  5. example                      copy of example/ → flutter pub get, analyze, test, linter --strict
  6. feature from the rules       every ```dart block under `[example] doc_paths` is written into the copy of
                                  the example and must pass flutter analyze and the linter

Usage:
  python3 scripts/selfcheck.py                                   # every template
  python3 scripts/selfcheck.py --template revoockv-original@1.0.0
  python3 scripts/selfcheck.py --no-flutter                      # without the Flutter steps
  python3 scripts/selfcheck.py --keep                            # keep the temp projects
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
LINTER = SKILL_ROOT / "scripts" / "dart_clean_arch_linter.py"
sys.path.insert(0, str(SKILL_ROOT / "scripts"))
import templates  # noqa: E402

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


def doc_blocks(template: templates.Template) -> dict[str, str]:
    """Return {lib path: code} of the rules' file blocks under `[example] doc_paths`."""
    example = template.data["example"]
    prefixes = tuple(example.get("doc_paths", ()))
    blocks: dict[str, str] = {}
    for doc in template.doc_files():
        for path, code in DOC_FILE_BLOCK.findall(doc.read_text(encoding="utf-8")):
            if not path.startswith(prefixes):
                continue
            code = code.replace(f"package:{example.get('docs_package', 'your_app')}/", f"package:{template.example_package}/")
            if path in blocks and blocks[path] != code:
                check(False, f"{path} is defined twice in the docs with different code ({doc.name})")
            blocks[path] = code
    return blocks


def compare_core(template: templates.Template, blocks: dict[str, str]) -> None:
    prefixes = tuple(template.data["example"].get("same_as_example", ()))
    for path, code in sorted(blocks.items()):
        if not path.startswith(prefixes):
            continue
        example_file = template.example_dir / path
        same = example_file.is_file() and example_file.read_text(encoding="utf-8") == code
        check(same, f"rules {path} == example", "" if same else "the rules and example/ differ — update one of them")


def flutter_checks(project: Path, label: str) -> None:
    ok, out = run(["flutter", "pub", "get"], project)
    if not ok:
        ok, out = run(["flutter", "pub", "get", "--offline"], project)
    if not check(ok, f"{label}: flutter pub get", out):
        return
    ok, out = run(["flutter", "analyze"], project)
    check(ok, f"{label}: flutter analyze", out)


def check_template(template: templates.Template, args: argparse.Namespace) -> None:
    print(f"\n══ {template.ref}")
    step("2. Template")
    errors, warnings = templates.problems(template)
    for warning in warnings:
        print(f"  ! {warning}")
    check(not errors, "templates.py validate", "\n".join(errors))

    step("3. Package versions")
    cmd = [sys.executable, str(SKILL_ROOT / "scripts" / "check_versions.py"), "--template", template.ref]
    ok, out = run(cmd + (["--strict"] if args.strict_versions else []), SKILL_ROOT)
    print("  " + out.strip().replace("\n", "\n  "))
    check(ok, "versions" + (" (strict)" if args.strict_versions else " (report only)"))

    step("4. Code in the rules vs the example")
    blocks = doc_blocks(template)
    print(f"  found {len(blocks)} file blocks in the rules")
    compare_core(template, blocks)

    if args.no_flutter:
        return
    tmp = Path(tempfile.mkdtemp(prefix="clean_arch_selfcheck_"))
    project = tmp / template.example_package
    shutil.copytree(template.example_dir, project, ignore=templates.COPY_IGNORE)
    (project / templates.PROJECT_FILE).write_text(f'template = "{template.ref}"\n', encoding="utf-8")

    step("5. Example")
    flutter_checks(project, "example")
    ok, out = run(["flutter", "test"], project)
    check(ok, "example: flutter test", out)
    ok, out = run([sys.executable, str(LINTER), "lib", "--strict"], project)
    check(ok, "example: linter --strict", out)

    feature = template.data["example"].get("doc_feature")
    if blocks and feature:
        step("6. Feature from the rules, compiled inside the example")
        for path, code in blocks.items():
            target = project / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(code, encoding="utf-8")
        ok, out = run(["flutter", "analyze"], project)
        check(ok, "rules: flutter analyze", out)
        ok, out = run([sys.executable, str(LINTER), feature, "--strict", "--ignore", "folder_naming"], project)
        check(ok, f"rules: linter --strict ({feature})", out)

    if args.keep:
        print(f"\n  temp project: {project}")
    else:
        shutil.rmtree(tmp, ignore_errors=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--no-flutter", action="store_true", help="skip steps that need the Flutter SDK")
    parser.add_argument("--strict-versions", action="store_true", help="fail when a package is outdated")
    parser.add_argument("--keep", action="store_true", help="keep the temp projects")
    parser.add_argument("--template", help="check only this template (name@version)")
    args = parser.parse_args()

    step("1. Linter unit tests")
    ok, out = run([sys.executable, "-m", "unittest", "discover", "-s", "tests"], SKILL_ROOT)
    check(ok, "tests/test_linter.py", out)

    refs = (
        [templates.load(args.template).ref]
        if args.template
        else [f"{n}{templates.SEPARATOR}{v}" for n in templates.names() for v in templates.versions(n)]
    )
    for ref in refs:
        check_template(templates.load(ref), args)

    print()
    if _failures:
        print(f"✗ {len(_failures)} check(s) failed")
        return 1
    print("✓ all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
