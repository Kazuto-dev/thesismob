#!/usr/bin/env bash
# Saves the database to backups/ and keeps the last 14 days. Run nightly
# by cron (setup-ubuntu.sh adds it). With OCI_BUCKET set and the OCI CLI
# configured, each backup is also copied to Object Storage, off this
# server.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups
file="backups/buildquantify-$(date +%Y%m%d-%H%M).dump"
docker compose exec -T db pg_dump -U buildquantify -d buildquantify -Fc > "$file"
echo "$(date -Is) saved $file ($(du -h "$file" | cut -f1))"
find backups -name 'buildquantify-*.dump' -mtime +14 -delete
if [[ -n "${OCI_BUCKET:-}" ]] && command -v oci >/dev/null; then
  oci os object put --bucket-name "$OCI_BUCKET" --file "$file" --force >/dev/null
  echo "$(date -Is) copied to bucket $OCI_BUCKET"
fi
