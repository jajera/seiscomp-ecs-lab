#!/bin/bash
# Load GEOFON inventory into RDS before scmaster listens, so processors
# that start in parallel can wait on Station rows instead of an empty catalog.
set -euo pipefail
export SEISCOMP_ROOT="${SEISCOMP_ROOT:-/home/sysop/seiscomp}"
export PATH="$SEISCOMP_ROOT/bin:$PATH"

/docker/import-inventory.sh
exec seiscomp exec scmaster --console 1
