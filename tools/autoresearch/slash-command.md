---
description: Start or resume an autonomous experiment loop for optimization
---

# /autoresearch [goal]

Start or resume an autonomous experiment loop. The agent iteratively tries ideas, keeps what works, discards what doesn't, and tracks everything in `autoresearch.jsonl`.

## Usage

```
/autoresearch                           # Resume existing session (if autoresearch.md exists)
/autoresearch optimize unit test speed   # Create new session with given goal
/autoresearch finalize                  # Finalize session into reviewable branches
/autoresearch dashboard                 # Show experiment dashboard
/autoresearch clear                     # Clear all autoresearch state and exit mode
```

Use the autoresearch skill to set up and run the loop.
