---
name: relay
description: 多个 AI 编码工具（Claude Code、Codex、WorkBuddy）之间接力干同一个任务。一个工具额度用完时，另一个工具接着干，进度靠工作目录里的 .relay/HANDOFF.md、.relay/journal.md 和 git 自动存档传递。用户说「接力」「接着干」「继续上次的」「额度用完了」「换 Codex/Claude 继续」「初始化接力」「接力状态」时使用。
---

# relay：跨工具接力

把接力需要的任务状态写进项目目录。Claude Code、Codex、WorkBuddy 轮流接班，读取同一套文件；已有结束钩子的客户端自动存档，其他客户端按规则维护交接文件。

## 安装后启用（由 Agent 执行）

用户安装 Skill 后说「在当前项目启用 relay，自动完成初始化和配置检查」，就是请求你执行配置。安装文件本身不会执行命令。不要把下面的命令清单交回用户手动运行。

1. 确认当前项目的绝对路径；从本 SKILL.md 所在目录解析 `scripts/`，不要写死作者机器的路径。检查 Git、jq、Python 3 和 `tomllib`；缺依赖时按当前环境和授权安装，无法完成则说明具体缺项。
2. 读取现有 `.relay/` 和项目规则；运行 `bash <技能目录>/scripts/init.sh <项目目录>`。保留既有交接内容，根据当前任务补全目标、已完成和下一步。该脚本会创建本地 Git 记录，并为图片等二进制添加忽略规则；不会上传远端。它还会把 relay 链接到本机装了的其他工具（Claude Code、Codex、WorkBuddy 中缺的那些），用户只需把 relay 装进其中一个。
3. 检查实际已安装的客户端与钩子。缺失时先备份配置，再增量配置：Claude Code 的 `SessionStart` 调用 `session_start.sh`，`Stop` 调用 `claude_stop.sh`；Codex 的 `notify` 调用 `codex_notify.sh`。保留已有钩子和通知行为，不覆盖整份配置。Codex 原来已有 notify 命令时，不要覆盖：把原命令写进环境变量 `RELAY_CODEX_NOTIFY_FORWARD`，`codex_notify.sh` 会先转发给它再存档。若当前客户端不支持对应钩子，明确采用手动维护交接文件的方式，不声称自动存档已接通。
4. 将本项目实际使用的 Skill 写进 `.relay/skills.txt`，检查并补齐目标客户端缺失的链接；将确实需要写入的项目外目录写进 `.relay/writable.txt`。`doctor.sh --fix` 会改变 Codex 全局联网和目录权限，仅在任务确有需要且已有授权时使用；纯本地接力无需联网，可只修复缺失链接。保留已有的更严格限制，不为通过检查扩大权限。
5. 运行 `bash <技能目录>/scripts/doctor.sh <项目目录>`，逐项处理检查结果，再验证配置可解析、脚本路径存在。当前脚本的检查不能代替真实钩子触发验证；首次正常任务结束后再从日志和 Git 确认。不要为测试伪造用户消息或提交。
6. 向用户简要报告已完成项、仍需处理的依赖，以及哪些配置需要新会话生效。之后的使用口令是「继续」；Agent 负责更新状态，用户无需手填交接文件。

## 文件

| 文件 | 谁写 | 内容 |
|---|---|---|
| `.relay/HANDOFF.md` | AI | 当前状态：目标、已完成、进行中（精确到下一步动作）、待办、本任务内的决定、坑。≤60 行，覆盖旧内容，不记历史 |
| `.relay/journal.md` | 脚本自动 | 每轮流水：时间、工具、用户说了什么、AI 最后回了什么、改了哪些文件。只留最近 30 条 |
| `.relay/LOCK` | 脚本自动 | 最近在干活的工具和时间 |
| git 提交 | 已接通的结束钩子调用脚本 | 每轮结束尝试 commit；只保存已落盘且未被忽略的内容，不保证恢复中断时未写出的内容 |

## 接班（开工时）

1. 读 `.relay/HANDOFF.md`。
2. 不够清楚时，再看 `.relay/journal.md` 最后 3 条和 `git log --oneline -5`、`git status`。
3. `.relay/LOCK` 显示另一个工具 10 分钟内还在干活时，先停下问用户，避免两边同时改文件。
4. 新会话的第一次回复，先按下面格式向用户报告接力状态，再处理用户的请求：

```
【接力状态】
- 上一棒：<工具>，<时间>（<多久前>）
- 已完成：<一句话>
- 进行中：<做到哪一步>
- 下一步：<接下来要做的动作>
- 最近改动：<文件，最多 3 个>
```

Claude Code 由 SessionStart 钩子自动注入以上内容；Codex 和 WorkBuddy 由 AGENTS.md 里的规则触发。

## 干活时

- 每完成一个步骤（不是每轮），覆盖更新 HANDOFF.md 的「进行中」「下一步」，有新决定写进「决定」。纯问答、纯聊天不更新。
- 「进行中」要写到别人能直接接手的程度：哪个文件、做到哪一步、下一条命令是什么。
- 存档由脚本自动完成，不需要手动 git commit。
- 交接前不能留后台还在跑的任务；跑着的话，在 HANDOFF 里写明怎么重跑。
- 工具独有的能力（如 Claude 的子 Agent）做的事，在 HANDOFF 里写结果，不写过程。

## 命令

`<技能目录>` 指本 SKILL.md 所在目录，常见位置是 `~/.claude/skills/relay` 或 `~/.codex/skills/relay`。

- 初始化一个目录：`bash <技能目录>/scripts/init.sh <目录>`（顺带把 relay 链接给本机其他工具）
- 体检前提条件：`bash <技能目录>/scripts/doctor.sh`；自动修复 skill 对齐和 Codex 权限：加 `--fix`
  - `.relay/skills.txt`：本项目要用的 skill，每行一个，修复时从 Claude 链接到 Codex 和 WorkBuddy
  - `.relay/writable.txt`：项目外 Codex 需要写的目录，修复时加进 Codex 可写目录，并打开联网（全局设置，改前自动备份）
- 查看接力状态和 token 估算：`bash <技能目录>/scripts/status.sh`
