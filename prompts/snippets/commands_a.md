### 命令参考

使用前确认可用：`which <tool>` 或 `npx <tool> --version`

**jina.ai** —— 网页提取 / 搜索

```bash
curl https://r.jina.ai/https://URL -o out.txt                              # 网页提取
curl -H "Authorization: Bearer $JINA_API_KEY" "https://s.jina.ai/?q=QUERY" # 搜索（密钥从环境变量读取，绝不硬编码）
```

**ducksearch**

```bash
npx ducksearch search "query" [-n N] [-o]         # -o 打开首结果
npx ducksearch fetch URL [-o out.txt] [--raw]     # 推荐 -o 保存
```

**ghr** —— GitHub 仓库分析

```bash
ghr {analyze|structure|search|read|readme|ls} <owner/repo>   # analyze 可加 -o out.json
ghr clean --all                                               # 清理缓存
```

**网络检查**

```bash
export https_proxy=http://127.0.0.1:7890 GH_PROXY=http://127.0.0.1:7890
```

**chrome-devtools** — 底层 CLI：截图/导航/调试/性能分析。
