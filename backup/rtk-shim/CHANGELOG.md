# Changelog

## 2026-07-12（NewMax 1.1.2）

| 项 | 修复 |
|----|------|
| A | `basename` → `${0##*/}`，消除热路径 fork |
| B | rtk 路径硬编码 → 裸名 PATH 解析 |
| C | 47 份全拷贝 → 单一数据源（symlink → `_dispatch`） |
| D | git/gh 写操作豁免 |
| E | 分流守卫收敛为仅 `CLAUDE_CONFIG_DIR` |
| F | git 豁免补 `reset`/`checkout`/`switch`/`branch`/`pull` |
| G | gh 豁免改按 action（第 2 个非 flag token）判断 |
| H | README 文档校正 |
| **P0** | 🔴 cat 安全网关：`rtk read` 不读 stdin，原方案 `cat > file` 会清空目标；修后无参/未知 flag → 真 cat |
| **P1** | 🔴 git 跳过全局 flag（`-C`/`-c`），`git -C path commit` 仍豁免 |
| **P2** | 🟠 gh 跳过全局 flag（`-R`/`--repo`）定位 action，豁免补 `upload` |

**已知边界**（代码内 `ponytail:` 注释）：

- `git --gitdir /p commit`（空格分隔）误判；`=` 形式正常
- gh 通用 flag 带值未穷举
- `git tag`/`config` 等非破坏性写操作走 rtk
- rtk 对未注册命令（eza/fd/bat/jq/node...）走通用代理，已测正常

验证：假 rtk 拦截器矩阵 + 真 rtk 端到端（25+ 用例）。
