#!/usr/bin/env bash
# Prepares a fresh Ubuntu 24.04 server (such as an Oracle Cloud instance)
# for BuildQuantify's backend. Run once, as a user with sudo, from the
# deploy folder of the repository:
#
#   sudo ./setup-ubuntu.sh
#
# It installs Docker, opens ports 80 and 443, turns on automatic security
# updates and schedules a nightly database backup. It is safe to run
# again.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo ./setup-ubuntu.sh" >&2
  exit 1
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
OWNER="${SUDO_USER:-root}"

echo "== Updating the system"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl unattended-upgrades netfilter-persistent \
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

echo "== Firewall: ports 80 and 443"
# Oracle's Ubuntu images reject everything but SSH in iptables. Accept
# web traffic ahead of that rule and keep it across reboots.
for port in 80 443; do
  if ! iptables -C INPUT -p tcp --dport "$port" -m state --state NEW -j ACCEPT 2>/dev/null; then
    iptables -I INPUT 5 -p tcp --dport "$port" -m state --state NEW -j ACCEPT
  fi
done
if ! iptables -C INPUT -p udp --dport 443 -j ACCEPT 2>/dev/null; then
  iptables -I INPUT 5 -p udp --dport 443 -j ACCEPT
fi
netfilter-persistent save

echo "== Settings file"
if [[ ! -f "$HERE/.env" ]]; then
  cp "$HERE/.env.example" "$HERE/.env"
  sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$(openssl rand -hex 24)/" "$HERE/.env"
  chown "$OWNER": "$HERE/.env"
  chmod 600 "$HERE/.env"
  echo "Created $HERE/.env with a new database password. Fill in the rest."
fi

echo "== Nightly backup at 02:30"
mkdir -p "$HERE/backups"
chown "$OWNER": "$HERE/backups"
CRON="30 2 * * * cd $HERE && ./backup.sh >> $HERE/backups/backup.log 2>&1"
( crontab -u "$OWNER" -l 2>/dev/null | grep -v 'backup.sh' ; echo "$CRON" ) | crontab -u "$OWNER" -

cat <<DONE

Done. Next:
  1. In the Oracle Cloud console, add ingress rules for TCP 80 and 443
     (and UDP 443) to the instance's subnet security list.
  2. Point your API domain's DNS A record at this server's public IP.
  3. Edit $HERE/.env: API_DOMAIN, ADMIN_EMAILS, the Gmail settings and,
     when you have it, GOOGLE_CLIENT_IDS.
  4. Log out and in again (for the docker group), then:
       cd $HERE && docker compose up -d --build
DONE
