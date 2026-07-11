# NewMax RTK Shim 方案备份

NewMax 对 [RTK](https://github.com/rtk-ai/rtk) 的 PATH shim 适配快照。**NewMax 1.1.2** / 2026-07-12。

## 原理

bare 命令（`git`/`ls`/`cat`/...）在 NewMax 下自动经 RTK 压缩；本机 Claude Code 与交互终端不受影响。单一数据源：46 个 symlink → `_dispatch`，调用时 `${0##*/}` 取命令名，零 fork。

两层守卫：PATH 注入（`.zshenv`/`.zprofile`，门控 `CLAUDECODE=1`）＋ 命令分流（`_dispatch`，门控 `CLAUDE_CONFIG_DIR` 含 `.newmax`）。

## 部署

```sh
./install.sh                                 # 装回 ~/.newmax/rtk-shim/（旧目录自动备份）
# 再把 shell-config/ 两段合入 ~/.zshenv 和 ~/.zprofile
```

## 验证

```sh
CLAUDE_CONFIG_DIR=$HOME/.newmax ~/.newmax/rtk-shim/ls /tmp          # 经 RTK（压缩格式）
CLAUDE_CONFIG_DIR=$HOME/.claude ~/.newmax/rtk-shim/ls /tmp          # 透传（原生格式）
CLAUDE_CONFIG_DIR=$HOME/.newmax sh -c 'echo X|~/.newmax/rtk-shim/cat>/tmp/_t' && /bin/cat /tmp/_t  # → X
```

## 目录

- `snapshot/rtk-shim/` — `_dispatch`(755) ＋ `README.md` ＋ 46 symlinks
- `shell-config/` — `.zshenv` / `.zprofile` PATH 注入片段
- `install.sh` — 还原脚本
- `CHANGELOG.md` — 修复历史与已知边界

兼容：NewMax 1.1.2、RTK 0.43.0、`/bin/sh`(POSIX)。
