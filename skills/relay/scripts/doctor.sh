#!/bin/bash
# 接力体检：检查前提条件；加 --fix 自动修复 skill 对齐和 Codex 权限。
# 用法：doctor.sh [目录] [--fix]
source "$(dirname "$0")/lib.sh"
FIX=0; DIR="$PWD"
for a in "$@"; do [ "$a" = "--fix" ] && FIX=1 || DIR="$a"; done
ROOT="$(relay_root "$DIR")" || { echo "✗ $DIR 没有启用接力，先运行 init.sh"; exit 1; }
cd "$ROOT"; OK=1
echo "接力体检：$ROOT"
# 0 基础
for c in git jq; do command -v $c >/dev/null || { echo "✗ 缺少 $c"; OK=0; }; done
grep -q 'relay/scripts/claude_stop.sh' ~/.claude/settings.json 2>/dev/null && echo "✓ Claude Code 钩子已配置" || { echo "✗ Claude Code 钩子未配置（~/.claude/settings.json）"; OK=0; }
grep -q 'relay/scripts/codex_notify.sh' ~/.codex/config.toml 2>/dev/null && echo "✓ Codex notify 已配置" || { echo "✗ Codex notify 未配置（~/.codex/config.toml）"; OK=0; }

# 5 skill 对齐
SRC=~/.claude/skills
if [ -f .relay/skills.txt ]; then
  for tgt in ~/.codex/skills ~/.workbuddy/skills; do
    [ -d "$tgt" ] || continue
    MISS=""
    while read -r s; do
      s="${s%%#*}"; s="$(echo "$s" | xargs)"; [ -z "$s" ] && continue
      [ -e "$tgt/$s" ] && continue
      if [ ! -e "$SRC/$s" ]; then echo "✗ $s 在 Claude 里也没有，无法同步"; OK=0; continue; fi
      if [ $FIX = 1 ]; then ln -s "$(cd "$SRC/$s" && pwd -P)" "$tgt/$s" && echo "  + 已链接 $s → $tgt"; else MISS="$MISS $s"; fi
    done < .relay/skills.txt
    [ -n "$MISS" ] && { echo "✗ $tgt 缺：$MISS"; OK=0; } || echo "✓ $tgt 已包含 skills.txt 里的全部 skill"
  done
else
  echo "· 没有 .relay/skills.txt，跳过 skill 对齐（每行写一个要用的 skill 名）"
fi

# 6 Codex 权限：联网 + 项目外可写目录
CFG=~/.codex/config.toml
NEED=""
if [ ! -f "$CFG" ]; then echo "· 没有 ${CFG}，跳过 Codex 权限检查"; else
ROOTS=()
[ -f .relay/writable.txt ] && while read -r w; do w="${w%%#*}"; w="$(echo "$w" | xargs)"; [ -z "$w" ] && continue; w="${w/#\~/$HOME}"; ROOTS+=("$(cd "$w" 2>/dev/null && pwd -P || echo "$w")"); done < .relay/writable.txt
NEED=$(python3 - "$CFG" "$ROOT" "${ROOTS[@]}" <<'PY'
import sys,tomllib
cfg,root,*roots=sys.argv[1:]
d=tomllib.load(open(cfg,'rb'))
miss=[]
if d.get('projects',{}).get(root,{}).get('trust_level')!='trusted': miss.append('trust')
sw=d.get('sandbox_workspace_write',{})
if not sw.get('network_access'): miss.append('network')
have=set(sw.get('writable_roots',[]))
for r in roots:
    if r not in have: miss.append('root:'+r)
print(' '.join(miss))
PY
)
if [ -z "$NEED" ]; then echo "✓ Codex 已信任本目录、可联网、项目外目录可写"
else
  echo "✗ Codex 权限缺：$NEED"
  if [ $FIX = 1 ]; then
    cp "$CFG" "$CFG.bak-relay-$(date +%Y%m%d%H%M%S)"
    python3 - "$CFG" "$ROOT" "${ROOTS[@]}" <<'PY'
import sys,re,json,tomllib
cfg,root,*roots=sys.argv[1:]
s=open(cfg).read(); d=tomllib.loads(s)
if d.get('projects',{}).get(root,{}).get('trust_level')!='trusted':
    s+=f'\n[projects.{json.dumps(root,ensure_ascii=False)}]\ntrust_level = "trusted"\n'
sw=d.get('sandbox_workspace_write')
cur=list(dict.fromkeys((sw or {}).get('writable_roots',[])+roots))
body='network_access = true\nwritable_roots = '+json.dumps(cur,ensure_ascii=False)+'\n'
if sw is None:
    s+='\n# relay：联网 + 项目外可写目录（doctor.sh 维护）\n[sandbox_workspace_write]\n'+body
else:
    s=re.sub(r'(\[sandbox_workspace_write\]\n)((?:(?!\n\[).)*)', lambda m: m.group(1)+''.join(l+'\n' for l in m.group(2).splitlines() if not l.startswith(('network_access','writable_roots')))+body, s, count=1, flags=re.S)
tomllib.loads(s); open(cfg,'w').write(s)
PY
    echo "  + 已修复（原文件已备份为 $CFG.bak-relay-*）。注意：联网和可写目录是 Codex 全局设置。"
  fi
fi
fi
[ $FIX = 0 ] && [ $OK = 0 -o -n "$NEED" ] && echo "→ 运行 doctor.sh --fix 自动修复 skill 对齐和 Codex 权限"
echo "· 改完配置后，Codex 和 Claude Code 要开新会话才生效"
