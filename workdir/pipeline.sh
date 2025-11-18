#!/usr/bin/env bash
set -euo pipefail

CFG=${1:-config.yaml}

# YAML読込（最小）
eval "$(
python - <<'PY'
import sys, yaml
c = yaml.safe_load(open(sys.argv[1]))
def E(k,v): print(f'export {k}="{v}"')
E("WORK_DIR", c["project"]["work_dir"])
d=c["data"]; E("SLC_DIR",d["slc_dir"]); E("ORB_DIR",d["orbit_dir"]); E("AUX_DIR",d["aux_dir"]); E("DEM",d["dem"])
E("COREG_METHOD", c["coreg"]["method"]); E("REF_DATE", c["coreg"]["reference_date"])
E("WORKFLOW", c["ifgram"]["workflow"])
PY
"$(realpath "$CFG")"
)"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

stackSentinel.py \
  -s "$SLC_DIR" \
  -o "$ORB_DIR" \
  -a "$AUX_DIR" \
  -d "$DEM" \
  -w "$WORK_DIR" \
  -W "$WORKFLOW" \
  -C "$COREG_METHOD" -m "$REF_DATE"

