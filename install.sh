#!/usr/bin/env bash
# cc-switch 安装脚本
# Usage: ./install.sh

set -euo pipefail

echo "=== Claude Code 供应商切换工具安装 ==="
echo ""

# 检查依赖
if ! command -v jq &> /dev/null; then
  echo "正在安装 jq..."
  brew install jq
fi

# 创建目录
mkdir -p ~/.local/bin

# 复制脚本
echo "安装 cc-switch 脚本..."
cp cc-switch ~/.local/bin/
chmod +x ~/.local/bin/cc-switch

# 复制配置
echo "安装 providers.json 配置..."
cp providers.json ~/.claude/

# 检查 .zshenv.env 是否存在
if [[ ! -f ~/.zshenv.env ]]; then
  echo "创建 ~/.zshenv.env..."
  cat > ~/.zshenv.env << 'EOF'
# ============================================================================
# 敏感 API 密钥配置（不纳入版本控制）
# ============================================================================

# MiMo
export TP_MIMO_API_KEY="your-mimo-key-here"

# GLM
export ZAI_API_KEY="your-glm-key-here"

# Claude Code - 由 cc-switch 管理
export ANTHROPIC_AUTH_TOKEN="${TP_MIMO_API_KEY}"
EOF
  echo "请编辑 ~/.zshenv.env 填入你的 API Keys"
else
  # 检查是否已有 ANTHROPIC_AUTH_TOKEN
  if ! grep -q "^export ANTHROPIC_AUTH_TOKEN=" ~/.zshenv.env; then
    echo "添加 ANTHROPIC_AUTH_TOKEN 到 ~/.zshenv.env..."
    echo "" >> ~/.zshenv.env
    echo "# Claude Code - 由 cc-switch 管理" >> ~/.zshenv.env
    echo 'export ANTHROPIC_AUTH_TOKEN="${TP_MIMO_API_KEY}"' >> ~/.zshenv.env
  fi
fi

# 检查 .zshrc 是否已有 alias
if ! grep -q "cc-switch" ~/.zshrc; then
  echo "添加 alias 到 ~/.zshrc..."
  cat >> ~/.zshrc << 'EOF'

# Claude Code 供应商切换
alias cc-switch='~/.local/bin/cc-switch'
alias cc-mimo='~/.local/bin/cc-switch mimo'
alias cc-glm='~/.local/bin/cc-switch glm'
EOF
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "下一步："
echo "1. 编辑 ~/.zshenv.env 填入你的 API Keys"
echo "2. 重新加载配置: source ~/.zshrc"
echo "3. 使用 cc-switch 查看可用供应商"
echo ""
echo "使用方法："
echo "  cc-switch        # 列出供应商"
echo "  cc-switch glm    # 切换到 GLM"
echo "  cc-switch mimo   # 切换到 MiMo"
echo "  cc-switch -s     # 查看当前配置"
