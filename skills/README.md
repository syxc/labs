# Skills

Alma / Claude Code / 其他 AI agent 的快捷提示（prompt template）集合。

## 结构

```
skills/
└── <skill-name>/
    └── SKILL.md    # prompt 模板（YAML frontmatter + 正文）
```

每个 skill 是一个独立目录，核心文件为 `SKILL.md`。Alma 通过 symlink 加载 `~/.config/alma/skills/` 下的目录。

## 使用

### Alma

将 skill 目录 symlink 到 `~/.config/alma/skills/`：

```bash
ln -s $HOME/Workspace/labs/skills/<skill-name> ~/.config/alma/skills/<skill-name>
```

在聊天中输入 `/review` 即可调用。

### Claude Code

将 skill 目录 symlink 到 `~/.claude/skills/` 或项目的 `.claude/skills/`。

## Skill 列表

| Skill | 说明 | 来源 Prompt |
|-------|------|-------------|
| [review](review/) | 结构化代码审查：正确性、回归、边界、测试、安全、性能 | "Review all changes in this worktree. Focus on correctness, regressions, edge cases, and missing tests. List concrete issues first, then note residual risks." |

## 新增 Skill

1. 在 `skills/` 下创建同名目录和 `SKILL.md`
2. `SKILL.md` 需包含 YAML frontmatter（`name`, `description`）
3. 正文记录 source prompt 和模板内容
4. 更新本 README 的 Skill 列表
5. 如需 Alma 使用，创建 symlink
