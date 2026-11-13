#!/bin/bash
# 在一个目录启用接力：git、.relay 文件、AGENTS.md 协议。
DIR="${1:-$PWD}"; cd "$DIR" || exit 1
SK="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p .relay
[ -f .relay/HANDOFF.md ] || cp "$SK/templates/HANDOFF.md" .relay/HANDOFF.md
[ -f .relay/journal.md ] || echo "# 接力流水账（最近 30 条，更早的在 journal-archive.md）" > .relay/journal.md
[ -d .git ] || git init -q
git config core.quotepath false
if ! grep -q 'relay-ignore' .gitignore 2>/dev/null; then cat >> .gitignore <<'G'
# relay-ignore：只跟踪文字类文件，图片等二进制不进仓库
*.png
*.jpg
*.jpeg
*.gif
*.webp
*.mp4
*.mov
*.pdf
*.xls
*.xlsx
*.docx
*.pptx
*.zip
.DS_Store
node_modules/
__pycache__/
.relay/LOCK
G
fi
if ! grep -q '接力协议（relay）' AGENTS.md 2>/dev/null; then cat >> AGENTS.md <<'A'

## 接力协议（relay）

本目录在 Claude Code、Codex、WorkBuddy 之间接力干活，进度在 `.relay/` 和 git 里。

- **开工**：先读 `.relay/HANDOFF.md`；不够清楚再看 `.relay/journal.md` 最后 3 条和 `git log --oneline -5`。`.relay/LOCK` 显示另一个工具 10 分钟内还在干活时，先问用户。新会话的第一次回复，不管用户说什么，先按这个格式报告接力状态，再处理请求：

  ```
  【接力状态】
  - 上一棒：<工具>，<时间>（<多久前>）
  - 已完成：<一句话>
  - 进行中：<做到哪一步>
  - 下一步：<接下来要做的动作>
  - 最近改动：<文件，最多 3 个>
  ```
- **干活**：每完成一个步骤（不是每轮），覆盖更新 HANDOFF.md 的「进行中（精确到下一步动作）」「待办」，新决定写进「决定」，≤60 行，只写当前状态。纯问答不更新。
- **存档**：git 提交和流水账由脚本自动完成，不需要手动 commit。
- **交接**：不留后台还在跑的任务；跑着的话在 HANDOFF 里写明怎么重跑。
A
fi
git add -A >/dev/null 2>&1; git commit -q --no-verify -m "relay: init" >/dev/null 2>&1
echo "已在 $DIR 启用接力"
[ -f .relay/skills.txt ] || printf "# 本项目会用到的 skill，每行一个；doctor.sh --fix 会同步到 Codex 和 WorkBuddy\nrelay\n" > .relay/skills.txt
[ -f .relay/writable.txt ] || printf "# 项目目录外、Codex 需要写入的目录，每行一个\n" > .relay/writable.txt
bash "$SK/scripts/doctor.sh" "$DIR"
