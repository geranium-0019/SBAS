#!/usr/bin/env bash
set -euo pipefail

# ---- ISCE_HOME の自動検出（conda-forge の site-packages 内）----
ISCE_HOME=$(python - <<'PY'
import isce, pathlib
print(pathlib.Path(isce.__file__).parent)
PY
)
export ISCE_HOME

# ---- isce2 ソース（Dockerfileで clone 済み）----
export ISCE_SRC=/opt/isce2

# ---- 追加したい stack ツールのディレクトリ（存在すればPATHへ）----
STACK_DIRS=(
  "$ISCE_SRC/contrib/stack/topsStack"   # Sentinel-1 TOPS
  "$ISCE_SRC/contrib/stack/alosStack"   # ALOS/ALOS-2
)

# /opt/conda/bin を先に（念のため）
if ! echo ":$PATH:" | grep -q ':/opt/conda/bin:'; then
  export PATH="/opt/conda/bin:$PATH"
fi

# ISCE の applications を PATH に
if [ -d "$ISCE_HOME/applications" ]; then
  export PATH="$ISCE_HOME/applications:$PATH"
fi

# 各 stack ディレクトリを PATH に追加（存在チェック付き）
for d in "${STACK_DIRS[@]}"; do
  if [ -d "$d" ]; then
    export PATH="$d:$PATH"
  fi
done

# Python から contrib を import できるように
export PYTHONPATH="$ISCE_SRC:${PYTHONPATH:-}"

# ---- ログ（任意）----
echo "[init] ISCE_HOME=$ISCE_HOME"
echo "[init] ISCE_SRC=$ISCE_SRC"
echo "[init] Added to PATH:"
for d in "$ISCE_HOME/applications" "${STACK_DIRS[@]}"; do
  [ -d "$d" ] && echo "       - $d"
done

# ---- 動作確認のヒント（必要なら uncomment）
# which topsApp.py || true
# which stripmapApp.py || true
# which stackSentinel.py || true
# which alosStack.py || true

# ここからシェルで作業（Jupyter 自動起動にしたい場合は下を置き換え）
exec bash
# exec jupyter lab --ip=0.0.0.0 --no-browser --NotebookApp.token=''
