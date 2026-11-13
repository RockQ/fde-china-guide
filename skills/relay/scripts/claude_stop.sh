#!/bin/bash
# Claude Code Stop 钩子：先判断要不要逼 AI 更新 HANDOFF，再自动存档。
source "$(dirname "$0")/lib.sh"
IN="$(cat)"
CWD="$(echo "$IN" | jq -r '.cwd // empty')"; [ -z "$CWD" ] && CWD="$PWD"
ROOT="$(relay_root "$CWD")" || exit 0
ACTIVE="$(echo "$IN" | jq -r '.stop_hook_active // false')"
TP="$(echo "$IN" | jq -r '.transcript_path // empty')"
UMSG=""; AMSG=""
if [ -f "$TP" ]; then
  UMSG="$(jq -r 'select(.type=="user") | .message.content | if type=="string" then . else (map(select(.type=="text") | .text) | join(" ")) end' "$TP" 2>/dev/null | grep -v '^$' | grep -v '^<' | tail -1)"
  AMSG="$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' "$TP" 2>/dev/null | tail -c 600)"
fi
cd "$ROOT"
REAL="$(git status --porcelain 2>/dev/null | awk '{print $2}' | grep -v '^\.relay/')"
HCH="$(git status --porcelain .relay/HANDOFF.md 2>/dev/null)"
AGE=99999; [ -f .relay/HANDOFF.md ] && AGE=$(( $(date +%s) - $(stat -f %m .relay/HANDOFF.md 2>/dev/null || stat -c %Y .relay/HANDOFF.md) ))
if [ "$ACTIVE" != "true" ] && [ -n "$REAL" ] && [ -z "$HCH" ] && [ "$AGE" -gt 900 ]; then
  jq -n --arg r "relay：这一轮改了文件，但 .relay/HANDOFF.md 超过 15 分钟没更新。请覆盖更新它的「进行中（精确到下一步动作）」「待办」，有新决定写进「决定」，≤60 行，然后再结束。不用向用户解释这一步。" '{decision:"block", reason:$r}'
  exit 0
fi
bash "$(dirname "$0")/checkpoint.sh" claude "$CWD" "$UMSG" "$AMSG"
exit 0
