#!/usr/bin/env bash
# Prepares a fresh Ubuntu 24.04 server (such as an Oracle Cloud instance)
# for BuildQuantify. Run once, as a user with sudo, from the repository:
#
#   sudo ./deploy/setup-ubuntu.sh
#
# The pipeline runs it by itself on the first deploy. It installs
# Docker, opens port 80, turns on automatic security updates, creates
# .env and schedules a nightly database backup. It is safe to run again.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo ./deploy/setup-ubuntu.sh" >&2
  exit 1
fi
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OWNER="${SUDO_USER:-root}"

echo "== Updating the system"
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  ca-certificates curl git rsync unattended-upgrades netfilter-persistent \
  iptables-persistent

echo "== Automatic security updates"
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "== Docker"
if ! command -v docker >/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker
if [[ "$OWNER" != root ]]; then usermod -aG docker "$OWNER"; fi

echo "== Firewall: port 80"
# Oracle's Ubuntu images reject everything but SSH in iptables. Accept
# web traffic ahead of that rule and keep it across reboots. Cloudflare
# serves HTTPS to visitors and reaches this server on port 80.
if ! iptables -C INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT 2>/dev/null; then
  iptables -I INPUT 5 -p tcp --dport 80 -m state --state NEW -j ACCEPT
fi
netfilter-persistent save

echo "== Settings file"
if [[ ! -f "$ROOT/.env" ]]; then
  cp "$ROOT/.env.example" "$ROOT/.env"
  sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$(openssl rand -hex 24)/" "$ROOT/.env"
  chown "$OWNER": "$ROOT/.env"
  chmod 600 "$ROOT/.env"
  echo "Created $ROOT/.env with a new database password. Fill in the rest."
fi

echo "== Nightly backup at 02:30"
mkdir -p "$ROOT/deploy/backups"
chown "$OWNER": "$ROOT/deploy/backups"
CRON="30 2 * * * $ROOT/deploy/backup.sh >> $ROOT/deploy/backups/backup.log 2>&1"
( crontab -u "$OWNER" -l 2>/dev/null | grep -v 'backup.sh' ; echo "$CRON" ) | crontab -u "$OWNER" -

cat <<DONE

Done. Next:
  1. In the Oracle Cloud console, add an ingress rule for TCP 80 to the
     instance's subnet security list.
  2. Edit $ROOT/.env: DOMAIN, ADMIN_EMAILS and the Gmail settings.
  3. Start it, or apply the changes to .env:
       cd $ROOT && ./deploy/update.sh
     (log out and in again first if docker says permission denied).
DONE
