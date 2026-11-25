# Packages (pinned versions)

```yaml
environment:
  sdk: ^3.12.0
dependencies:
  flutter_bloc: ^9.1.1
  logger: ^2.8.0
  uuid: ^4.6.0
dev_dependencies:
  bloc_test: ^10.0.0
  flutter_lints: ^6.0.0
```

`flutter_bloc` exports `bloc` and the `provider` context extensions; do not add them separately. No `equatable`: its 3.x
compares without `runtimeType`, so two different states with the same fields would be equal (`rules/state/blocs.md`).

The source of truth is `example/pubspec.yaml`. Before adding packages, run `python3 <skill_base>/scripts/check_versions.py`
(`[packages] tracked` of `template.toml`); `--update` bumps the pins, then `scripts/selfcheck.py` must pass.
