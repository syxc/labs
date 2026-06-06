---
name: commit
description: "Create git commits and commit messages using scope-prefixed format — scope first, no type prefix."
alwaysAllow: ["Bash"]
---

# Commit

## Config

- **Co-Authored-By**: disabled
- **Do NOT push**, only commit

## Format

```
<scope>: <summary>

[body]
```

- `scope` **REQUIRED**. The module/subsystem affected. Infer from file paths and project git log.
- `summary` **REQUIRED**. Imperative mood, ≤72 chars, no trailing period, first word must be a verb.
- `body` **OPTIONAL**. Only when the WHY isn't obvious. Blank line before body.

No type prefix (no `feat`, `fix`, `chore`, etc.). The change type is obvious from the summary.

## Scope

Infer from **changed file paths** and **project git log** together:

```bash
git log --oneline -n 50
```

Check recent commits for existing scope conventions. Match them.

```
src/auth/middleware.ts       → auth
packages/parser/src/lex.ts   → parser
apps/web/pages/index.tsx     → web
internal/db/migrations/001   → db
README.md                    → docs
```

- Skip container dirs (`src/`, `lib/`, `app/`, `packages/`, `internal/`)
- One commit = one logical change. Keep scope focused.
- Comma-separate for truly cross-scope; `treewide` for whole-tree changes.

## Summary

- **Imperative, present tense**: `add` not `added`, `fix` not `fixed`
- **First word must be a verb**: add, fix, remove, update, refactor, move, rename, bump, revert
- **Describe WHAT**, not HOW (the diff already shows how)

```
+ auth: fix token refresh race condition
+ db: add user_preferences table migration

- fix(auth): token refresh    (type prefix noise)
- updated stuff               (no scope, past tense)
```

## Notes

- No `Signed-off-by`, `BREAKING CHANGE`, or other markers/footers.
- If unsure whether a file should be committed, **ask the user**.
- **NEVER** use literal `\n`, `\t` escape sequences in commit messages. Use actual newlines and indentation.

## Caller Arguments

Users may pass extra instructions. Handling rules:

| User input | Behavior |
|------------|----------|
| Freeform instructions | Influence scope, summary, and body |
| File paths / globs | Stage **only** specified files (unless explicitly told otherwise) |
| Files + instructions | Honor both |

## Workflow

1. Check if user specified file paths or globs
2. `git status` to see all changes
3. Stage files: `git add` specified files, or all changes if none specified
4. `git diff --staged` to review what will be committed
5. `git log --oneline -n 50` to learn existing scope conventions
6. Determine scope; match project conventions
7. If staged changes span multiple unrelated scopes, ask user about splitting
8. Ask user about ambiguous files
9. Write `<scope>: <summary>`; add body only when WHY isn't obvious
10. Commit:
    - No body: `git commit -m "<scope>: <summary>"`
    - With body: `git commit -m "<scope>: <summary>" -m "<body>"`
    - No Co-authored-by
11. Brief summary of what was committed
