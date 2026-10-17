#!/usr/bin/env bash
# Restores the database from a backup made by backup.sh, replacing what
# is there. The backend is stopped while it runs.
#
#   ./deploy/restore.sh deploy/backups/buildquantify-20261016-0230.dump
set -euo pipefail
file="$(realpath "${1:?which backup file?}")"
cd "$(dirname "$0")/.."
read -r -p "Replace the database with $file? Type yes: " answer
[[ "$answer" == yes ]] || exit 1
docker compose stop backend
docker compose exec -T db pg_restore -U buildquantify -d buildquantify \
  --clean --if-exists --no-owner < "$file"
docker compose start backend
echo "Restored $file"
