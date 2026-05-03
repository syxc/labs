---
name: review
description: "Structured code review prompt. Use when the user wants to review changes in a worktree, branch, or PR — or when you invoke /review as a shortcut."
---

# Review — Code Review Skill

## Source Prompt

Original prompt from [emdash.sh](https://emdash.sh):

> Review all changes in this worktree. Focus on correctness, regressions, edge cases, and missing tests. List concrete issues first, then note residual risks.

## Prompt Template

Use the following prompt when reviewing code changes. Replace `<scope>` as needed.

```
Review all changes in <scope> (default: this worktree).

## Review Checklist

- **Correctness** — logic errors, wrong assumptions, type mismatches, off-by-one, null/undefined paths
- **Regressions** — behavioral changes that break existing callers or consumers, API contract violations
- **Edge cases** — empty inputs, boundary values, concurrent access, error paths, platform-specific behavior
- **Missing tests** — uncovered branches, untested error paths, 缺少的边界用例
- **Security** — injection, credential leaks, privilege escalation, input validation gaps
- **Performance** — unnecessary allocations, O(n^2) where O(n) suffices, hot-path regressions

## Output Format

### Issues (ranked by severity)

For each issue:
- **Severity**: Critical / Major / Minor
- **Location**: file:line (or function name)
- **Description**: what's wrong and why it matters
- **Suggested fix**: concrete code or approach (not vague advice)

### Residual Risks

Items that aren't bugs but deserve attention:
- Design debt or coupling that may cause future pain
- Assumptions that could break under realistic conditions
- Areas where confidence is low due to missing context

### Summary

One-sentence verdict: ship it / ship after fixes / needs rework.
```

## Usage

In any chat, type:

```
/review
```

Or with a custom scope:

```
/review main..feature-branch
/review src/auth/
```

The default scope is the current worktree (`git diff`).
