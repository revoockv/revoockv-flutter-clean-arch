#!/usr/bin/env python3
"""
Architecture templates of the skill: find, show, choose, create, version and validate them.

A template is `templates/<name>/<version>/` with `template.toml` (the choices and the
topic → rule files map), `rules/` (the rules, one topic per file), `example/` (a project
built with every rule) and optionally its own CHANGELOG in `templates/<name>/CHANGELOG.md`.

Which template a project uses: `<project>/.clean_arch.toml` (`template = "name@version"`),
else the default of `templates/index.toml`. `name` without `@version` means its newest version.

Usage:
  python3 scripts/templates.py list
  python3 scripts/templates.py show [REF] [--project P]
  python3 scripts/templates.py rules [REF] [--project P] [--topic state,di]   # paths to read
  python3 scripts/templates.py use REF --project P          # writes P/.clean_arch.toml
  python3 scripts/templates.py set-default REF
  python3 scripts/templates.py new NAME --from REF          # a new template, version 1.0.0
  python3 scripts/templates.py bump NAME --to 1.1.0         # a new version from the newest one
  python3 scripts/templates.py validate [REF | --all]
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

SKILL_ROOT = Path(__file__).resolve().parent.parent
TEMPLATES_DIR = SKILL_ROOT / "templates"
INDEX_FILE = TEMPLATES_DIR / "index.toml"
TEMPLATE_FILE = "template.toml"
PROJECT_FILE = ".clean_arch.toml"
SEPARATOR = "@"
VERSION = re.compile(r"^\d+\.\d+\.\d+$")
NAME = re.compile(r"^[a-z0-9][a-z0-9-]*$")
REQUIRED_KEYS = ("name", "version", "description", "choices", "rules", "structure", "example")
# A rule file longer than this costs context; validate warns about it.
MAX_RULE_LINES = 250
# Parameters of [lint.params] the linter reads (dart_clean_arch_linter.configure)
LINT_PARAMS = {"allowed_numbers", "theme_file", "layout_name_words", "use_case_imports_in"}
COPY_IGNORE = shutil.ignore_patterns(".dart_tool", "build", "pubspec.lock", "__pycache__")


class TemplateError(Exception):
    """A template that cannot be found or read."""


@dataclass(frozen=True)
class Template:
    """One version of a template."""

    name: str
    version: str
    folder: Path
    data: dict[str, Any]

    @property
    def ref(self) -> str:
        return f"{self.name}{SEPARATOR}{self.version}"

    @property
    def example_dir(self) -> Path:
        return self.folder / self.data["example"]["path"]

    @property
    def example_package(self) -> str:
        return str(self.data["example"]["package"])

    @property
    def layout(self) -> dict[str, tuple[str, ...]]:
        return {layer: tuple(folders) for layer, folders in self.data["structure"].items()}

    @property
    def core_files(self) -> tuple[str, ...]:
        return tuple(self.data.get("scaffold", {}).get("core_files", ()))

    @property
    def lint_off(self) -> tuple[str, ...]:
        return tuple(self.data.get("lint", {}).get("off", ()))

    def rule_files(self, topics: list[str] | None = None) -> list[Path]:
        """The rule files of [topics] (all when None), in the order of template.toml."""
        rules: dict[str, list[str]] = self.data["rules"]
        unknown = [t for t in topics or () if t not in rules]
        if unknown:
            raise TemplateError(f"unknown topic(s) {', '.join(unknown)}; topics: {', '.join(rules)}")
        chosen = topics or list(rules)
        return [self.folder / f for topic in chosen for f in rules[topic]]

    def doc_files(self) -> list[Path]:
        """Every Markdown file of the template's rules."""
        return sorted((self.folder / "rules").rglob("*.md"))


def _version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def versions(name: str) -> list[str]:
    """The versions of template [name], oldest first."""
    folder = TEMPLATES_DIR / name
    if not folder.is_dir():
        return []
    found = [p.name for p in folder.iterdir() if p.is_dir() and VERSION.match(p.name)]
    return sorted(found, key=_version_key)


def names() -> list[str]:
    return sorted(p.name for p in TEMPLATES_DIR.iterdir() if p.is_dir() and versions(p.name))


def load(ref: str) -> Template:
    """The template [ref] (`name@version` or `name` for its newest version)."""
    name, _, version = ref.partition(SEPARATOR)
    found = versions(name)
    if not found:
        raise TemplateError(f"no template {name!r}; templates: {', '.join(names()) or 'none'}")
    version = version or found[-1]
    if version not in found:
        raise TemplateError(f"{name} has no version {version}; versions: {', '.join(found)}")
    folder = TEMPLATES_DIR / name / version
    file = folder / TEMPLATE_FILE
    if not file.is_file():
        raise TemplateError(f"{file} is missing")
    with file.open("rb") as f:
        data = tomllib.load(f)
    return Template(name=name, version=version, folder=folder, data=data)


