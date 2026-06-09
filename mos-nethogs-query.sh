#!/usr/bin/env bash
# mos-nethogs-query — runs one nethogs refresh cycle and outputs JSON
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo '{"error":"must be run as root"}'
  exit 1
fi

if ! command -v nethogs >/dev/null 2>&1; then
  echo '{"error":"nethogs not installed"}'
  exit 1
fi

# -t = text mode, -c 2 = two cycles (take only last), -d 1 = 1s delay
RAW="$(nethogs -t -c 2 -d 1 2>/dev/null || true)"

echo "$RAW" | awk '
BEGIN { block = 0 }
/^Refreshing:/ {
  block++
  delete lines
  count = 0
  next
}
/\t/ {
  lines[count++] = $0
}
END {
  printf "["
  out = 0
  for (i = 0; i < count; i++) {
    split(lines[i], f, "\t")
    if (f[1] == "unknown TCP") continue
    n = split(f[1], p, "/")
    if (n < 3) continue
    pid  = p[n-1]
    user = p[n]
    prog = ""
    for (j = 1; j <= n-2; j++) prog = prog (j > 1 ? "/" : "") p[j]
    if (prog == "") continue
    if (out > 0) printf ","
    printf "{\"program\":\"%s\",\"pid\":\"%s\",\"user\":\"%s\",\"interface\":\"%s\",\"sent\":%.3f,\"recv\":%.3f}",
      prog, pid, user, f[2], f[3]+0, f[4]+0
    out++
  }
  printf "]"
}
'