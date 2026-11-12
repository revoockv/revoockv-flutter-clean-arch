# Packages (pinned versions)

```yaml
environment:
  sdk: ^3.12.0
dependencies:
  get_it: ^9.3.0
  logger: ^2.8.0
  uuid: ^4.6.0
  watch_it: ^2.5.0
dev_dependencies:
  flutter_lints: ^6.0.0
```

The source of truth is `example/pubspec.yaml`. Before adding packages to a project, run `python3 <skill_base>/scripts/check_versions.py`: it compares the pins with the latest versions on pub.dev. When something is outdated, tell the user; `--update` bumps the pins in the example and the docs, then `scripts/selfcheck.py` must pass before the new versions are used.
