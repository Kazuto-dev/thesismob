#!/usr/bin/env bash
# Starts BuildQuantify, or applies new code. The pipeline runs it after
# every deploy; you can run it yourself after a git pull. It backs up the
# database, restarts the backend on the new code (which brings the
# database schema up to date), reloads nginx's settings and waits until
# the API answers.
#
# A git pull brings the backend and nginx's settings. The web app is
# compiled by the pipeline, which uploads it to frontend/build/web.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo ".env is missing. Run once: sudo ./deploy/setup-ubuntu.sh" >&2
  exit 1
fi
# Made here, not by Docker, so it belongs to you and the pipeline can
# upload the app into it.
mkdir -p frontend/build/web
if [[ ! -f frontend/build/web/index.html ]]; then
  echo "Note: the web app is not here yet; the pipeline uploads it." >&2
fi

if [[ -n "$(docker compose ps --quiet --status running db)" ]]; then
  ./deploy/backup.sh
fi

# Restart the backend on the new code, unless `up` has just (re)created
# it, which already did.
before="$(docker compose ps --quiet backend)"
docker compose up -d --remove-orphans
if [[ -n "$before" && "$before" == "$(docker compose ps --quiet backend)" ]]; then
  docker compose restart backend
fi
docker compose exec -T frontend nginx -t -q
docker compose exec -T frontend nginx -s reload

echo "== Waiting for the API"
for _ in $(seq 1 60); do
  if curl -fs -o /dev/null http://localhost/api/health; then
    docker compose ps
    echo "BuildQuantify is up."
    exit 0
  fi
  sleep 3
done
echo "The API did not answer within 3 minutes. Its log:" >&2
docker compose logs --tail 60 backend >&2
exit 1
