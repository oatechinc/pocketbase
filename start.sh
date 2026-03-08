#!/bin/sh

set -eu

PB_ROOT="/pb"
FILEBROWSER_PORT="${PORT:-8080}"
POCKETBASE_PORT="${POCKETBASE_PORT:-8090}"

mkdir -p "$PB_ROOT"
cd "$PB_ROOT"

echo "WEB_USERNAME: ${WEB_USERNAME:-}"
echo "PORT (provided by Railway): ${PORT:-}"

# Filebrowser and PocketBase are installed into PATH by the image build.
if ! command -v filebrowser >/dev/null 2>&1; then
    echo "filebrowser binary not found in PATH" >&2
    exit 1
fi

if ! command -v pocketbase >/dev/null 2>&1; then
    echo "pocketbase binary not found in PATH" >&2
    exit 1
fi

if [ -n "${WEB_USERNAME:-}" ] && [ -n "${WEB_PASSWORD:-}" ]; then
    filebrowser config init || true
    filebrowser users add "$WEB_USERNAME" "$WEB_PASSWORD" || true
else
    echo "Skipping Filebrowser user creation because WEB_USERNAME or WEB_PASSWORD is unset."
fi

echo "Starting Filebrowser on port $FILEBROWSER_PORT..."
filebrowser -r "$PB_ROOT" -a 0.0.0.0 -p "$FILEBROWSER_PORT" &
FILEBROWSER_PID=$!

echo "Starting PocketBase on port $POCKETBASE_PORT..."
pocketbase serve --http="0.0.0.0:$POCKETBASE_PORT" &
POCKETBASE_PID=$!

cleanup() {
    kill "$FILEBROWSER_PID" "$POCKETBASE_PID" 2>/dev/null || true
}

trap cleanup INT TERM

while :; do
    if ! kill -0 "$FILEBROWSER_PID" 2>/dev/null; then
        wait "$FILEBROWSER_PID"
        exit $?
    fi

    if ! kill -0 "$POCKETBASE_PID" 2>/dev/null; then
        wait "$POCKETBASE_PID"
        exit $?
    fi

    sleep 1
done
