#!/usr/bin/env bash
set -euo pipefail

host="${1:-45.202.242.2.sslip.io}"
web_root=/opt/workplace-town/web
bundle=/root/workplace-town-web-server.zip

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root." >&2
    exit 1
fi
if [[ ! -f "$bundle" ]]; then
    echo "Missing deployment bundle: $bundle" >&2
    exit 1
fi
if ss -lntH '( sport = :80 or sport = :8443 )' | grep -q .; then
    echo "TCP 80 or 8443 is already in use; inspect listeners before deployment." >&2
    exit 1
fi
if systemctl is-active --quiet caddy 2>/dev/null; then
    echo "Caddy is already active; refusing to replace its configuration." >&2
    exit 1
fi
install -d -m 755 /opt/workplace-town
unzip -oq "$bundle" -d /opt/workplace-town
if [[ ! -f "$web_root/index.html" ]]; then
    echo "The exported web files are missing." >&2
    exit 1
fi
if ! id workplace-town >/dev/null 2>&1; then
    useradd --system --home /opt/workplace-town --shell /usr/sbin/nologin workplace-town
fi
install -d -o workplace-town -g workplace-town -m 750 /var/lib/workplace-town
install -m 644 /opt/workplace-town/deploy/workplace-town.service \
    /etc/systemd/system/workplace-town.service
systemctl daemon-reload
systemctl enable workplace-town
systemctl restart workplace-town
if ! systemctl is-active --quiet workplace-town; then
    echo "The workplace-town API service is not running." >&2
    exit 1
fi
if [[ -t 0 ]]; then
    read -rsp "DeepSeek API key (press Enter to use template NPC replies): " deepseek_key
    echo
    if [[ -n "$deepseek_key" ]]; then
        umask 077
        printf 'NPC_LLM_PROVIDER=deepseek\nDEEPSEEK_API_KEY=%s\n' "$deepseek_key" > /etc/workplace-town.env
        chmod 600 /etc/workplace-town.env
        systemctl restart workplace-town
    fi
    unset deepseek_key
fi

if ! command -v caddy >/dev/null; then
    export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a
    apt-get update
    apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl gnupg
    curl -fsSL --retry 3 https://dl.cloudsmith.io/public/caddy/stable/gpg.key \
        | gpg --batch --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -fsSL --retry 3 https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt \
        -o /etc/apt/sources.list.d/caddy-stable.list
    apt-get update
    apt-get install -y caddy
fi

if [[ -f /etc/caddy/Caddyfile ]]; then
    cp -p /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.before-workplace-town.$(date +%Y%m%d%H%M%S)"
fi
cat > /etc/caddy/Caddyfile <<EOF
https://$host:8443 {
    encode zstd gzip
    header {
        Cross-Origin-Opener-Policy same-origin
        Cross-Origin-Embedder-Policy require-corp
        Cross-Origin-Resource-Policy same-origin
    }

    @api path /api/*
    handle @api {
        reverse_proxy 127.0.0.1:8077
    }

    handle {
        root * $web_root
        file_server
    }
}
EOF
chmod 644 /etc/caddy/Caddyfile

caddy validate --config /etc/caddy/Caddyfile
systemctl enable --now caddy
systemctl restart caddy

for attempt in {1..6}; do
    status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 10 "https://$host:8443/" || true)"
    if [[ "$status" == 200 ]]; then
        break
    fi
    sleep 5
done
if [[ "$status" != 200 ]]; then
    echo "HTTPS did not become ready; check TCP 80/8443 and Caddy logs." >&2
    journalctl -u caddy --no-pager -n 25 >&2
    exit 1
fi

api_status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 10 "https://$host:8443/api/v1/health")"
if [[ "$api_status" != 200 ]]; then
    echo "The protected API returned HTTP $api_status instead of 200." >&2
    exit 1
fi

echo "Ready: https://$host:8443/"
echo "Visitors can open the URL without a password. Session data is stored on this server."
