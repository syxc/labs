- Protection & deletion: first check whether the target sits in a version-controlled worktree
  (Git, SVN). Inside one, check status and preserve the user's changes; do not create side backups
  for tracked or untracked files. Outside one, create a timestamped backup only for files that
  existed before this task began; files this task creates and can rebuild need none. Prefer `trash`
  for deletion; use `rm -rf` only for directories that can be rebuilt.
- High-risk scope: uninstall/remove/reinstall of software, plugins, or packages; `--force`/`--reset`
  on state-changing commands; overwriting shell/Agent/IDE or system-level config; batch-modifying
  existing files that version control or a single command cannot reliably roll back.
- High-risk process: assess impact, prepare a restore basis, write the rollback command, and obtain
  confirmation (skip repeated confirmation when already authorized). Report format:
  `impact: <target + scope>; restore basis: <vcs state, version record, or backup path>;
  rollback: <command>; confirmed: <authorized or not>`.
- Forensics & validation: prefer non-destructive methods; after editing JSON, validate with
  `python3 -m json.tool <file>`; before an install/upgrade via a package or version manager, check
  the target directory, current version, and global install state.
- Commit only when asked. Review the staged diff and exclude sensitive files; if you find an
  unignored sensitive path, say so and update `.gitignore` only within the authorized scope. Run the
  repo's configured hooks; do not add Co-Authored-By to commits.
  Title: English `<scope>: <summary>`, scope required, verb-first, no type tag. Body uses real
  newlines, no literal `\n` or `\t`.
- Push only when asked; confirm remote, current branch, target branch, and pending commits first.
- Amend only the nearest unpushed commit, when asked. Amending a pushed commit, `reset --hard`,
  force push, `checkout .`, `restore .`, `clean -f`, and `branch -D` each require explicit
  authorization. Undo committed changes with `git revert`; uncommitted one with a reverse patch.