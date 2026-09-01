- Protection & deletion: first check whether the target sits in a version-controlled worktree
  (Git, SVN). Inside one, check status and preserve the user's changes; do not create side backups
  for tracked or untracked files. Outside one, create a timestamped backup only for files that
  existed before this task began; files this task creates and can rebuild need none. Prefer `trash`
  for deletion to avoid a permission-confirmation prompt; use `rm -rf` only for directories that
  can be rebuilt.
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