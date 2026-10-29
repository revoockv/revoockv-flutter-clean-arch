# Git rules (any project)

## Branch strategy

```
main           ← stable, always runnable, tagged with releases
├── hotfix/009-crash-on-start   ← urgent fix of a released version
├── release/1.3.0               ← preparing a release: version, changelog, fixes
└── develop    ← integration branch, next release
       ├── feature/001-user-profile
       ├── feature/002-offline-cache
       ├── fix/004-state-leak
       └── refactor/005-extract-logic
```

### Branch types

| Prefix | Use for |
|---|---|
| `feature/<num>-<name>` | New capability |
| `fix/<num>-<name>` | Bug fix |
| `refactor/<num>-<name>` | Restructure, no behavior change |
| `docs/<num>-<name>` | Documentation changes |
| `test/<num>-<name>` | Add or fix tests |
| `style/<num>-<name>` | Formatting, linting, no logic change |
| `hotfix/<num>-<name>` | Urgent fix of the released version on `main` — see "Hotfix branches" |
| `release/<version>` | Preparing a release: version number, changelog, dependency updates, build/CI settings, fixes found while testing it — see "Release branches" |

### Branch naming

- `<num>` is the task number: the issue/ticket number of your tracker, or a running counter when the project has no tracker.
- Zero-padded to 3 digits (`001`, `002`, …); beyond 999 it simply grows (`1000`, `1001`, …).
- `<name>` is short kebab-case.
- A release branch has no number and no name: `release/<version>` (`release/1.3.0`).

### Branch flow

1. Create the branch from `develop`: `git switch -c feature/001-user-profile develop`
2. Work and commit on the branch.
3. When done, merge into `develop` with a merge commit in the commit format:
   ```bash
   git switch develop
   git merge --no-ff feature/001-user-profile -m "[FEAT-001] merge user profile into develop"
   ```
4. Delete the branch: `git branch -d feature/001-user-profile`
5. When `develop` is ready for a release, create a release branch — see "Release branches". `develop` is never merged into `main` directly.

`--no-ff` always creates the merge commit, so its message follows the commit format, and `git log --grep="FEAT-001"` finds the work commits and the merge. Never keep Git's default `Merge branch '…'` message.

### Release branches

A release is prepared on its own branch, so `develop` keeps taking features for the next version meanwhile:

```
develop ──●──●──●──────────────────────────●── (next features)
              \                            ↑ 5. merge back
               release/1.3.0 ──●──●──●─────┤
                                           ↓ 4. merge + tag v1.3.0
main ──────────────────────────────────────●
```

1. When `develop` has everything for the release: `git switch -c release/1.3.0 develop`
2. On the branch — only release work, no new features:
   - `[RELEASE-1.3.0] bump version to 1.3.0+13` (`version:` in `pubspec.yaml`)
   - `[RELEASE-1.3.0] update changelog`
   - `[RELEASE-1.3.0] update get_it to 9.4.0` — dependency updates (`python3 <skill_base>/scripts/check_versions.py --update`), build and CI settings: they are tested together with the release, so there is no separate branch type for them
   - `[RELEASE-1.3.0] fix …` — bugs found while testing the release
3. Meanwhile features keep going into `develop` for the next version.
4. Merge into `main` and tag:
   ```bash
   git switch main
   git merge --no-ff release/1.3.0 -m "[RELEASE-1.3.0] merge into main"
   git tag -a v1.3.0 -m "v1.3.0"
   ```
5. Merge back into `develop`, so the version and the fixes reach it too:
   ```bash
   git switch develop
   git merge --no-ff release/1.3.0 -m "[RELEASE-1.3.0] merge into develop"
   ```
6. Delete the branch: `git branch -d release/1.3.0`

### Hotfix branches

For an urgent fix of the released version when `develop` already contains unreleased work. A hotfix starts from `main`, not from `develop`, and goes back into **both**:

