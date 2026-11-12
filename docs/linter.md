# Architecture linter

The linter script lives in the skill's `scripts/` folder. Never copy the script into the project.

**Default target = the whole Flutter project.** When the user does not name a feature, run the linter with no path argument — it defaults to `lib` and walks every feature. Only when the user gives an exact feature path do you narrow the target to that single feature folder.

```bash
# Default — run over the WHOLE project (all features under lib/), no path argument needed
python3 <skill_base>/scripts/dart_clean_arch_linter.py

# Exact feature — run only over one feature when the user names it
python3 <skill_base>/scripts/dart_clean_arch_linter.py <project_path>/lib/features/<feature>

# Strict mode — exits 1 on violations (for CI / pre-commit)
python3 <skill_base>/scripts/dart_clean_arch_linter.py --strict

# Subset of rules
python3 <skill_base>/scripts/dart_clean_arch_linter.py --rules naming_file,naming_class,inline_callbacks

# JSON output (for programmatic consumption)
python3 <skill_base>/scripts/dart_clean_arch_linter.py --json

# Ignore specific rules (only when the user explicitly requests)
python3 <skill_base>/scripts/dart_clean_arch_linter.py --ignore magic_numbers,magic_strings

# Skip project folders for one run (relative to the project root, globs allowed)
python3 <skill_base>/scripts/dart_clean_arch_linter.py --ignore-paths 'lib/features/*/presentation/routes'
```

The `path` positional argument is optional: omit it (or pass `lib`) for the whole project, or pass a single feature folder to narrow the scope. All flag combinations (`--strict`, `--rules`, `--json`, `--ignore`, `--ignore-paths`) work with either target.

**Ignored paths.** Folders and files that are not part of the Flutter layers (for example the HTTP server folders, `rules/http/serving_http.md`) are listed in a hidden `.clean_arch_ignore`: one path per line, relative to the project root, globs allowed, `#` for comments. The linter does not see them at all — no file rules, no `folder_naming`. It reads two files and adds `--ignore-paths`:

- `<project>/.clean_arch_ignore` — local, next to `pubspec.yaml` (commit it with the project);
- `<skill_base>/.clean_arch_ignore` — global, for every project.

```
# .clean_arch_ignore
lib/core/presentation/routes
lib/features/*/presentation/routes
lib/features/*/presentation/dto
```

Add a path only when the user asks for it or when a reference says so — never to silence a violation.

**30 rules:** `naming_file`, `naming_class`, `magic_numbers`, `magic_strings`, `magic_colors`, `widget_helpers`, `inline_callbacks`, `import_violation`, `setstate_usage`, `stateful_no_lifecycle`, `dartdoc_public`, `no_state_in_di`, `widget_stateless`, `watching_widget`, `no_controller_in_ui`, `static_const_order`, `no_build_return`, `folder_naming`, `async_gap_context_mounted`, `widget_key_parameter`, `controller_lifecycle`, `widget_methods`, `stateless_with_controllers`, `static_const_in_state_class`, `magic_numbers_in_layout`, `theme_import`, `value_listenable_exposure`, `watch_order`, `controller_naming`, `controller_no_actions`.

All rules are enabled by default. Only disable a rule with `--ignore` when the user explicitly requests it.
