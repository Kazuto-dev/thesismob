#!/bin/sh
# Picks nginx's site configuration when the container starts: HTTPS once
# Let's Encrypt has issued a certificate for $DOMAIN, plain HTTP before
# that (enough to get the certificate, and to try the app on the
# server's IP address). Run by the nginx image's entrypoint.
set -eu

dir=/etc/nginx/buildquantify
domain="${DOMAIN:-}"
if [ -n "$domain" ] && [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
  mode=https
else
  mode=http
fi
# Only ${DOMAIN} is replaced; nginx's own $variables are left alone.
DOMAIN="${domain:-_}" envsubst '${DOMAIN}' \
  < "$dir/$mode.conf.template" > /etc/nginx/conf.d/default.conf
# Listen on IPv6 too only where the machine has it.
if [ ! -f /proc/net/if_inet6 ]; then
  sed -i '/listen \[::\]/d' /etc/nginx/conf.d/default.conf
fi
echo "BuildQuantify: serving over $mode${domain:+ for $domain}"

# Pick up renewed certificates: reload every 6 hours.
if [ "$mode" = https ]; then
  (while :; do sleep 21600; nginx -s reload; done) &
fi
