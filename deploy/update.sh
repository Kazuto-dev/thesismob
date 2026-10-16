#!/usr/bin/env bash
# Updates to the latest code on this branch and restarts what changed.
# The API brings the database up to date on start. A backup runs first.
set -euo pipefail
cd "$(dirname "$0")"
./backup.sh
git pull --ff-only
docker compose pull db caddy
docker compose up -d --build
docker image prune -f >/dev/null
docker compose ps
