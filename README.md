# revoockv-flutter-clean-arch

An agent skill (Claude Code, Cursor, Codex and other agents that read `SKILL.md`) for building Flutter apps with clean architecture by **templates**. A template holds every choice of the architecture and code style — folders, state manager, DI, use cases, errors, models, style, tests, git — split into small rule files, plus an example project built with all of it. The default template, `revoockv-original`, is clean architecture on **GetIt + watch_it** and `ValueNotifier`-based reactive state. Make your own template from it (`docs/constructor.md`); templates have their own versions, the skill has its own.

The agent uses it to create features, refactor or migrate existing ones (from Riverpod, Bloc or streams), wire DI per feature, map data models to domain entities and build UI with as few and as low rebuilds as possible. A linter checks the result.

> **About this skill.** This is my own attempt at understanding clean architecture in Flutter, not an official or final standard. The rules here are how I see it today. I keep learning, so I will keep updating the skill: rules can change, including breaking ones, every time I understand something better. Each change is listed in [CHANGELOG.md](CHANGELOG.md). Issues and suggestions are welcome.

## Install

With the [skills CLI](https://github.com/vercel-labs/skills):

```bash
# for every project (user level)
npx skills add revoockv/revoockv-flutter-clean-arch -g

# only for the current project
npx skills add revoockv/revoockv-flutter-clean-arch

# for a specific agent
npx skills add revoockv/revoockv-flutter-clean-arch -g -a claude-code
```

Update later with `npx skills update`.

Manually: clone the repository into your agent's skills folder, e.g.

```bash
git clone https://github.com/revoockv/revoockv-flutter-clean-arch ~/.claude/skills/revoockv-flutter-clean-arch
```

## Use

Ask the agent in plain words, for example:

- "Create a notes feature with add and delete"
- "Refactor `lib/features/profile` to the clean architecture"
- "Migrate this Bloc screen to watch_it"

The agent follows `SKILL.md` and the references, then runs the linter.

## What it enforces (template `revoockv-original`)

- **Layers per feature:** `data` / `domain` / `presentation`; `core` mirrors the same layout.
- **DI:** one `registerAndInit<Feature>()` per feature, registered by type in GetIt; widgets reach use cases only through `<feature>_getters.dart`.
- **State:** repositories keep a private `ValueNotifier` and expose `ValueListenable<ResultState<T>>`; widgets read it with `watch(watch<Name>UseCase()).value` and `switch` over it.
- **Results:** actions return `Future<Result<T>>`; failures are human-readable messages, exceptions are logged.
- **UI controllers:** UI state only, like `TextEditingController` — no DI, no use cases; named `<noun>Controller`; owned by a `WatchingWidget` with `createOnce`, which calls the use cases itself.
- **Ids:** UUID v4 created in the data source.
- **Tests:** a test DI per feature with fake data sources; the app code stays as it is.
- **Conventions:** naming, no magic numbers/strings/colors, Dartdoc on every public declaration, logging, git rules.

## Contents

```
SKILL.md                         how the agent finds the template and reads only what the task needs
templates/index.toml             the default template
templates/<name>/<version>/      template.toml (choices, topics), rules/<topic>/*.md, example/ (runnable app)
docs/constructor.md              how templates are built, made, changed and versioned
docs/linter.md                   the architecture linter
scripts/                         templates, linter, feature generator, version check, self-check
tests/                           linter unit tests
```

## Scripts

Run them from the skill folder with Python 3 (3.11+).

```bash
# templates: list, show, choose, create, version, validate
python3 scripts/templates.py list
python3 scripts/templates.py show --project path/to/app
python3 scripts/templates.py use revoockv-original@1.0.0 --project path/to/app
python3 scripts/templates.py new my-arch --from revoockv-original@1.0.0
python3 scripts/templates.py bump my-arch --to 1.1.0
python3 scripts/templates.py validate --all

# architecture linter (30 rules) on a Flutter project
python3 scripts/dart_clean_arch_linter.py path/to/app/lib --strict

# folder skeleton and DI stubs for a new project or feature
python3 scripts/init_feature.py --core --lib-dir path/to/app/lib
python3 scripts/init_feature.py --feature notes --lib-dir path/to/app/lib

# pinned package versions vs pub.dev
python3 scripts/check_versions.py

# self-check of every template: rules vs example, example analyze/test/lint
python3 scripts/selfcheck.py
```

`selfcheck.py` and the example app need the Flutter SDK (Dart `^3.12.0`); `--no-flutter` skips those steps.

## Packages

`get_it ^9.3.0`, `watch_it ^2.5.0`, `logger ^2.8.0`, `uuid ^4.6.0`, `flutter_lints ^6.0.0`.

## Versioning

[Semantic Versioning](https://semver.org/) for the skill ([CHANGELOG.md](CHANGELOG.md)) and, separately, for every template (`templates/<name>/CHANGELOG.md`).

## License

[MIT](LICENSE)
