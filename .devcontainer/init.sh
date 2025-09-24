#!/usr/bin/env bash
set -euo pipefail

# ---- ISCE_HOME の自動検出（conda-forge の site-packages 内） ----
ISCE_HOME=$(python - <<'PY'
import isce, pathlib
print(pathlib.Path(isce.__file__).parent)
PY
)
export ISCE_HOME

# ---- topsStack のソースルート（Dockerfileでclone済み） ----
export ISCE_SRC=/opt/isce2

# ---- PATH / PYTHONPATH に追加 ----
export PATH="$ISCE_HOME/applications:$ISCE_SRC/contrib/stack/topsStack:$PATH"
export PYTHONPATH="$ISCE_SRC:${PYTHONPATH:-}"

# ---- 動作確認のログ ----
echo "[init] ISCE_HOME=$ISCE_HOME"
echo "[init] ISCE_SRC=$ISCE_SRC"
echo "[init] PATH=$(echo $PATH | cut -d: -f1-5)..."

# ---- デフォルトはシェルを起動 ----
exec bash
