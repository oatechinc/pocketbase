#!/bin/sh

set -eu

PB_ROOT="/pb"
PUBLIC_PORT="${PORT:-8080}"
POCKETBASE_INTERNAL_PORT="${POCKETBASE_INTERNAL_PORT:-${POCKETBASE_PORT:-8090}}"
FILEBROWSER_INTERNAL_PORT="${FILEBROWSER_INTERNAL_PORT:-${FILEBROWSER_PORT:-8091}}"
FILEBROWSER_BASE_URL="/files"
FILEBROWSER_DB="$PB_ROOT/filebrowser.db"
CADDYFILE_PATH="/etc/caddy/Caddyfile"

mkdir -p "$PB_ROOT"
cd "$PB_ROOT"

if ! command -v pocketbase >/dev/null 2>&1; then
    echo "pocketbase binary not found in PATH" >&2
    exit 1
fi

if ! command -v filebrowser >/dev/null 2>&1; then
    echo "filebrowser binary not found in PATH" >&2
    exit 1
fi

if ! command -v caddy >/dev/null 2>&1; then
    echo "caddy binary not found in PATH" >&2
    exit 1
fi

if [ -z "${WEB_USERNAME:-}" ] || [ -z "${WEB_PASSWORD:-}" ]; then
    echo "WEB_USERNAME and WEB_PASSWORD are required to expose Filebrowser." >&2
    exit 1
fi

if [ "$PUBLIC_PORT" = "$POCKETBASE_INTERNAL_PORT" ] || [ "$PUBLIC_PORT" = "$FILEBROWSER_INTERNAL_PORT" ] || [ "$POCKETBASE_INTERNAL_PORT" = "$FILEBROWSER_INTERNAL_PORT" ]; then
    echo "PORT, POCKETBASE_INTERNAL_PORT, and FILEBROWSER_INTERNAL_PORT must all be different." >&2
    exit 1
fi

mkdir -p "$(dirname "$CADDYFILE_PATH")"
cat >"$CADDYFILE_PATH" <<EOF
:$PUBLIC_PORT {
    encode zstd gzip

    handle $FILEBROWSER_BASE_URL {
        redir $FILEBROWSER_BASE_URL/ 308
    }

    handle $FILEBROWSER_BASE_URL/* {
        reverse_proxy 127.0.0.1:$FILEBROWSER_INTERNAL_PORT
    }

    handle {
        reverse_proxy 127.0.0.1:$POCKETBASE_INTERNAL_PORT
    }
}
EOF

echo "Railway public port: $PUBLIC_PORT"
echo "PocketBase internal port: $POCKETBASE_INTERNAL_PORT"
echo "Filebrowser internal port: $FILEBROWSER_INTERNAL_PORT"
echo "Filebrowser URL path: $FILEBROWSER_BASE_URL/"

filebrowser config init -d "$FILEBROWSER_DB" >/dev/null 2>&1 || true

if filebrowser users find "$WEB_USERNAME" -d "$FILEBROWSER_DB" >/dev/null 2>&1; then
    filebrowser users update "$WEB_USERNAME" -d "$FILEBROWSER_DB" --password "$WEB_PASSWORD" --perm.admin >/dev/null
else
    filebrowser users add "$WEB_USERNAME" "$WEB_PASSWORD" -d "$FILEBROWSER_DB" --perm.admin >/dev/null
fi

POCKETBASE_PID=""
FILEBROWSER_PID=""
CADDY_PID=""

cleanup() {
    [ -n "$FILEBROWSER_PID" ] && kill "$FILEBROWSER_PID" 2>/dev/null || true
    [ -n "$POCKETBASE_PID" ] && kill "$POCKETBASE_PID" 2>/dev/null || true
    [ -n "$CADDY_PID" ] && kill "$CADDY_PID" 2>/dev/null || true
}

trap cleanup INT TERM

echo "Starting PocketBase on internal port $POCKETBASE_INTERNAL_PORT..."
pocketbase serve --http="0.0.0.0:$POCKETBASE_INTERNAL_PORT" &
POCKETBASE_PID=$!

echo "Starting Filebrowser on internal port $FILEBROWSER_INTERNAL_PORT..."
filebrowser \
    -d "$FILEBROWSER_DB" \
    -r "$PB_ROOT" \
    -a 0.0.0.0 \
    -p "$FILEBROWSER_INTERNAL_PORT" \
    -b "$FILEBROWSER_BASE_URL" &
FILEBROWSER_PID=$!

echo "Starting Caddy reverse proxy on public port $PUBLIC_PORT..."
caddy run --config "$CADDYFILE_PATH" --adapter caddyfile &
CADDY_PID=$!

while :; do
    if ! kill -0 "$POCKETBASE_PID" 2>/dev/null; then
        wait "$POCKETBASE_PID"
        exit $?
    fi

    if ! kill -0 "$FILEBROWSER_PID" 2>/dev/null; then
        wait "$FILEBROWSER_PID"
        exit $?
    fi

    if ! kill -0 "$CADDY_PID" 2>/dev/null; then
        wait "$CADDY_PID"
        exit $?
    fi

    sleep 1
done
