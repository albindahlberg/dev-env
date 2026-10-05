#!/usr/bin/env bash
# Snapshot the local MLflow server (docker, sqlite + served artifacts under
# ~/mlflow-local) into ~/mlflow-local/backup/<weekday>/, so the 7 newest
# daily snapshots rotate themselves. The DB goes through sqlite's backup API,
# which is safe while the server writes; trace spans live in artifacts/, so
# those are tarred alongside.
set -euo pipefail

root="${MLFLOW_LOCAL:-$HOME/mlflow-local}"
out="$root/backup/$(date +%a)"
mkdir -p "$out"

python3 - "$root/db/mlflow.db" "$out/mlflow.db" <<'PY'
import sqlite3, sys
src = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
dst = sqlite3.connect(sys.argv[2])
src.backup(dst)
dst.close()
PY
tar -czf "$out/artifacts.tar.gz" -C "$root" artifacts
