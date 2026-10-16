#!/usr/bin/env bash
# Updates to the latest code on this branch and rebuilds what changed.
# A backup runs first; the backend brings the database up to date when
# it starts.
set -euo pipefail
cd "$(dirname "$0")/.."
./deploy/backup.sh
git pull --ff-only
docker compose pull db certbot
docker compose up -d --build
docker image prune -f >/dev/null
docker compose ps