def default_ref() -> str:
    with INDEX_FILE.open("rb") as f:
        return str(tomllib.load(f)["default"])


def project_root(path: Path) -> Path | None:
    """The nearest folder with pubspec.yaml at or above [path]."""
    path = path.resolve()
    start = path if path.is_dir() else path.parent
    for folder in (start, *start.parents):
        if (folder / "pubspec.yaml").is_file():
            return folder
    return None


def project_ref(project: Path | None) -> str | None:
    root = project_root(project) if project else None
    file = root / PROJECT_FILE if root else None
    if file is None or not file.is_file():
        return None
    with file.open("rb") as f:
        return tomllib.load(f).get("template")


def resolve(ref: str | None = None, project: Path | None = None) -> Template:
    """[ref], else the project's template, else the default."""
    return load(ref or project_ref(project) or default_ref())


# ── Commands ──


def cmd_list(_: argparse.Namespace) -> int:
    default = default_ref()
    for name in names():
        for version in versions(name):
            ref = f"{name}{SEPARATOR}{version}"
            mark = "  (default)" if ref == default or (default == name and version == versions(name)[-1]) else ""
            print(f"{ref}{mark}  — {load(ref).data.get('description', '')}")
    return 0


def cmd_show(args: argparse.Namespace) -> int:
    template = resolve(args.ref, args.project)
    data = template.data
    print(f"{template.ref} — {data.get('description', '')}")
    print(f"folder: {template.folder}  (rule paths below and `example/…` paths in the rules are relative to it)\n")
    for key, value in data["choices"].items():
        shown = "; ".join(value) if isinstance(value, list) else str(value).lower() if isinstance(value, bool) else value
        print(f"  {key}: {shown}")
    print("\nTopics (lines):")
    for topic, files in data["rules"].items():
        lines = sum(len((template.folder / f).read_text(encoding="utf-8").splitlines()) for f in files)
        print(f"  {topic:16} {lines:5}  {', '.join(files)}")
    return 0


def cmd_rules(args: argparse.Namespace) -> int:
    template = resolve(args.ref, args.project)
    topics = [t.strip() for t in args.topic.split(",")] if args.topic else None
    for file in template.rule_files(topics):
        print(file)
    return 0


def cmd_use(args: argparse.Namespace) -> int:
    template = load(args.ref)
    root = project_root(args.project)
    if root is None:
        raise TemplateError(f"no pubspec.yaml at or above {args.project}")
    (root / PROJECT_FILE).write_text(
        f'# Architecture template of this project (revoockv-flutter-clean-arch).\ntemplate = "{template.ref}"\n',
        encoding="utf-8",
    )
    print(f"{root / PROJECT_FILE}: {template.ref}")
    return 0


def cmd_set_default(args: argparse.Namespace) -> int:
    template = load(args.ref)
    INDEX_FILE.write_text(
        f'# The template a project without `{PROJECT_FILE}` uses.\ndefault = "{template.ref}"\n', encoding="utf-8"
    )
    print(f"default: {template.ref}")
    return 0


def _copy(source: Template, name: str, version: str) -> Path:
    target = TEMPLATES_DIR / name / version
    if target.exists():
        raise TemplateError(f"{target} already exists")
    shutil.copytree(source.folder, target, ignore=COPY_IGNORE)
    file = target / TEMPLATE_FILE
    text = file.read_text(encoding="utf-8")
    text = re.sub(r'^name = ".*"$', f'name = "{name}"', text, count=1, flags=re.M)
    text = re.sub(r'^version = ".*"$', f'version = "{version}"', text, count=1, flags=re.M)
    file.write_text(text, encoding="utf-8")
    changelog = TEMPLATES_DIR / name / "CHANGELOG.md"
    entry = f"## [{version}]\n\n- Made from {source.ref}.\n"
    if changelog.is_file():
        head, _, rest = changelog.read_text(encoding="utf-8").partition("\n## ")
        changelog.write_text(f"{head.rstrip()}\n\n{entry}\n## {rest}" if rest else f"{head.rstrip()}\n\n{entry}", encoding="utf-8")
    else:
        changelog.write_text(f"# {name} — changelog\n\n{entry}", encoding="utf-8")
    return target


def cmd_new(args: argparse.Namespace) -> int:
    if not NAME.match(args.name):
        raise TemplateError("a template name is lowercase kebab-case")
    if versions(args.name):
        raise TemplateError(f"{args.name} exists; make a new version with bump")
    target = _copy(load(args.source), args.name, args.version)
    print(f"created {target}\nnext: change template.toml and rules/, rebuild example/, run validate and selfcheck")
    return 0


