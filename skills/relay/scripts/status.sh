#!/bin/bash
# 接力状态 + 自动保存的 token 估算
source "$(dirname "$0")/lib.sh"
ROOT="$(relay_root "${1:-$PWD}")" || { echo "当前目录没有启用接力（找不到 .relay）"; exit 0; }
cd "$ROOT"
echo "接力目录：$ROOT"
[ -f .relay/LOCK ] && { read A T H < .relay/LOCK; echo "最近干活：${A}，${H}"; }
echo "HANDOFF：$(wc -l < .relay/HANDOFF.md | tr -d ' ') 行，$(wc -c < .relay/HANDOFF.md | tr -d ' ') 字节"
cat .relay/journal.md .relay/journal-archive.md 2>/dev/null | awk '
/^## /{turns++; split($0,a," · "); ag[a[2]]++}
/handoff_updated=yes/{up++; split($0,b,"handoff_bytes="); bytes+=b[2]}
END{
  printf "已记录轮次：%d（", turns; for(k in ag) printf "%s %d 轮 ", k, ag[k]; print "）"
  printf "AI 更新 HANDOFF：%d 次\n", up
  if(up>0){ est=int(bytes/2.5*1.4); printf "估算花在更新交接上的 token：约 %d（每次≈读+写一遍 HANDOFF，按中文约 2.5 字节/token 粗估）\n", est }
  print "流水账、git 存档由脚本完成，不花 token。"
}'
