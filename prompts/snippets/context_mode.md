### context-mode：上下文窗口优化

核心原则：将原始数据留在 sandbox 中处理，避免占用 context window。

#### Think in Code

分析/统计/过滤/比较/搜索/解析/转换数据时：用 `mcp__context-mode__ctx_execute(language, code)` 写代码处理，只用 `console.log()` 输出答案，不将原始数据读入 context。JavaScript（Node.js 内置：`fs`、`path`、`child_process`），`try/catch`，处理 `null`/`undefined`。一个脚本替代十次工具调用。

大输出（>5KB）时传 `intent: "describe what to find"`：输出自动索引到 FTS5，仅匹配预览进入 context，后续通过 ctx_search 深入。不传 intent 则完整 stdout 进入 context。

#### 优先使用 sandbox 工具

| 场景 | 应使用 |
|------|--------|
| 网页抓取 | `mcp__context-mode__ctx_fetch_and_index(url, source)` → `mcp__context-mode__ctx_search(queries)` |
| Shell 输出 >20 行 | `mcp__context-mode__ctx_batch_execute(commands, queries)` 或 `mcp__context-mode__ctx_execute(language:"shell", code)` |
| 读文件做分析（非编辑） | `mcp__context-mode__ctx_execute_file(path, language, code)`。以 UTF-8 读取，二进制文件用 `ctx_execute` + `readFileSync(path)` 返回 Buffer |
| grep/搜索输出大 | `mcp__context-mode__ctx_execute(language:"shell", code:"grep ...")` 在 sandbox 中执行 |

Shell 短命令（`git`/`mkdir`/`rm`/`mv`/`cd`/`ls`/`npm install`/`pip install`）直接用 Bash 即可。

#### 工具速查

| 工具 | 用途 |
|------|------|
| `mcp__context-mode__ctx_batch_execute(commands, queries)` | 批量收集（`{label, command}`），自动索引 + 搜索，一次替代 30+ 次调用 |
| `mcp__context-mode__ctx_search(queries: ["q1", ...])` | 搜索已索引内容，批量查询 |
| `mcp__context-mode__ctx_execute(language, code)` | Sandbox 执行，仅 stdout 进入 context |
| `mcp__context-mode__ctx_execute_file(path, language, code)` | Sandbox 处理文件。每次调用隔离：一个 ctx_execute 中写入的文件在后续 ctx_execute_file 中不可见。使用绝对路径 |
| `mcp__context-mode__ctx_fetch_and_index(url, source)` → ctx_search | 抓取网页 → 索引 → 搜索 |
| `mcp__context-mode__ctx_index(content, source)` | 索引内容到 FTS5 供后续搜索 |

#### 并发

I/O 密集型（网络）：`concurrency: 4-8`。CPU 密集型/共享状态：`concurrency: 1`。GitHub API：上限 4。

#### 用户命令

| 命令 | 操作 |
|------|------|
| `ctx stats` | 调用 `mcp__context-mode__ctx_stats` |
| `ctx doctor` | 调用 `mcp__context-mode__ctx_doctor`，运行返回的命令 |
| `ctx upgrade` | 调用 `mcp__context-mode__ctx_upgrade`，运行返回的命令 |
| `ctx purge` | 调用 `mcp__context-mode__ctx_purge`，`confirm: true` |

/clear 或 /compact 后知识库和会话统计保留。用 `ctx purge` 完全重置。
