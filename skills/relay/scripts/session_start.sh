#!/bin/bash
# Claude Code SessionStart 钩子：把接力状态注入上下文。
source "$(dirname "$0")/lib.sh"
IN="$(cat)"; CWD="$(echo "$IN" | jq -r '.cwd // empty' 2>/dev/null)"; [ -z "$CWD" ] && CWD="$PWD"
ROOT="$(relay_root "$CWD")" || exit 0
cd "$ROOT"
echo "【接力状态 relay】本目录启用了跨工具接力（Claude Code / Codex / WorkBuddy）。规则见 relay skill。"
if [ -f .relay/LOCK ]; then
  read A T H < .relay/LOCK
  D=$(( $(date +%s) - T ))
  echo "上一个干活的工具：${A}，${H}（$((D/60)) 分钟前）。"
  [ "$A" != "claude" ] && [ "$D" -lt 600 ] && echo "⚠ ${A} 10 分钟内还在干活，先问用户是否已停下，避免两边同时改文件。"
fi
echo; echo "=== .relay/HANDOFF.md ==="; cat .relay/HANDOFF.md 2>/dev/null
echo; echo "=== 流水账最后 3 条 ==="
awk '/^## /{n++} {buf[n]=buf[n] $0 "\n"} END{for(i=(n>3?n-2:1);i<=n;i++) printf "%s", buf[i]}' .relay/journal.md 2>/dev/null
echo; echo "=== 最近提交 ==="; git log --oneline -5 2>/dev/null
cat <<'FMT'

【给 AI 的要求】这是新会话的第一次回复。不管用户第一句话说什么，先按下面格式向用户报告接力状态（信息取自上面的 HANDOFF、流水账和提交，不编造；HANDOFF 是空模板时就说「交接文件还没填，以下根据流水账推断」），然后再处理用户的请求：
【接力状态】
- 上一棒：<工具>，<时间>（<多久前>）
- 已完成：<一句话>
- 进行中：<做到哪一步>
- 下一步：<接下来要做的动作>
- 最近改动：<文件，最多 3 个>
FMT
exit 0
