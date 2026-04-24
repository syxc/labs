# Claude Code 供应商切换工具

## 架构设计

### 设计原则

1. **配置分离** - 供应商配置与运行时配置分离，便于维护
2. **安全性** - API Key 不写入配置文件，从环境变量读取
3. **原子性** - 使用 atomic write 防止中断导致配置损坏
4. **可扩展** - 添加新供应商只需修改 providers.json

### 文件结构

```
~/.claude/
├── providers.json          # 供应商配置定义
├── settings.json           # Claude Code 运行时配置
└── settings.json.bak.*     # 配置备份（最多保留 3 个）

~/.zshenv.env               # 敏感环境变量（API Keys）
~/.zshrc                    # Shell 别名定义

~/.local/bin/cc-switch      # 切换脚本
```

### 数据流

```
┌─────────────────┐
│  providers.json │  供应商配置定义
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   cc-switch     │  切换脚本
└────────┬────────┘
         │
         ├──────────────────────────────┐
         │                              │
         ▼                              ▼
┌─────────────────┐            ┌─────────────────┐
│  settings.json  │            │   .zshenv.env   │
│ (BASE_URL等)    │            │ (AUTH_TOKEN)    │
└─────────────────┘            └─────────────────┘
         │                              │
         └──────────────┬───────────────┘
                        ▼
              ┌─────────────────┐
              │   Claude Code   │
              └─────────────────┘
```

## 配置说明

### providers.json

供应商配置文件，定义每个供应商的连接参数：

```json
{
  "供应商标识": {
    "name": "显示名称",
    "ANTHROPIC_BASE_URL": "API 端点",
    "ANTHROPIC_AUTH_TOKEN_VAR": "环境变量名",
    "ANTHROPIC_MODEL": "默认模型",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "Haiku 模型",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "Sonnet 模型",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "Opus 模型"
  }
}
```

**关键字段说明：**

| 字段 | 说明 |
|------|------|
| `ANTHROPIC_AUTH_TOKEN_VAR` | 存储 API Key 的环境变量名（不带 `${}`） |
| `ANTHROPIC_BASE_URL` | API 端点地址 |
| `ANTHROPIC_MODEL` | 默认使用的模型 |

### .zshenv.env

存储敏感环境变量，格式：

```bash
# 供应商 API Keys
export TP_MIMO_API_KEY="your-mimo-key"
export ZAI_API_KEY="your-glm-key"

# Claude Code 读取的变量（由 cc-switch 自动管理）
export ANTHROPIC_AUTH_TOKEN="${TP_MIMO_API_KEY}"
```

**注意：** `ANTHROPIC_AUTH_TOKEN` 的值使用 `${VAR}` 格式引用其他环境变量，Claude Code 会自动展开。

### settings.json

Claude Code 运行时配置，**不包含** `ANTHROPIC_AUTH_TOKEN`：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.example.com/anthropic",
    "ANTHROPIC_MODEL": "model-name",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "haiku-model",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "sonnet-model",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "opus-model"
  }
}
```

## 安装步骤

### 1. 复制文件

```bash
# 复制脚本
cp cc-switch ~/.local/bin/
chmod +x ~/.local/bin/cc-switch

# 复制配置
cp providers.json ~/.claude/
```

### 2. 配置环境变量

编辑 `~/.zshenv.env`，添加供应商 API Keys：

```bash
# MiMo
export TP_MIMO_API_KEY="your-mimo-key"

# GLM
export ZAI_API_KEY="your-glm-key"
```

### 3. 添加 Shell 别名

在 `~/.zshrc` 中添加：

```bash
# Claude Code 供应商切换
alias cc-switch='~/.local/bin/cc-switch'
alias cc-mimo='~/.local/bin/cc-switch mimo'
alias cc-glm='~/.local/bin/cc-switch glm'
```

### 4. 重新加载配置

```bash
source ~/.zshrc
```

## 使用方法

### 查看可用供应商

```bash
cc-switch
# 或
cc-switch --list
```

### 切换供应商

```bash
cc-switch glm    # 切换到 GLM
cc-switch mimo   # 切换到 MiMo
```

### 查看当前配置

```bash
cc-switch --status
```

### 查看帮助

```bash
cc-switch --help
```

### 验证配置

```bash
cc-switch --validate
```

校验内容：
- providers.json / settings.json 格式
- 必填字段是否完整
- 环境变量是否已设置
- .zshenv.env 配置是否正确

## 添加新供应商

### 1. 获取 API 信息

需要以下信息：
- API 端点地址
- API Key
- 支持的模型列表

### 2. 添加环境变量

在 `~/.zshenv.env` 中添加：

```bash
export NEW_PROVIDER_API_KEY="your-api-key"
```

### 3. 更新 providers.json

```json
{
  "new-provider": {
    "name": "New Provider",
    "ANTHROPIC_BASE_URL": "https://api.newprovider.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN_VAR": "NEW_PROVIDER_API_KEY",
    "ANTHROPIC_MODEL": "model-name",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "haiku-model",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "sonnet-model",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "opus-model"
  }
}
```

### 4. 添加别名（可选）

在 `~/.zshrc` 中添加：

```bash
alias cc-new='~/.local/bin/cc-switch new-provider'
```

## 故障排除

### 问题：切换后 Claude Code 仍使用旧配置

**解决方案：** 重启 Claude Code

```bash
# 退出当前会话
# 重新启动
claude
```

### 问题：环境变量未设置

**检查：**

```bash
echo $TP_MIMO_API_KEY
echo $ZAI_API_KEY
```

**解决：** 确保在 `~/.zshenv.env` 中正确设置了环境变量，并执行 `source ~/.zshenv.env`

### 问题：jq 未安装

**安装：**

```bash
brew install jq
```

### 问题：权限错误

**检查脚本权限：**

```bash
ls -la ~/.local/bin/cc-switch
chmod +x ~/.local/bin/cc-switch
```

## 设计决策

### 为什么 AUTH_TOKEN 不写入 settings.json？

1. **安全性** - 避免 API Key 明文存储在配置文件中
2. **灵活性** - 支持从环境变量动态读取
3. **一致性** - 与其他工具（如 curl、git）使用相同的环境变量

### 为什么使用 ${VAR} 格式？

Claude Code 支持在环境变量值中使用 `${VAR}` 格式引用其他环境变量，这允许：
- 一个变量引用另一个变量
- 便于管理和切换
- 避免重复存储敏感信息

### 为什么需要 reload？

切换供应商后需要重新加载 shell 配置，因为：
- `.zshenv.env` 中的环境变量需要重新读取
- `settings.json` 的更改需要 Claude Code 重新加载
- 确保所有配置生效
