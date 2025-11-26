#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${SCRIPT_DIR}/run_files"

if [ ! -d "$RUN_DIR" ]; then
  echo "[ERROR] run_files directory not found: $RUN_DIR" >&2
  exit 1
fi

# run_files/run_* を番号順に実行
mapfile -t RUN_SCRIPTS < <(find "$RUN_DIR" -maxdepth 1 -type f -name 'run_*' | sort)

if [ "${#RUN_SCRIPTS[@]}" -eq 0 ]; then
  echo "[ERROR] no run_* scripts found in $RUN_DIR" >&2
  exit 1
fi

echo "[INFO] scripts to run:"
for s in "${RUN_SCRIPTS[@]}"; do
  echo "  - $(basename "$s")"
done
echo

i=1
for s in "${RUN_SCRIPTS[@]}"; do
  echo "=============================="
  echo "[STEP $i/${#RUN_SCRIPTS[@]}] $(basename "$s")"
  echo "=============================="
  bash "$s"
  echo "[DONE] $(basename "$s")"
  echo
  ((i++))
done

echo "[ALL DONE] all run_* scripts finished."
