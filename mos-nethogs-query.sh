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

# -t = troff/text mode, -c 2 = two cycles (first is often empty), -d 1 = 1s delay
RAW="$(nethogs -t -c 2 -d 1 2>/dev/null || true)"

echo "$RAW" | awk '
BEGIN { printf "["; count=0 }
/\t/ {
  split($0, f, "\t")
  n = split(f[1], p, "/")
  pid  = p[n-1]
  user = p[n]
  prog = ""
  for (i=1; i<=n-2; i++) prog = prog (i>1 ? "/" : "") p[i]
  if (prog == "") next
  sent = f[3]+0
  recv = f[4]+0
  if (count > 0) printf ","
  printf "{\"program\":\"%s\",\"pid\":\"%s\",\"user\":\"%s\",\"interface\":\"%s\",\"sent\":%.3f,\"recv\":%.3f}", prog, pid, user, f[2], sent, recv
  count++
}
END { printf "]" }
'