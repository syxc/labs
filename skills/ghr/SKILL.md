---
name: ghr
description: GitHub 仓库分析工具（免费，无 API 配额）。用于：分析仓库 | 搜索代码 | 查看结构 | 读取文件 | 查看 README。
---

# ghr

GitHub 仓库快速分析（免费、无 API 限制）。

## 命令

```bash
# 仓库分析
ghr analyze owner/repo [-o output.json]

# 目录结构
ghr structure owner/repo [-d depth]        # 默认深度 3
ghr ls owner/repo path/to/dir              # 列出目录

# 代码搜索
ghr search owner/repo "query" [-e .ext] [-i]  # -e 按扩展名，-i 忽略大小写

# 文件读取
ghr read owner/repo path/to/file           # 读取文件
ghr readme owner/repo                      # 读取 README

# 缓存
ghr clean --all                            # 清理所有缓存
```

全局 flag：`--no-cache`（绕过缓存，重新克隆）

## 提示

- 大型仓库用 `-o` 保存到文件，避免输出截断
- 首次分析会克隆仓库，后续使用本地缓存（极快）