1. Create the branch from `main`: `git switch -c hotfix/009-crash-on-start main`
2. Fix and commit: `[HOTFIX-009] fix crash on start without network`, then bump the PATCH version: `[HOTFIX-009] bump version to 1.3.1+14`
3. Merge into `main` and tag with the PATCH bumped (`v1.3.0` → `v1.3.1`):
   ```bash
   git switch main
   git merge --no-ff hotfix/009-crash-on-start -m "[HOTFIX-009] merge crash on start fix into main"
   git tag -a v1.3.1 -m "v1.3.1"
   ```
4. Merge `main` into `develop`, so the next release does not bring the bug back:
   ```bash
   git switch develop
   git merge --no-ff main -m "[HOTFIX-009] merge v1.3.1 into develop"
   ```
5. Delete the branch: `git branch -d hotfix/009-crash-on-start`

A bug found in `develop` (not released yet) is a normal `fix/` branch from `develop`.

---

## Commit messages

Format:

```
[TYPE-NUM] short description
```

### Types

| Type | Use for |
|---|---|
| `FEAT` | New capability |
| `FIX` | Bug fix |
| `REFACTOR` | Restructure, no behavior change |
| `DOCS` | README, comments, changelog |
| `TEST` | Add or fix tests |
| `STYLE` | Formatting, linting, no logic change |
| `HOTFIX` | Urgent fix of a released version (`hotfix/` branch) |
| `RELEASE` | Release preparation on a `release/` branch — version, changelog, dependencies, build/CI: `[RELEASE-1.3.0] …`, the version instead of a number |

### Rules

- One logical change per commit.
- Imperative mood: "add", "fix", "extract" — not "added", "fixes", "extracting".
- Subject line of about 72 characters at most.
- No messages like "fix", "wip", "stuff", "update".
- `NUM` equals the number of the branch; on a `release/` branch it is the version (`[RELEASE-1.3.0]`).
- Merge commits follow the same format (`git merge --no-ff … -m "[TYPE-NUM] merge …"`).
- **The type matches the branch prefix, not the nature of the single commit.** On `feature/003-…` every commit is `FEAT-003`, even one that fixes a bug found during the work. `FIX` is used only on `fix/` branches, `REFACTOR` only on `refactor/` branches, and so on.

### Examples

```
[FEAT-001] add user profile entity
[FEAT-001] add profile repository
[FEAT-001] wire up DI for profile
[FEAT-003] fix cache invalidation on logout
[FIX-004] fix subscription leak in repository
[REFACTOR-005] extract validation into use case
[DOCS-006] describe offline mode in README
[TEST-007] add repository tests
[STYLE-008] apply dart format
[HOTFIX-009] fix crash on start without network
[FEAT-001] merge user profile into develop
[RELEASE-1.3.0] bump version to 1.3.0+13
[RELEASE-1.3.0] merge into main
```

### Common mistake

```
// WRONG — on feature/003-offline-cache:
[FIX-003] fix cache invalidation      ← the type must follow the branch

// CORRECT:
[FEAT-003] fix cache invalidation     ← "fix" in the description is fine
```

### Find the commits of a task

```bash
git log --oneline --grep="FEAT-001"
```

---

## Tags

Tags mark permanent, named points in history.

### When to tag

On `main` only, right after merging a `release/` or `hotfix/` branch (see above). The tag equals the version in `pubspec.yaml` without the build number: `version: 1.3.0+13` → `v1.3.0`.

```bash
git switch main
git tag -a v0.1.0 -m "First runnable version"
```

Always use annotated tags (`-a`): they store author, date and message.

### Versioning

Semantic versioning `v<major>.<minor>.<patch>`:

| Change | Bump |
|---|---|
| Breaking change | MAJOR |
| New feature | MINOR |
| Bug fix, hotfix | PATCH |

### Common commands

```bash
git tag -l                 # list tags
git tag -l "v0.*"          # list tags by pattern
git show v0.1.0            # what a tag points to
git checkout v0.1.0        # check out a tagged state
git diff v0.1.0 v0.2.0     # changes between versions
```

---

## Pre-commit checklist

Any project:
- [ ] no secrets, API keys or tokens in code or config
- [ ] no generated or local-only files (build output, IDE/tool folders, platform folders the project does not target)

A Flutter project built with this skill, in addition:
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] the architecture linter passes (`python3 <skill_base>/scripts/dart_clean_arch_linter.py --strict`)
