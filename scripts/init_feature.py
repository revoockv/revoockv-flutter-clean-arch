#!/usr/bin/env python3
"""
Create the folder skeleton (and DI stubs) of revoockv Flutter clean architecture.

Every layer gets every subfolder the `folder_naming` linter rule requires; empty
folders get a `.gitkeep` so git keeps them.

  lib/features/<feature>/            lib/core/
    data/data_sources|models|repositories
    domain/entities|repositories|use_cases
    presentation/pages|widgets|di|controllers

`--core` also copies the core files from assets/example_app (the verified
reference): result.dart, disposable_resource.dart, result_state.dart, core_di.dart, theme.dart —
and creates lib/di.dart with registerAndInit() when it is missing.

Usage:
  python3 scripts/init_feature.py --core
  python3 scripts/init_feature.py --feature notes
  python3 scripts/init_feature.py --feature auth --subfeature session
  python3 scripts/init_feature.py --feature notes --lib-dir path/to/app/lib
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
EXAMPLE = SKILL_ROOT / "assets" / "example_app"
EXAMPLE_PACKAGE = "example_app"

LAYOUT = {
    "data": ("data_sources", "models", "repositories"),
    "domain": ("entities", "repositories", "use_cases"),
    "presentation": ("pages", "widgets", "di", "controllers"),
}

CORE_FILES = (
    "core/domain/entities/result.dart",
    "core/domain/entities/disposable_resource.dart",
    "core/domain/entities/result_state.dart",
    "core/presentation/di/core_di.dart",
    "core/presentation/theme.dart",
)

APP_DI = """import 'package:watch_it/watch_it.dart';

import 'core/presentation/di/core_di.dart';

/// Registers every feature and waits until all async initializations finish.
Future<void> registerAndInit() async {
  await di.reset();

  registerAndInitCore();

  // registerAndInit<Feature>(); — one line per feature

  await di.allReady();
}
"""


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


def init_core(lib_dir: Path) -> None:
    root = lib_dir / "core"
    _make_layout(root)
    package = _package_name(lib_dir)
    for rel in CORE_FILES:
        code = (EXAMPLE / "lib" / rel).read_text(encoding="utf-8")
        if package:
            code = code.replace(f"package:{EXAMPLE_PACKAGE}/", f"package:{package}/")
        _write_if_missing(lib_dir / rel, code)
    _write_if_missing(lib_dir / "di.dart", APP_DI)
    _keep_empty_folders(root)
    print(f"Initialized core at: {root}")


def init_feature(lib_dir: Path, feature: str, subfeature: str | None) -> None:
    root = lib_dir / "features" / feature
    _make_layout(root)
    title = _title(feature)

    _write_if_missing(
        root / "presentation" / "di" / f"{feature}_di.dart",
        f"""/// Registers the {feature} feature and starts its async initialization.
///
/// Called from `registerAndInit()` in `lib/di.dart`; `di.allReady()` waits for its `init()`s.
void registerAndInit{title}() {{
  // import 'package:watch_it/watch_it.dart'; and register bottom-up:
  // 1. data sources — di.registerLazySingleton<...>(..., dispose: disposeResource)
  // 2. repositories — di.registerSingletonAsync<...>(() => Impl(...).init(), dispose: disposeResource)
  //    or di.registerLazySingleton<...>(...) when there is no startup work
  // 3. use cases — di.registerLazySingleton<...>(() => UseCase(di<Repository>()))
}}
""",
    )
    _write_if_missing(
        root / "presentation" / "di" / f"{feature}_getters.dart",
        f"""// UI getters for the {feature} feature: one top-level getter per use case.
// Widgets import only this file. Example:
//
// /// Watch use case for the live list of items.
// Watch{title}UseCase get watch{title}UseCase => di<Watch{title}UseCase>();
""",
    )
    if subfeature:
        _write_if_missing(
            root / "presentation" / "di" / f"{subfeature}_di.dart",
            f"""/// Registers the {feature}.{subfeature} subfeature and starts its async initialization.
///
/// Prefer feature-only DI unless the user explicitly requests subfeature DI.
void registerAndInit{title}{_title(subfeature)}() {{
  // Register subfeature data sources, repositories, use cases (see {feature}_di.dart).
}}
""",
        )
    _keep_empty_folders(root)
    print(f"Initialized feature at: {root}")
    print(f"Next: call registerAndInit{title}() from registerAndInit() in lib/di.dart")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--feature", default=None)
    parser.add_argument("--subfeature", default=None)
    parser.add_argument("--lib-dir", default="lib")
    parser.add_argument("--core", action="store_true")
    args = parser.parse_args()

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
