# Agent Skills

共 20 个 skills，来源数据来自 `.skill-lock.json`。

---

## 来源索引

| Skill | Source | Author |
|-------|--------|--------|
| agent-browser | vercel-labs/agent-browser | Vercel |
| caveman | mattpocock/skills | @mattpocock |
| commit | 自建 (skill.md) | — |
| check | tw93/waza | @tw93 |
| design | tw93/waza | @tw93 |
| ducksearch | 自建 (skill.md) | — |
| find-skills | vercel-labs/skills | Vercel |
| ghr | 自建 (syxc/gh-repo-cli) | — |
| github | mitsuhiko/agent-stuff | @mitsuhiko |
| handoff | mattpocock/skills | @mattpocock |
| hunt | tw93/waza | @tw93 |
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


# 其他独立包
npx skills add vercel-labs/agent-skills -s vercel-react-best-practices -g -y
npx skills add vercel-labs/agent-browser -s agent-browser -g -y
npx skills add mitsuhiko/agent-stuff -s github -g -y
npx skills add anthropics/skills -s skill-creator -g -y
```

## 移除

