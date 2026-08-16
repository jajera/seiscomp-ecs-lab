#!/bin/bash
# Point SeisComP at Compose DNS or ECS Cloud Map / RDS via env.
set -euo pipefail

export SEISCOMP_ROOT="${SEISCOMP_ROOT:-/home/sysop/seiscomp}"
DB_HOST="${DB_HOST:-mariadb}"
DB_USER="${DB_USER:-sysop}"
DB_PASSWORD="${DB_PASSWORD:-sysop}"
DB_NAME="${DB_NAME:-seiscomp}"
SEEDLINK_HOST="${SEEDLINK_HOST:-seedlink}"
SCMASTER_HOST="${SCMASTER_HOST:-scmaster}"

python3 - "$SEISCOMP_ROOT" "$DB_HOST" "$DB_USER" "$DB_PASSWORD" "$DB_NAME" \
  "$SEEDLINK_HOST" "$SCMASTER_HOST" <<'PY'
import pathlib, sys
root, db_host, db_user, db_password, db_name, seedlink, scmaster = sys.argv[1:]
dsn = f"mysql://{db_user}:{db_password}@{db_host}/{db_name}"
store = f"{db_user}:{db_password}@{db_host}/{db_name}"
g = pathlib.Path(root) / "etc" / "global.cfg"
text = g.read_text() if g.exists() else ""
lines = []
keys = {
    "recordstream": f"slink://{seedlink}:18000",
    "connection.server": f"{scmaster}/production",
    "database": dsn,
}
seen = set()
for line in text.splitlines():
    raw = line.strip()
    if not raw or raw.startswith("#") or "=" not in line:
        lines.append(line)
        continue
    key = line.split("=", 1)[0].strip()
    if key in keys:
        lines.append(f"{key} = {keys[key]}")
        seen.add(key)
    else:
        lines.append(line)
for key, val in keys.items():
    if key not in seen:
        lines.append(f"{key} = {val}")
g.parent.mkdir(parents=True, exist_ok=True)
g.write_text("\n".join(lines) + "\n")

s = pathlib.Path(root) / "etc" / "scmaster.cfg"
stext = s.read_text() if s.exists() else ""
slines = []
skeys = {
    "queues.production.processors.messages.dbstore.read": store,
    "queues.production.processors.messages.dbstore.write": store,
}
sseen = set()
for line in stext.splitlines():
    raw = line.strip()
    if not raw or raw.startswith("#") or "=" not in line:
        slines.append(line)
        continue
    key = line.split("=", 1)[0].strip()
    if key in skeys:
        slines.append(f"{key} = {skeys[key]}")
        sseen.add(key)
    else:
        slines.append(line)
for key, val in skeys.items():
    if key not in sseen:
        slines.append(f"{key} = {val}")
s.write_text("\n".join(slines) + "\n")

a = pathlib.Path(root) / "etc" / "slarchive.cfg"
atext = a.read_text() if a.exists() else ""
alines = []
akeys = {"address": seedlink, "port": "18000"}
aseen = set()
for line in atext.splitlines():
    raw = line.strip()
    if not raw or raw.startswith("#") or "=" not in line:
        alines.append(line)
        continue
    key = line.split("=", 1)[0].strip()
    if key in akeys:
        alines.append(f"{key} = {akeys[key]}")
        aseen.add(key)
    else:
        alines.append(line)
for key, val in akeys.items():
    if key not in aseen:
        alines.append(f"{key} = {val}")
a.write_text("\n".join(alines) + "\n")
PY
