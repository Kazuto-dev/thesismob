#!/usr/bin/env bash
# Gets the HTTPS certificate for DOMAIN from Let's Encrypt and switches
# nginx to HTTPS. Run once, after the domain's DNS points at this server
# and the app is up (docker compose up -d). certbot renews it after that.
#
#   ./deploy/get-certificate.sh
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
: "${DOMAIN:?Set DOMAIN in .env first}"
: "${CERTBOT_EMAIL:?Set CERTBOT_EMAIL in .env first}"

echo "== Checking that http://$DOMAIN reaches this server"
if ! curl -fsS -o /dev/null --max-time 10 "http://$DOMAIN/"; then
  echo "http://$DOMAIN/ did not answer. Check the DNS A record, the Oracle"
  echo "security list (TCP 80 and 443) and 'docker compose ps'." >&2
  exit 1
fi

echo "== Asking Let's Encrypt for a certificate"
docker compose run --rm --entrypoint certbot certbot certonly \
  --webroot -w /var/www/certbot -d "$DOMAIN" \
  --email "$CERTBOT_EMAIL" --agree-tos --no-eff-email --non-interactive

echo "== Switching nginx to HTTPS"
docker compose up -d --force-recreate frontend
sleep 3
curl -fsS -o /dev/null --max-time 10 "https://$DOMAIN/" \
  && echo "Done: https://$DOMAIN is live." \
  || echo "nginx restarted; check 'docker compose logs frontend'."
