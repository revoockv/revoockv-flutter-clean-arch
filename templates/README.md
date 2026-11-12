# Templates

A template is one way to build a Flutter app: its folders, state manager, DI, use cases, errors, models, code style,
tests and git rules. The agent reads a template's `template.toml` first, then only the rule files a task needs.

```
templates/
  index.toml                    default = "name@version"
  <name>/
    CHANGELOG.md                the template's versions
    <version>/                  MAJOR.MINOR.PATCH; released versions are not changed
      template.toml             choices, topic → rule files, folders, core files, example, lint
      rules/<topic>/*.md        the rules, one subject per file
      example/                  a project built with every rule; selfcheck verifies it
```

A project chooses its template in `.clean_arch.toml` next to `pubspec.yaml`:

```toml
template = "revoockv-original@1.0.0"   # or "revoockv-original" for its newest version
```

## template.toml

| Section | What it holds |
|---|---|
| `name`, `version`, `description`, `author` | The template; `name` and `version` equal its folders |
| `[choices]` | One short answer per subject (state manager, where app state lives, what use cases return, DI, …). The agent reads them first; the rule files say the details |
| `[rules]` | Topic → rule files. Fixed topics the skill knows: `workflow`, `decisions`, `structure`, `state`, `di`, `use_cases`, `errors_models`, `style`, `testing`, `git`, `packages`, `example_feature`, `http`; a template may add its own |
| `[structure]` | Layer → folders of every feature and of `lib/core` (`init_feature` creates them) |
| `[scaffold]` | `core_files` that `init_feature --core` copies from the example |
| `[example]` | `path`, `package`; `docs_package` used in the rules' imports; `doc_paths` (code blocks compiled in the example), `same_as_example` (blocks that must equal the example's files), `doc_feature` (a feature that lives only in the rules) |
| `[lint]` | `off` — linter rules this template does not use |

## Make your own template

1. `python3 scripts/templates.py new my-arch --from revoockv-original@1.0.0`
2. Change `template.toml` (`[choices]` first) and the rule files of what you do differently. Keep every file short and on
   one subject: a file over 250 lines makes `validate` warn.
3. Rebuild `example/` by the new rules (ask the agent: "build the example of my-arch by its rules").
4. `python3 scripts/templates.py validate my-arch` and `python3 scripts/selfcheck.py --template my-arch@1.0.0`.
5. Optional: `templates.py set-default my-arch@1.0.0`; contribute it to the skill repository with a pull request.

To change a template later: `templates.py bump my-arch --to 1.1.0`, change the new folder, describe it in
`templates/my-arch/CHANGELOG.md`, run the self-check. Projects pinned to the old version keep it.

The linter's rules are written for watch_it + ValueNotifier. A template with another state manager turns the rules
that do not apply off in `[lint] off`; the general rules (names, magic values, imports, dartdoc, …) still check it.
