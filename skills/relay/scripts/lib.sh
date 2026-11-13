#!/bin/bash
# 找到含 .relay 的目录（从给定目录向上找）
relay_root() {
  local d; d="$(cd "${1:-$PWD}" 2>/dev/null && pwd -P)" || return 1
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    [ -d "$d/.relay" ] && { echo "$d"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}
now() { date '+%Y-%m-%d %H:%M:%S'; }
clip() { tr '\n' ' ' | sed 's/  */ /g' | cut -c1-"${1:-240}"; }
