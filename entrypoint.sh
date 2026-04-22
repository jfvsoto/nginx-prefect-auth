#!/bin/sh
set -e

# --- Validate required environment variables ---
missing=""
for var in AUTH_USER AUTH_PASSWORD UPSTREAM_HOST UPSTREAM_PORT; do
    eval val=\$$var
    if [ -z "$val" ]; then
        missing="$missing $var"
    fi
done

if [ -n "$missing" ]; then
    echo "ERROR: Missing required environment variables:$missing" >&2
    exit 1
fi

# --- Generate .htpasswd from env vars ---
htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASSWORD"
echo "Created .htpasswd for user: $AUTH_USER"

# --- Detect DNS resolver from container runtime ---
RESOLVER=$(grep -m1 '^nameserver' /etc/resolv.conf | awk '{print $2}')
if [ -z "$RESOLVER" ]; then
    RESOLVER="8.8.8.8"
    echo "WARNING: No nameserver found in /etc/resolv.conf, falling back to $RESOLVER"
fi

# nginx requires IPv6 addresses in square brackets
if echo "$RESOLVER" | grep -q ':'; then
    RESOLVER="[$RESOLVER]"
fi

echo "Using DNS resolver: $RESOLVER"
export RESOLVER

# --- Railway provides $PORT; default to 8080 for local dev ---
export LISTEN_PORT="${PORT:-8080}"
echo "Listening on port: $LISTEN_PORT"

# --- Substitute env vars into nginx config ---
envsubst '${LISTEN_PORT} ${RESOLVER} ${UPSTREAM_HOST} ${UPSTREAM_PORT}' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

echo "nginx config written, starting nginx..."

exec "$@"