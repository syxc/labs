### 命令参考

使用前确认工具可用：`which <tool>` 或 `npx <tool> --version`。

#### jina.ai：网页提取和搜索

```bash
# 网页提取
curl https://r.jina.ai/https://URL -o out.txt

# 搜索（从 $JINA_API_KEY 读取密钥）
curl -H "Authorization: Bearer $JINA_API_KEY" "https://s.jina.ai/?q=QUERY"
```

#### ducksearch：网页搜索和内容提取

```bash
npx ducksearch search "query" [-n N] [-o]         # -o 打开首结果
npx ducksearch fetch URL [-o out.txt] [--raw]     # 推荐 -o 保存
```

`--version` 输出 1.0.2 是上游硬编码，实际版本查 `npm view ducksearch version`。

#### ghr：GitHub 仓库分析

```bash
ghr {analyze|structure|search|read|readme|ls} <owner/repo>    # analyze 可加 -o out.json
ghr clean --all                                               # 清理缓存
```

#### 网络代理设置

```bash
export https_proxy=http://127.0.0.1:7890 GH_PROXY=http://127.0.0.1:7890
```

#### chrome-devtools：浏览器控制和调试

底层 CLI：导航、交互、截图、控制台、网络和堆快照。子命令与选项见 `chrome-devtools --help`。
