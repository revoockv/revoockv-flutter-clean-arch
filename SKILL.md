---
name: revoockv-flutter-clean-arch
description: Build Flutter apps by a chosen clean-architecture template (default revoockv-original - GetIt + watch_it, ValueNotifier-based state) and manage those templates. Use when the user asks to create a new feature or project, refactor an existing project/feature, migrate from Riverpod/Bloc/streams, add DI modules, data models (DTO) with mapping to entities, build minimal-rebuild UI, check code against the architecture (linter), or to create, change, version, choose or validate an architecture template (folders, state manager, DI, use cases, code style, tests, git rules).
metadata:
  version: 0.9.0
  author: revoockv
---

# Flutter clean architecture by templates

The rules live in **templates**: `templates/<name>/<version>/`. A template says how the app is built (folders, state manager, DI, use cases, errors, models, code style, tests, git) and has an `example/` project built with all of it. The skill has its own versions (`CHANGELOG.md`); every template has its versions too (`templates/<name>/CHANGELOG.md`).

## 1. Find the template — always first

```bash
python3 <skill_base>/scripts/templates.py show --project <project_path>
```

It prints the template of the project (`<project>/.clean_arch.toml`, else the default of `templates/index.toml` — now `revoockv-original@1.0.0`), its choices and its topics with their sizes. **Follow that template only.** When its rules and your memory disagree, the template's `example/` wins.

## 2. Read only the topics of the task

```bash
python3 <skill_base>/scripts/templates.py rules --project <project_path> --topic workflow,structure
```

prints the files to read. Topics (`[rules]` of `template.toml`):

| Task | Topics |
|---|---|
| New feature / refactor / migration | `workflow`, `structure`, then `state`, `di`, `use_cases`, `errors_models` as you reach them; `example_feature` for a full worked feature |
| UI and its state | `state` |
| "Which pattern for X?" | `decisions` |
| Code style, constants, logging, docs | `style` |
| Tests | `testing` |
| Commits, branches, merges, releases | `git` |
| Packages and versions | `packages` |
| Serving use cases over HTTP | `http` |

Do not read every topic up front: each costs context. A rule that names `example/<path>` points to working code in the template folder: open that file when you need the code.

## 3. Tools

| Command | What it does |
|---|---|
| `scripts/dart_clean_arch_linter.py [path] [--strict]` | Architecture linter — run it after every change; it skips the rules the template turns off. Details: `docs/linter.md` |
| `scripts/init_feature.py --core` / `--feature <name>` | Folder skeleton of the template (`[structure]`), its core files and DI stubs |
| `scripts/check_versions.py [--template REF]` | The template's pinned packages vs pub.dev (`--update` bumps them) |
| `scripts/selfcheck.py [--template REF]` | Every template: rules vs example, example analyze/test/lint. Run it after changing the skill or a template |

## 4. Making or changing a template

Only for tasks about templates themselves (create, change, version, choose, validate): read `docs/constructor.md`.
