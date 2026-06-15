# Agent Skills

共 20 个 skills，来源数据来自 `.skill-lock.json`。

---

## 来源索引

| Skill | Source | Author |
|-------|--------|--------|
| agent-browser | vercel-labs/agent-browser | Vercel |
| caveman | mattpocock/skills | @mattpocock |
| commit | 自编 (skill.md) | — |
| check | tw93/waza | @tw93 |
| design | tw93/waza | @tw93 |
| ducksearch | 自编 (skill.md) | — |
| find-skills | vercel-labs/skills | Vercel |
| ghr | 自编 (syxc/gh-repo-cli) | — |
| github | mitsuhiko/agent-stuff | @mitsuhiko |
| handoff | mattpocock/skills | @mattpocock |
| hunt | tw93/waza | @tw93 |
| ponytail | dietrichgebert/ponytail | @dietrichgebert |
| ponytail-audit | dietrichgebert/ponytail | ← |
| ponytail-debt | dietrichgebert/ponytail | ← |
| ponytail-help | dietrichgebert/ponytail | ← |
| ponytail-review | dietrichgebert/ponytail | ← |
| review | mattpocock/skills | @mattpocock |
| skill-creator | anthropics/skills | Anthropic |
| vercel-react-best-practices | vercel-labs/agent-skills | Vercel |
| write | tw93/waza | @tw93 |

---

## 安装

```bash
# tw93/waza
npx skills add tw93/waza -s check -s design -s hunt -s write -g -y

# mattpocock/skills
npx skills add mattpocock/skills -s caveman -s handoff -s review -g -y

# dietrichgebert/ponytail
npx skills add dietrichgebert/ponytail -g -y

# 其他独立包
npx skills add vercel-labs/agent-skills -s vercel-react-best-practices -g -y
npx skills add vercel-labs/agent-browser -s agent-browser -g -y
npx skills add mitsuhiko/agent-stuff -s github -g -y
npx skills add anthropics/skills -s skill-creator -g -y
```

## 移除

```bash
# 单个
npx skills remove -g -s <skill> -y

# 整包
npx skills remove -g -s ponytail -s ponytail-audit -s ponytail-debt -s ponytail-help -s ponytail-review -y
```
