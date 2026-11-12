# Template constructor

How to make, change, version and choose an architecture template. Read this only when the task is about templates
themselves; building an app needs only the project's template (`SKILL.md`).

## 1. What a template is

```
templates/
  index.toml                    default = "name@version"
  <name>/
    CHANGELOG.md                the template's versions
    <version>/                  MAJOR.MINOR.PATCH; a released version is never changed
      template.toml             choices, topic → rule files, folders, core files, example, lint
      rules/<topic>/*.md        the rules, one subject per file
      scaffold/                 stub files init_feature writes (app/, feature/, subfeature/)
      example/                  a project built with every rule; selfcheck verifies it
```

A project chooses its template in `.clean_arch.toml` next to `pubspec.yaml` (`template = "name@version"`, or
`"name"` for its newest version); without it the default of `templates/index.toml` applies.

## 2. What a template decides

Every subject below is the template's choice. Answer each in one line in `[choices]`, give the details in the rule
file of its topic. A subject the new template does the same way as its source stays as copied.

| Topic | Decide |
|---|---|
| `structure` | layers and their folders (`[structure]`); what `lib/core` holds; where features and subfeatures live; where the app state lives |
| `state` | state manager (watch_it, Bloc/Cubit, Riverpod, Provider, signals…); what owns domain state and what owns UI state; what widgets may do; how they read state and react to it; `setState` / `StatefulWidget` allowed or not |
| `di` | how dependencies are created and found: a container (GetIt), the widget tree (`RepositoryProvider`, `Provider`, Riverpod providers) or by hand; registration style; startup work; disposal. It follows from the state manager |
| `use_cases` | use cases required or not; their shape (`call()`, class or function); what they return: `Future<Result<T>>`, `ValueListenable<T>`, `Stream<T>` |
| `errors_models` | the result type (own sealed `Result`, `Either`, exceptions); failure kinds; DTO ↔ entity mapping; JSON by hand or generated; equality |
| `style` | naming of files, classes, use cases, controllers; constants and magic values; imports; dartdoc; logging; Dart idioms |
| `testing` | what is tested on each layer; fakes or mocks; widget tests; test DI |
| `git` | branch types and names, commit and merge messages, subject length, what happens to merged branches, releases, tags |
| `packages` | pinned packages and the SDK |
| `workflow`, `decisions` | the order of work for a new feature, a refactor, a migration; quick "you need X → do Y" answers |
| `example_feature`, `http` | optional: a worked feature in the rules, serving use cases over HTTP |

## 3. template.toml

| Section | What it holds |
|---|---|
| `name`, `version`, `description`, `author` | The template; `name` and `version` equal its folders |
| `[choices]` | One short answer per subject; the agent reads them first |
| `[rules]` | Topic → rule files (relative to the version folder). Topics of section 2; a template may add its own |
| `[structure]` | Layer → folders of every feature and of `lib/core`: `init_feature` creates them, the linter's `folder_naming` checks them |
| `[scaffold]` | `core_files` that `init_feature --core` copies from the example; `next_step` printed after `--feature`. Stub files are in the version folder's `scaffold/app/` (under `lib/` with `--core`), `scaffold/feature/` and `scaffold/subfeature/` (under the feature) as `*.tmpl`, with `{{feature}}`, `{{Feature}}`, `{{subfeature}}`, `{{Subfeature}}`, `{{package}}` filled in |
| `[example]` | `path`, `package`; `docs_package` (package name in the rules' imports); `doc_paths` (code blocks of the rules compiled in the example), `same_as_example` (blocks that must equal the example's files), `doc_feature` (a feature that lives only in the rules) |
| `[lint]` | `off` — rules the template does not use; `warn` — rules shown as warnings (`--strict` does not fail on them) |
| `[lint.params]` | `allowed_numbers`, `theme_file` (relative to `lib/`), `layout_name_words`, `use_case_imports_in` (presentation folders that may import use cases) |
| `[packages]` | `tracked` — packages `check_versions.py` compares with pub.dev |

## 4. Make a template

1. `python3 scripts/templates.py new <name> --from <source>@<version>` — copies the source as `<name>/1.0.0`.
2. `[choices]` first: change the answers that differ, then `[structure]`, `[scaffold]`, `[lint]`.
3. Rewrite the rule files of the changed topics; delete files and topics the template does not use (and their entries in
   `[rules]`).
4. Rebuild `example/` by the new rules: the same app (notes: list, add, delete; tests on every layer) so templates can
   be compared. Pin its packages in `example/pubspec.yaml` and `rules/packages/packages.md`.
5. Run the linter on the example; for each rule that fires decide: the example breaks the template's rules (fix the
   example) or the rule does not fit the template (put it in `[lint] off`, say why in a comment).
6. `python3 scripts/templates.py validate <name>` and `python3 scripts/selfcheck.py --template <name>@1.0.0`.
7. Optional: `templates.py set-default <name>@1.0.0`, or `templates.py use <name> --project <path>` per project.

## 5. Write rules that cost little context

- One subject per file, at most ~250 lines (`validate` warns above).
- State a rule once, in the file of its topic; other files link to it.
- Do not copy code that is in the example: write `example/<path>` and the reader opens it when needed
  (`selfcheck` checks that every such path exists). Code in the rules only for what the example does not show.
- Put the short answer first (`[choices]`, `decisions.md`), the reasons and edge cases after.

## 6. Change and version a template

- `python3 scripts/templates.py bump <name> --to X.Y.Z` copies the newest version; change the copy, describe it in
  `templates/<name>/CHANGELOG.md`, run the self-check. Projects pinned to the old version keep it.
- MAJOR: a rule change that makes existing code wrong; MINOR: a new rule or topic that old code still meets; PATCH:
  wording and fixes.
- The skill has its own versions (`CHANGELOG.md` in the skill root): a change of the scripts or of this constructor is
  a skill change; a change of rules is a template change.

## 7. The linter and other state managers

The linter's rules were written with watch_it + `ValueNotifier`. Tried on `revoockv-bloc`, these check that model and
are off in templates without it: `watching_widget`, `watch_order`, `value_listenable_exposure`, `no_state_in_di`,
`no_controller_in_ui`. `import_violation` stays on — it keeps widgets away from repositories and the data layer — and
`[lint.params] use_case_imports_in` lists the presentation folders that may import use cases (`["blocs", "pages"]`
there). The other rules (names, folders, magic values, dartdoc, widget shape, `setState`, controller lifecycle,
`context.mounted`, theme) are general.

## 8. Commands

| `scripts/templates.py …` | What it does |
|---|---|
| `list` | Every template version, the default marked |
| `show [REF] [--project P]` | Choices, folder and topics with their sizes |
| `rules [REF] --topic a,b` | Paths of the rule files of topics |
| `use REF --project P` | The project uses REF (writes `P/.clean_arch.toml`) |
| `set-default REF` | The template of projects that choose none |
| `new NAME --from REF` | A new template (1.0.0) copied from REF |
| `bump NAME --to X.Y.Z` | A new version from the newest one |
| `validate [REF \| --all]` | Keys, files, sizes, lint rules and params |
