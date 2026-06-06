# AI Builders Early Report - Scheduled Task Prompt

> This file stores the prompt used by the scheduled task (09:00 daily via niuma AI).
> Restore by creating a new scheduled task with this prompt content.

> **Note:** All paths below use `$HOME` placeholders. Replace with actual paths on the target machine.

---

执行 AI Builders 早报生成流程。

前置检查：
- 检查 `src/content/blog/ai/YYYY-MM/ai-builders-YYYY-MM-DD.md` 是否已存在（在博客仓库 `$HOME/Workspace/demos/syxc.github.io` 中），如果今天已发布过则跳过整个流程

步骤：
1. 先拉取上游 feed 更新：`cd $HOME/ai/niuma/follow-builders && git pull`
2. 运行 `bash $HOME/.follow-builders/run-digest.sh` 拉取最新 feed 数据并生成 prompt 文件
3. 读取 prompt 模板 `$HOME/.follow-builders/prompts/digest-morning-briefing.md` 中的规则
4. 读取 JSON blob `$HOME/.follow-builders/cache/digest-input-YYYY-MM-DD.json` 中的原始 feed 数据（用今天日期替换 YYYY-MM-DD）
5. 按照规则生成完整的 AI Builders 早报
6. 将生成的早报保存到 `$HOME/.follow-builders/output/YYYY-MM-DD-digest.md`（纯内容，不含 frontmatter）
7. 同步到博客仓库：
   a. `cd $HOME/Workspace/demos/syxc.github.io && git pull`
   b. 创建按月目录 `src/content/blog/ai/YYYY-MM/`（如不存在）
   c. 将早报写入 `src/content/blog/ai/YYYY-MM/ai-builders-YYYY-MM-DD.md`，文件头部添加 frontmatter：
   ```
   ---
   pubDatetime: YYYY-MM-DDT00:00:00+08:00
   title: AI Builders 早报 - YYYY-MM-DD
   slug: ai-builders-YYYY-MM-DD
   featured: true
   draft: false
   description: "AI Builders Morning Briefing - AI 开发者每日精华"
   tags:
     - AI
     - Builders
     - News
   ---
   ```
   d. `git add src/content/blog/ai/YYYY-MM/ai-builders-YYYY-MM-DD.md` 并 `git commit -m "feat(blog): AI Builders morning briefing YYYY-MM-DD" && git push`
8. 在对话中展示生成的早报内容

输出格式要求：
- 使用 Markdown 标准语法
- 项目用 `###` 标题 + 列表形式展示
- 不要用分割线（如 ━━、--- 作为装饰性分隔）
- 链接用 Markdown 格式 [text](url)
- 保持简洁清晰的层次结构
- 表格使用最简 GFM 格式：`| col | col |` 搭配 `|---|---|`
- 不使用 `&nbsp;` 等 HTML 实体
- 不使用 emoji

注意：
- 使用今天的日期（YYYY-MM-DD 格式）
- 格式严格遵循 prompt 模板中的规则
- 输出中文，技术术语保留英文
- 标点规则：见 prompt 模板 `digest-morning-briefing.md` Language & Punctuation 一节，核心原则：句子级标点跟随句子主体语言（中文句子用。，：；！？），英文术语嵌入时不改变句子标点；引号按内容分（中文引用""，英文术语""，代码`）；括号按内容分（中文用（），英文用() 且前加空格）；数字用半角
- 博客文件需要 frontmatter，本地存档文件不需要
