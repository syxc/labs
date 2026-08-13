### 命令参考

使用前确认可用：`which <tool>` 或 `npx <tool> --version`

**jina.ai**

```bash
# 网页提取
curl https://r.jina.ai/https://URL -o output.txt

# 搜索（密钥从 $JINA_API_KEY 读取，绝不硬编码）
curl -H "Authorization: Bearer $JINA_API_KEY" "https://s.jina.ai/?q=QUERY"
```

**ducksearch**

```bash
npx ducksearch search "query" [-n N] [-o]         # -o 打开首个结果
npx ducksearch fetch URL [-o output.txt] [--raw]  # 推荐 -o 保存
```

**ghr**

```bash
ghr analyze <owner/repo> [-o output.json] [--no-cache]
ghr structure <owner/repo>                        # 目录结构
ghr search <owner/repo> <query> [-e .ext]
ghr read <owner/repo> <file>                      # 读取文件
ghr readme <owner/repo>                           # 读取 README
ghr ls <owner/repo> [<path>]
ghr clean --all                                   # 清理缓存
```

**网络检查**

```bash
export https_proxy=http://127.0.0.1:7890 GH_PROXY=http://127.0.0.1:7890
```

**chrome-devtools** — 底层 CLI，截图/导航/调试/性能分析

**browser-harness** — CDP 直接操控，坐标点击
