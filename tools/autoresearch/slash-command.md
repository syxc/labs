---
description: Start or resume an autonomous experiment loop for optimization
---

# /autoresearch [goal]

Start or resume an autonomous experiment loop. The agent iteratively tries ideas, keeps what works, discards what doesn't, and tracks everything in `autoresearch.jsonl`.

`[goal]` is free-form text — any description of what you want to optimize. It is NOT a fixed format or subcommand.

## Subcommands

| Command | Action |
|---------|--------|
| `/autoresearch <text>` | Create new session with `<text>` as goal |
| `/autoresearch` | Resume existing session (if `autoresearch.md` exists) |
| `/autoresearch dashboard` | Show experiment dashboard |
| `/autoresearch finalize` | Split into independent reviewable branches |
| `/autoresearch clear` | Delete all autoresearch state |

## Examples

```
/autoresearch reduce bundle size below 200kb
/autoresearch speed up Python text processing pipeline
/autoresearch model training loss ratio, run 5 minutes of train.py
```

Use the autoresearch skill to set up and run the loop.
