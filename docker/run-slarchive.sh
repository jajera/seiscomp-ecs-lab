#!/bin/bash
set -euo pipefail
export SEISCOMP_ROOT="${SEISCOMP_ROOT:-/home/sysop/seiscomp}"
export PATH="$SEISCOMP_ROOT/bin:$PATH"

host="${SEEDLINK_HOST:-seedlink}"
echo "waiting for ${host}:18000..."
ok=0
for _ in $(seq 1 90); do
  if python3 -c "import socket; socket.create_connection(('${host}',18000),2).close()" 2>/dev/null; then
    ok=1
    break
  fi
  sleep 2
done
if [ "$ok" != "1" ]; then
  echo "${host}:18000 not reachable" >&2
  exit 1
fi

seiscomp enable slarchive >/dev/null || true
seiscomp update-config slarchive
streams="$SEISCOMP_ROOT/var/lib/slarchive/slarchive.streams"
if [ ! -f "$streams" ]; then
  echo "missing $streams" >&2
  exit 1
fi
echo "starting slarchive -> ${host}:18000"
exec slarchive -SDS "$SEISCOMP_ROOT/var/lib/archive" -Fi:1 -Fc:900 -l "$streams" "${host}:18000"
