- Commit only when asked. Disable `--no-verify` and `--no-gpg-sign` on commit. Review the staged
  diff and exclude sensitive files; if you find an unignored sensitive path, say so and update
  `.gitignore` only within the authorized scope. Run the repo's configured hooks; do not add Co-Authored-By to commits. Title: English `<scope>: <summary>`, scope
  required, verb-first, no type tag. Body uses real newlines, no literal `\n` or `\t`.
- Push only when asked; confirm remote, current branch, target branch, and pending commits first.
- Amend only the nearest unpushed commit, when asked. Amending a pushed commit, `reset --hard`,
  force push, `checkout .`, `restore .`, `clean -f`, and `branch -D` each require explicit
  authorization. Undo committed changes with `git revert`; uncommitted one with a reverse patch.