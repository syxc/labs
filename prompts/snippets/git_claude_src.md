### Git

- commit message 用英文：
  - 格式为 `<scope>: <summary>`（scope 必填，summary 以动词开头，无需 type tag）
  - 正文使用真实换行和缩进
  - 禁止写入字面量 `\n`、`\t`，以免 hooks 解析失败

<example>
  <good>auth: verify token expiry before refresh</good>
  <bad>fix: \n fixed the bug</bad>
</example>

- 仅在用户明确要求时创建 commit
- 仅在用户明确要求时 push；push 前复查状态、目标分支和待提交内容
- 允许 amend 本地未推送的 commit；amend 已推送的 commit 须经用户明确同意
- 提交始终走完整 hooks 流程，使用个人 author
- 破坏性操作（reset --hard、force push、checkout .、restore .、clean -f、branch -D）仅在用户明确要求时执行
- 敏感文件（.env、credentials、*.pem、*.key）通过 .gitignore 排除；提交前检查暂存内容
- 撤销已提交变更用 `git revert`；撤销本轮未提交改动用反向补丁以保留工作区内容，不用 `checkout .`、`restore .` 等会丢弃未提交改动的命令
