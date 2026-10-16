#!/usr/bin/env bash
# Restores the database from a backup made by backup.sh, replacing what
# is there. The API is stopped while it runs.
#
#   ./restore.sh backups/buildquantify-20261016-0230.dump
set -euo pipefail
cd "$(dirname "$0")"
file="${1:?which backup file?}"
read -r -p "Replace the database with $file? Type yes: " answer
[[ "$answer" == yes ]] || exit 1
docker compose stop api
docker compose exec -T db pg_restore -U buildquantify -d buildquantify \
  --clean --if-exists --no-owner < "$file"
docker compose start api
echo "Restored $file"
