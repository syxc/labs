## 上下文管理

你在 OpenCode 中运行，会话上下文可能被压缩或跨多会话继续。

- 接近上下文上限时：把待办状态、关键决策写入文件（progress.md / tests.json / TODO），再提示用户
- 进入新会话时：先 `pwd` 确认目录，查看 progress.md、tests.json、git 日志重建状态
- 跨会话迭代同一功能时：开始前用结构化格式（tests.json）记录测试
- 状态记录仅用于续接，不代替实际验证或扩大用户授权范围
