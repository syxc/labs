---
name: ducksearch
description: 免费网页搜索和内容提取工具（DuckDuckGo，无配额限制）。用于：搜索网络信息 | 查找技术文档 | 获取网页内容 | 网络调研。
---

# ducksearch

DuckDuckGo 网页搜索和内容提取（免费、无配额）。

## 命令

```bash
# 搜索
npx -y ducksearch search "query" [-n N]    # 搜索，限制结果数（默认 10）
npx -y ducksearch search "query" -o        # 打开第一个结果到浏览器

# 提取网页内容
npx -y ducksearch fetch URL                # 输出纯文本
npx -y ducksearch fetch URL -o file.txt    # 保存到文件
npx -y ducksearch fetch URL -r             # 输出原始 HTML
npx -y ducksearch fetch URL -j             # 输出 JSON 格式
```

## 提示

- 长内容用 `-o` 保存到文件，避免截断
- 可全局安装：`npm install -g ducksearch`
