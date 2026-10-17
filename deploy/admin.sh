#!/usr/bin/env bash
# The admin tool, run inside the backend: codes, accounts, companies.
#
#   ./deploy/admin.sh                 lists the commands
#   ./deploy/admin.sh stats
#   ./deploy/admin.sh issue-code --plan business --months 1 \
#     --email customer@gmail.com --send
set -euo pipefail
cd "$(dirname "$0")/.."
tty=()
[[ -t 0 && -t 1 ]] || tty=(-T)
exec docker compose exec "${tty[@]}" -u 10001:10001 -e HOME=/app backend \
  dart run bin/admin.dart "$@"
