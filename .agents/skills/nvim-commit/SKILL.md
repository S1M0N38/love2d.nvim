---
name: nvim-commit
description: >
  Create conventional commits for love2d.nvim that are compatible with release-please
  and follow SemVer. Use when the user asks to commit changes, make a git commit,
  or says "/commit" while working on love2d.nvim. Analyzes the diff to produce
  correctly scoped, typed commit messages that release-please can parse into
  changelog entries and semantic version bumps.
license: MIT
allowed-tools: Bash
---

# love2d.nvim Conventional Commits

Create semantic git commits for love2d.nvim that release-please can parse into
changelog sections and correct version bumps.

## Why this matters

release-please scans commit messages to decide what goes in the CHANGELOG and whether
to bump the patch, minor, or major version. A poorly scoped or mistyped commit either
gets ignored or ends up in the wrong changelog section.

## Conventional Commit Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

The scope is always present — Neovim plugins benefit from always scoping because
modules are small and tightly named.

## Commit Types and SemVer Impact

| Type       | Purpose                          | Version Bump | Changelog Section |
| ---------- | -------------------------------- | ------------ | ----------------- |
| `feat`     | New feature or capability        | minor        | Features          |
| `fix`      | Bug fix                          | patch        | Bug Fixes         |
| `perf`     | Performance improvement          | patch        | Performance       |
| `refactor` | Code restructuring (no behavior) | none         | (omitted)         |
| `docs`     | Documentation only               | none         | (omitted)         |
| `style`    | Formatting, whitespace (no logic)| none         | (omitted)         |
| `test`     | Add or update tests              | none         | (omitted)         |
| `build`    | Build system, dependencies       | none         | Build             |
| `ci`       | CI configuration                 | none         | CI                |
| `chore`    | Maintenance, tooling, meta       | none         | (omitted)         |
| `revert`   | Revert a previous commit         | varies       | Reverts           |

## Scopes for love2d.nvim

The scope identifies the module or area that changed.

### Auto-detecting scope from file paths

| File Path Pattern                        | Scope       |
| ---------------------------------------- | ----------- |
| `lua/love2d/init.lua`                    | `init`      |
| `lua/love2d/config.lua`                  | `config`    |
| `lua/love2d/job.lua`                     | `job`       |
| `lua/love2d/output.lua`                  | `output`    |
| `lua/love2d/events.lua`                  | `events`    |
| `lua/love2d/autocmd.lua`                 | `autocmd`   |
| `lua/love2d/lsp.lua`                     | `lsp`       |
| `lua/love2d/health.lua`                  | `health`    |
| `lua/love2d/utils.lua`                   | `utils`     |
| `lua/love2d/types.lua`                   | `types`     |
| `plugin/love2d.lua`                      | `plugin`    |
| `compiler/love.lua`                      | `compiler`  |
| `doc/love2d.txt`                         | `docs`      |
| `README.md`                              | `docs`      |
| `tests/*_spec.lua`                       | omit scope  |
| `after/queries/lua/injections.scm`       | `injections`|
| `after/syntax/*`                         | `syntax`    |
| `libraries/love2d/*`                     | `library`   |
| `libraries/luasocket/*`                  | `library`   |
| `.github/workflows/*`                    | `ci`        |
| `.stylua.toml`, `.luarc.json`            | omit scope  |

When multiple files span different scopes, pick the scope of the primary change.

### Scope style

- Lowercase, no hyphens or underscores
- Examples: `config`, `init`, `plugin`, `injections`, `library`

## Breaking Changes

Signal with `!` after the type/scope:

```
feat(config)!: rename `disabled` to `enabled`

BREAKING CHANGE: `disabled` option renamed to `enabled` with inverted logic.
```

## Workflow

### 1. Analyze the diff

```bash
# Staged changes
git diff --staged

# If nothing staged, check working tree
git diff

# File list for scope detection
git diff --name-only --staged || git diff --name-only
```

### 2. Stage files if needed

If nothing is staged, check `git status --porcelain` and stage the changed files.
Group logically related changes together.

**Never commit**: secrets, `.env`, credentials, private keys.

### 3. Determine type, scope, and description

- **Type**: based on the nature of the change
- **Scope**: auto-detect from the file paths using the table above
- **Description**: one line, present tense, imperative mood, under 72 characters

### 4. Execute the commit

```bash
# Single line
git commit -m "feat(config): add output option for panel configuration"

# With body
git commit -m "$(cat <<'EOF'
feat(config): add makeprg support for LÖVE projects

Automatically configure makeprg and errorformat when a LÖVE
project is detected, allowing :make to run and parse errors.
EOF
)"
```

## Writing good descriptions

- Present tense, imperative mood: "add option" not "added option"
- Start with lowercase after colon: `feat(config): add debounce helper`
- Be specific: "add `output` option" beats "add new option"
- Keep under 72 characters
- Don't end with a period

## What to avoid

- Don't use `chore` for actual code changes — it won't appear in the changelog
- Don't combine multiple unrelated changes in one commit
- Don't use generic scopes like `core` or `misc`
- Don't reference issue numbers in the subject line

## Git Safety

- Never update git config
- Never run destructive commands (`--force`, hard reset) without explicit request
- Never skip hooks (`--no-verify`) unless asked
- Never force push to main/master
