# cc-switch

Claude Code 多供应商切换工具，一键切换 MiMo、GLM 等不同供应商配置。

## 平台支持

- macOS（已验证）
- Linux（未测试，理论上兼容）

依赖：`jq`、`zsh`

## 文件说明

```
~/.claude/providers.json      # 供应商配置
~/.claude/settings.json       # Claude Code 配置（不含 API Key）
~/.zshenv.env                 # 环境变量（API Key 存储于此）
~/.local/bin/cc-switch        # 切换脚本
```

## 安装

```bash
# 方式一：使用安装脚本
./install.sh

# 方式二：手动安装
cp cc-switch ~/.local/bin/
chmod +x ~/.local/bin/cc-switch
cp providers.json ~/.claude/
```

安装后在 `~/.zshrc` 中添加：

```bash
alias cc-switch='~/.local/bin/cc-switch'
alias cc-mimo='~/.local/bin/cc-switch mimo'
alias cc-glm='~/.local/bin/cc-switch glm'
```

执行 `source ~/.zshrc` 生效。

## 配置

编辑 `~/.zshenv.env`，设置供应商 API Key：

```bash
export TP_MIMO_API_KEY="your-mimo-key"
export ZAI_API_KEY="your-glm-key"
```

## 使用

```bash
cc-switch            # 查看可用供应商
cc-switch mimo       # 切换到 MiMo
cc-switch glm        # 切换到 GLM
cc-switch -s         # 查看当前配置
cc-switch --validate # 校验配置
```

切换后重启 Claude Code 生效。

## 添加新供应商

1. 在 `~/.zshenv.env` 添加 API Key

```bash
export NEW_PROVIDER_API_KEY="your-key"
```

2. 在 `~/.claude/providers.json` 添加配置

```json
{
  "new-provider": {
    "name": "New Provider",
    "ANTHROPIC_BASE_URL": "https://api.example.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN_VAR": "NEW_PROVIDER_API_KEY",
    "ANTHROPIC_MODEL": "model-name",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "haiku-model",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "sonnet-model",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "opus-model"
  }
}
```

## 常见问题

**切换后配置未生效**

重启 Claude Code。

**jq 未安装**

```bash
brew install jq
```

**环境变量未设置**

```bash
echo $TP_MIMO_API_KEY  # 检查是否已设置
source ~/.zshenv.env   # 重新加载
```
