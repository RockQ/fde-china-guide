#!/bin/bash
# 用法：checkpoint.sh <agent> <cwd> <用户消息> <AI 消息> [handoff_guard_note]
# 自动存档：写流水账、更新 LOCK、git commit。不调用模型，不花 token。
source "$(dirname "$0")/lib.sh"
AGENT="$1"; CWD="$2"; UMSG="$3"; AMSG="$4"
ROOT="$(relay_root "$CWD")" || exit 0
cd "$ROOT" || exit 0
J=.relay/journal.md
CHANGED="$(git status --porcelain 2>/dev/null | grep -v ' \.relay/journal' | grep -v ' \.relay/LOCK' | awk '{print $2}')"
HU=no; echo "$CHANGED" | grep -q '^\.relay/HANDOFF.md$' && HU=yes
HB=$(wc -c < .relay/HANDOFF.md 2>/dev/null | tr -d ' ')
FILES="$(echo "$CHANGED" | grep -v '^$' | head -10 | tr '\n' ' ')"
{
  echo ""
  echo "## $(now) · $AGENT"
  echo "- 用户：$(printf '%s' "$UMSG" | clip 200)"
  echo "- AI：$(printf '%s' "$AMSG" | clip 300)"
  echo "- 改动：${FILES:-无}"
  echo "- handoff_updated=$HU handoff_bytes=$HB"
} >> "$J"
# 只留最近 30 条，旧的归档
N=$(grep -c '^## ' "$J")
if [ "$N" -gt 30 ]; then
  CUT=$(grep -n '^## ' "$J" | sed -n "$((N-29))p" | cut -d: -f1)
  head -n $((CUT-1)) "$J" | tail -n +2 >> .relay/journal-archive.md
  { echo "# 接力流水账（最近 30 条，更早的在 journal-archive.md）"; tail -n +"$CUT" "$J"; } > "$J.tmp" && mv "$J.tmp" "$J"
fi
echo "$AGENT $(date +%s) $(now)" > .relay/LOCK
git add -A >/dev/null 2>&1
git commit -q --no-verify -m "relay($AGENT): $(printf '%s' "$UMSG" | clip 60)" >/dev/null 2>&1
exit 0
