#!/bin/bash
# Codex notify 包装：先转发给原来的通知程序（如有），再自动存档。
# 原来的 notify 命令写在环境变量 RELAY_CODEX_NOTIFY_FORWARD 里；没设时，尝试 Codex Computer Use 自带的通知程序。
JSON="${@: -1}"
FWD="${RELAY_CODEX_NOTIFY_FORWARD:-}"
SKY="$HOME/.codex/computer-use/Codex Computer Use.app/Contents/SharedSupport/SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient"
if [ -n "$FWD" ]; then (eval "$FWD" '"$JSON"' >/dev/null 2>&1 &)
elif [ -x "$SKY" ]; then ("$SKY" turn-ended "$JSON" >/dev/null 2>&1 &)
fi
TYPE="$(echo "$JSON" | jq -r '.type // empty' 2>/dev/null)"
[ "$TYPE" != "agent-turn-complete" ] && exit 0
CWD="$(echo "$JSON" | jq -r '.cwd // empty')"; [ -z "$CWD" ] && CWD="$PWD"
UMSG="$(echo "$JSON" | jq -r '(."input-messages" // []) | last // ""')"
AMSG="$(echo "$JSON" | jq -r '."last-assistant-message" // ""')"
# Codex 客户端自己的后台调用（生成推荐问题、起任务标题）也会触发 notify，不记账
case "$UMSG" in
  "# Overview Generate"*|"You are a helpful assistant. You will be presented with a user prompt"*) exit 0 ;;
esac
bash "$(dirname "$0")/checkpoint.sh" codex "$CWD" "$UMSG" "$AMSG"
exit 0
