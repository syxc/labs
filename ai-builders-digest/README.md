# AI Builders Digest

AI Builders 早报生成工具的配置备份。

## 文件说明

| 文件 | 说明 |
|------|------|
| `run-digest.sh` | 核心调度脚本，拉取 feed 数据并生成 LLM prompt |
| `config.json` | 本地配置（语言、时区、频率） |
| `prompts/digest-morning-briefing.md` | LLM prompt 模板，定义早报生成规则 |
| `scheduled-task-prompt.md` | 牛马 AI 定时任务的完整 prompt（用于恢复） |

## 环境变量

`run-digest.sh` 通过环境变量定位路径，支持自定义：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `FOLLOW_BUILDERS_REPO` | `$HOME/ai/niuma/follow-builders` | follow-builders 仓库本地路径 |
| `FOLLOW_BUILDERS_HOME` | `$HOME/.follow-builders` | 用户配置和缓存目录 |

## 致谢

Prompt 模板（`prompts/digest-morning-briefing.md`）基于 [kevinma2010 的 gist](https://gist.github.com/kevinma2010/d234e6239f54b7d1b1052dd04c3596b1) 改编。

## 依赖

- feed 数据来源：[zarazhangrui/follow-builders](https://github.com/zarazhangrui/follow-builders) 的本地 clone
- 博客仓库：[syxc/syxc.github.io](https://github.com/syxc/syxc.github.io) 的本地 clone
- 运行时：mise (node), python3

## 恢复步骤

1. 将文件复制到 `$FOLLOW_BUILDERS_HOME`：
   ```bash
   INSTALL_DIR="${FOLLOW_BUILDERS_HOME:-$HOME/.follow-builders}"
   cp config.json "$INSTALL_DIR/"
   cp run-digest.sh "$INSTALL_DIR/"
   mkdir -p "$INSTALL_DIR/prompts"
   cp prompts/digest-morning-briefing.md "$INSTALL_DIR/prompts/"
   ```
2. 确保依赖就绪（follow-builders 仓库已 clone、mise 已安装 node）
3. 在牛马 AI 中创建定时任务，prompt 内容取自 `scheduled-task-prompt.md`
