#!/usr/bin/env python3
"""
Create the folder skeleton (and DI stubs) of revoockv Flutter clean architecture.

Every layer gets every subfolder the `folder_naming` linter rule requires; empty
folders get a `.gitkeep` so git keeps them.

  lib/features/<feature>/            lib/core/
    data/data_sources|models|repositories
    domain/entities|repositories|use_cases
    presentation/pages|widgets|di|controllers

The folders come from `[structure]` of the project's template (`.clean_arch.toml`, else
the default template, or `--template`). `--core` also copies the template's
`[scaffold] core_files` from its example (the verified reference). Stub files come from
the template's `scaffold/` folder: `app/` (with --core, under lib/), `feature/` and
`subfeature/` (under the feature); existing files are kept.

Usage:
  python3 scripts/init_feature.py --core
  python3 scripts/init_feature.py --feature notes
  python3 scripts/init_feature.py --feature auth --subfeature session
  python3 scripts/init_feature.py --feature notes --lib-dir path/to/app/lib
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SKILL_ROOT / "scripts"))
import templates  # noqa: E402

# Set by main() from the project's template: its example, folders and core files
EXAMPLE = Path()
EXAMPLE_PACKAGE = ""
LAYOUT: dict[str, tuple[str, ...]] = {}
CORE_FILES: tuple[str, ...] = ()

# Stub files of the template: <template>/scaffold/{app,feature,subfeature}/**.tmpl.
# `{{feature}}`, `{{Feature}}`, `{{subfeature}}`, `{{Subfeature}}`, `{{package}}` in names and text are filled in.
SCAFFOLD = Path()
TEMPLATE_SUFFIX = ".tmpl"
NEXT_STEP = ""


def _title(name: str) -> str:
    return "".join(part[:1].upper() + part[1:] for part in name.split("_"))


def _package_name(lib_dir: Path) -> str | None:
    pubspec = lib_dir.resolve().parent / "pubspec.yaml"
    if not pubspec.is_file():
        return None
    m = re.search(r"^name:\s*(\S+)", pubspec.read_text(encoding="utf-8"), re.M)
    return m.group(1) if m else None


def _write_if_missing(path: Path, contents: str) -> None:
    if path.exists():
        print(f"  kept     {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents, encoding="utf-8")
    print(f"  created  {path}")


def _make_layout(root: Path) -> None:
    for layer, subfolders in LAYOUT.items():
        for sub in subfolders:
            (root / layer / sub).mkdir(parents=True, exist_ok=True)


def _keep_empty_folders(root: Path) -> None:
    for folder in sorted(p for p in root.rglob("*") if p.is_dir()):
        if not any(folder.iterdir()):
            (folder / ".gitkeep").touch()


def _fill(text: str, values: dict[str, str]) -> str:
    for key, value in values.items():
        text = text.replace("{{" + key + "}}", value)
    return text


def _copy_stubs(kind: str, target: Path, values: dict[str, str]) -> None:
    """Write the template's `scaffold/<kind>/` stubs under [target] (existing files are kept)."""
    source = SCAFFOLD / kind
    if not source.is_dir():
        return
    for stub in sorted(source.rglob("*" + TEMPLATE_SUFFIX)):
        relative = _fill(str(stub.relative_to(source))[: -len(TEMPLATE_SUFFIX)], values)
        _write_if_missing(target / relative, _fill(stub.read_text(encoding="utf-8"), values))


def init_core(lib_dir: Path) -> None:
    root = lib_dir / "core"
    _make_layout(root)
    package = _package_name(lib_dir)
    for rel in CORE_FILES:
        code = (EXAMPLE / "lib" / rel).read_text(encoding="utf-8")
        if package:
            code = code.replace(f"package:{EXAMPLE_PACKAGE}/", f"package:{package}/")
        _write_if_missing(lib_dir / rel, code)
    _copy_stubs("app", lib_dir, {"package": package or EXAMPLE_PACKAGE})
    _keep_empty_folders(root)
    print(f"Initialized core at: {root}")


def init_feature(lib_dir: Path, feature: str, subfeature: str | None) -> None:
    root = lib_dir / "features" / feature
    _make_layout(root)
    values = {
        "feature": feature,
        "Feature": _title(feature),
        "package": _package_name(lib_dir) or EXAMPLE_PACKAGE,
    }
    _copy_stubs("feature", root, values)
    if subfeature:
        _copy_stubs("subfeature", root, {**values, "subfeature": subfeature, "Subfeature": _title(subfeature)})
    _keep_empty_folders(root)
    print(f"Initialized feature at: {root}")
    if NEXT_STEP:
        print(f"Next: {_fill(NEXT_STEP, values)}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--feature", default=None)
    parser.add_argument("--subfeature", default=None)
    parser.add_argument("--lib-dir", default="lib")
    parser.add_argument("--core", action="store_true")
    parser.add_argument("--template", help="template (name@version); default: the project's .clean_arch.toml, else the skill's default")
    args = parser.parse_args()

    global EXAMPLE, EXAMPLE_PACKAGE, LAYOUT, CORE_FILES, SCAFFOLD, NEXT_STEP
    try:
        template = templates.resolve(args.template, Path(args.lib_dir).resolve().parent)
    except templates.TemplateError as e:
        raise SystemExit(str(e)) from e
    EXAMPLE, EXAMPLE_PACKAGE = template.example_dir, template.example_package
    LAYOUT, CORE_FILES = template.layout, template.core_files
    SCAFFOLD = template.folder / "scaffold"
    NEXT_STEP = str(template.data.get("scaffold", {}).get("next_step", ""))
    print(f"Template {template.ref}")

    if not args.core and not args.feature:
        raise SystemExit("Provide --feature <name> and/or --core.")
    for flag, name in (("--feature", args.feature), ("--subfeature", args.subfeature)):
        if name is not None and not re.fullmatch(r"[a-z][a-z0-9_]*", name):
            raise SystemExit(f"{flag} '{name}' must be snake_case (a-z, 0-9, _), e.g. user_profile — it becomes file names and registerAndInit<Name>().")
    if args.subfeature and not args.feature:
        raise SystemExit("--subfeature needs --feature.")

    lib_dir = Path(args.lib_dir)
    if args.core:
        init_core(lib_dir)
    if args.feature:
        init_feature(lib_dir, args.feature, args.subfeature)


if __name__ == "__main__":
    main()
