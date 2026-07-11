# rtk-shim

PATH shim 让 shell 命令自动经 RTK 压缩，**仅对 NewMax 中的 Claude Code 生效**。

## 工作原理

```
用户命令 → rtk-shim/<cmd> (symlink → _dispatch) → 环境检查 → 走 RTK 或透传
```

**激活条件**（全部满足）：
- `CLAUDE_CONFIG_DIR` 包含 `.newmax`（标识 NewMax 环境）
- `RTK_SHIM_ACTIVE` 未设置（防递归）

**不满足条件时**：动态查找 PATH 中下一个同名可执行文件，透传执行。

## 为什么仅对 NewMax 生效

本机 Claude Code CLI 完美支持 RTK hooks，无需 shim。通过检查 `CLAUDE_CONFIG_DIR` 区分：

| 环境 | `CLAUDE_CONFIG_DIR` | 行为 |
|------|---------------------|------|
| NewMax | `/Users/syxc/.newmax` | 拦截 → RTK |
| 本机 Claude Code | `/Users/syxc/.claude` | 透传 → 原生 |

## 架构

单一数据源设计——所有逻辑集中在 `_dispatch`，46 个命令名均为指向 `_dispatch` 的 symlink：

```
rtk-shim/
  _dispatch      ← 唯一逻辑主体
  ls → _dispatch ← symlink
  git → _dispatch
  cat → _dispatch
  ...
```

每次调用时 `_dispatch` 通过 `${0##*/}` 获取命令名，零 fork 开销。

## 覆盖范围

46 个命令（覆盖 RTK 支持的所有已安装工具）：

| 类别 | 命令 |
|------|------|
| 文件/目录 | ls, cat, find, tree, wc, eza, fd, bat |
| Git | git, gh |
| 搜索 | grep, rg, fzf |
| 差异 | diff, delta |
| 容器 | docker, kubectl |
| 数据库 | psql, mysql, sqlite3 |
| 构建 | make, cmake, cargo, go, swift, xcodebuild, golangci-lint, zig |
| JS/TS | node, npm, npx, pnpm, yarn, bun, deno, tsc |
| Python | uv, pipx |
| Ruby | ruby, rails, rake |
| 其他 | curl, wget, jq, mise, playwright |

特殊映射：
- `cat` → `rtk read`（rtk read 只读文件参数、不读 stdin）。**安全网关**：无参数（`cat`/`cat > f`/heredoc/管道）、显式 `-`、或带 rtk read 不支持的 flag（`-A`/`-s`/`-b` 等）时透传真 cat——否则 `cat > file` 会被 rtk read 的空输出清空目标文件。仅 `cat file`/`-n`/多文件走 rtk read 压缩。
- `git` 写/破坏性操作 → 透传原生，不走 RTK（对照 CLAUDE.md 破坏性清单）：`commit|push|rebase|merge|revert|cherry-pick|clean|restore|rm|mv|stash|bisect|reset|checkout|switch|branch|pull`。**跳过全局 flag**（`-C <dir>`/`-c <k=v>`）定位真子命令，使 `git -C path commit` / `git -c k=v push` 仍豁免。
- `gh` 写操作 → 跳过全局 flag（`-R`/`--repo`/`--hostname`）取第 2 个非 flag token 作为 action 判断豁免：`create|delete|rename|merge|close|reopen|review|edit|rerun|login|logout|upload`（gh 格式为 `[全局flag] <entity> <action>`）
- 只读操作（`git log/status/diff`、`gh pr list`、`gh repo view` 等）仍走 RTK 压缩

## 两层守卫

PATH 注入与命令分流在不同层级，依赖不同环境变量：

| 层级 | 位置 | 触发条件 | 作用 |
|------|------|----------|------|
| PATH 注入 | `~/.zshenv` / `~/.zprofile` | `CLAUDECODE=1` | 决定 rtk-shim 是否进入 PATH |
| 命令分流 | `_dispatch` 内 | `CLAUDE_CONFIG_DIR` 含 `.newmax` | 决定命令走 RTK 还是透传真命令 |

`~/.zshenv`（仅 `CLAUDECODE=1` 时前置，不影响交互终端）：
```sh
if [ "$CLAUDECODE" = "1" ]; then
  case ":$PATH:" in
    *":$HOME/.newmax/rtk-shim:"*) ;;
    *) export PATH="$HOME/.newmax/rtk-shim:$PATH" ;;
  esac
fi
```

`~/.zprofile`（login shell 末尾去重再前置，确保顺序在 PATH 操作之后仍居首）：
```sh
if [ "$CLAUDECODE" = "1" ]; then
  PATH=$(echo "$PATH" | sed "s|$HOME/.newmax/rtk-shim:||g")
  export PATH="$HOME/.newmax/rtk-shim:$PATH"
fi
```

## 动态 fallback

`_dispatch` 遍历 PATH 查找下一个可执行文件，不硬编码路径：

```sh
for _d in $PATH; do
  case "$_d" in *rtk-shim*) continue ;; esac
  [ -x "$_d/$_name" ] && exec "$_d/$_name" "$@"
done
```

mise 管理的工具（npm/npx/tsc 等）卸载后自动跳过，不会报错。

## 验证

`_dispatch` 只认 `CLAUDE_CONFIG_DIR`（`CLAUDECODE` 是 PATH 注入层的开关，对分流无效）：

```sh
# NewMax 环境（CLAUDE_CONFIG_DIR=.newmax → 拦截走 RTK）
CLAUDE_CONFIG_DIR=/Users/syxc/.newmax ~/.newmax/rtk-shim/ls /tmp

# 本机 Claude Code（CLAUDE_CONFIG_DIR=.claude → 透传真命令）
CLAUDE_CONFIG_DIR=/Users/syxc/.claude ~/.newmax/rtk-shim/ls /tmp

# git 破坏性操作透传（reset 不走 RTK，显示原生 manpage）
CLAUDE_CONFIG_DIR=/Users/syxc/.newmax ~/.newmax/rtk-shim/git reset --help 2>&1 | head -1
```