def cmd_bump(args: argparse.Namespace) -> int:
    if not VERSION.match(args.to):
        raise TemplateError("a version is MAJOR.MINOR.PATCH")
    source = load(f"{args.name}{SEPARATOR}{args.source_version}" if args.source_version else args.name)
    if _version_key(args.to) <= _version_key(versions(args.name)[-1]):
        raise TemplateError(f"{args.to} is not newer than {versions(args.name)[-1]}")
    target = _copy(source, args.name, args.to)
    print(f"created {target}")
    return 0


def problems(template: Template) -> tuple[list[str], list[str]]:
    """(errors, warnings) of [template]."""
    errors: list[str] = []
    warnings: list[str] = []
    data = template.data
    for key in REQUIRED_KEYS:
        if key not in data:
            errors.append(f"template.toml has no `{key}`")
    if errors:
        return errors, warnings
    if data["name"] != template.name or data["version"] != template.version:
        errors.append(f"template.toml says {data['name']}@{data['version']}, its folder {template.ref}")
    for topic, files in data["rules"].items():
        for f in files:
            path = template.folder / f
            if not path.is_file():
                errors.append(f"{topic}: {f} is missing")
                continue
            lines = len(path.read_text(encoding="utf-8").splitlines())
            if lines > MAX_RULE_LINES:
                warnings.append(f"{f}: {lines} lines (> {MAX_RULE_LINES}) — split it to save context")
    listed = {template.folder / f for files in data["rules"].values() for f in files}
    for doc in template.doc_files():
        if doc not in listed:
            warnings.append(f"{doc.relative_to(template.folder)} is in no topic of [rules]")
    if not (template.example_dir / "pubspec.yaml").is_file():
        errors.append(f"example: {template.example_dir} has no pubspec.yaml")
    for core in template.core_files:
        if not (template.example_dir / "lib" / core).is_file():
            errors.append(f"scaffold: {core} is not in the example")
    sys.path.insert(0, str(SKILL_ROOT / "scripts"))
    from dart_clean_arch_linter import ALL_RULES  # noqa: PLC0415

    lint = data.get("lint", {})
    for key in ("off", "warn"):
        unknown = sorted(set(lint.get(key, ())) - ALL_RULES)
        if unknown:
            errors.append(f"lint.{key}: unknown rule(s) {', '.join(unknown)}")
    unknown_params = sorted(set(lint.get("params", {})) - LINT_PARAMS)
    if unknown_params:
        errors.append(f"lint.params: unknown {', '.join(unknown_params)}; known: {', '.join(sorted(LINT_PARAMS))}")
    return errors, warnings


def cmd_validate(args: argparse.Namespace) -> int:
    refs = [f"{n}{SEPARATOR}{v}" for n in names() for v in versions(n)] if args.all else [resolve(args.ref).ref]
    failed = 0
    for ref in refs:
        errors, warnings = problems(load(ref))
        print(f"{'✗' if errors else '✓'} {ref}")
        for e in errors:
            print(f"    error: {e}")
        for w in warnings:
            print(f"    warning: {w}")
        failed += bool(errors)
    if not args.all:
        print("full check (example builds, tests, lints): python3 scripts/selfcheck.py --template " + refs[0])
    return 1 if failed else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("list", help="every template version").set_defaults(run=cmd_list)
    for name, run, helptext in (("show", cmd_show, "choices and topics"), ("rules", cmd_rules, "paths of rule files")):
        p = sub.add_parser(name, help=helptext)
        p.add_argument("ref", nargs="?")
        p.add_argument("--project", type=Path, default=Path.cwd())
        if name == "rules":
            p.add_argument("--topic", help="comma-separated topics (default: all)")
        p.set_defaults(run=run)
    p = sub.add_parser("use", help="choose the template of a project")
    p.add_argument("ref")
    p.add_argument("--project", type=Path, default=Path.cwd())
    p.set_defaults(run=cmd_use)
    p = sub.add_parser("set-default", help="the template of projects that choose none")
    p.add_argument("ref")
    p.set_defaults(run=cmd_set_default)
    p = sub.add_parser("new", help="a new template copied from another")
    p.add_argument("name")
    p.add_argument("--from", dest="source", required=True)
    p.add_argument("--version", default="1.0.0")
    p.set_defaults(run=cmd_new)
    p = sub.add_parser("bump", help="a new version of a template")
    p.add_argument("name")
    p.add_argument("--to", required=True)
    p.add_argument("--from-version", dest="source_version")
    p.set_defaults(run=cmd_bump)
    p = sub.add_parser("validate", help="check a template (or --all)")
    p.add_argument("ref", nargs="?")
    p.add_argument("--all", action="store_true")
    p.set_defaults(run=cmd_validate)
    args = parser.parse_args(argv)
    try:
        return args.run(args)
    except TemplateError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
