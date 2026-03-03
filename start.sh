#!/bin/sh

# Ensure the script exits on failure
set -e 

# Move PocketBase contents if it doesn't already exist
if [ ! -f "/pb/pocketbase" ]; then
    echo "Initializing PocketBase directory..."
    mv /tmp/pb/* /pb/
    if [ $? -ne 0 ]; then
        echo "Failed to move PocketBase contents" >&2
        exit 1
    fi
fi

echo "WEB_USERNAME: $WEB_USERNAME"
echo "PORT (provided by Railway): $PORT"

# Initialize Filebrowser config
/filebrowser config init || true # Prevent script exit if already initialized
/filebrowser users add $WEB_USERNAME $WEB_PASSWORD || true

# Important: Railway expects your app to listen on $PORT and 0.0.0.0
# We will assign Railway's port to Filebrowser
FILEBROWSER_PORT=${PORT:-8080} 

# We will run PocketBase on a different local port (e.g., 8090)
POCKETBASE_PORT=8090

# Start Filebrowser in the background, listening on 0.0.0.0 and Railway's $PORT
echo "Starting Filebrowser on port $FILEBROWSER_PORT..."
/filebrowser -r /pb -a 0.0.0.0 -p $FILEBROWSER_PORT &

# Start PocketBase in the background, listening on 0.0.0.0 and port 8090
echo "Starting PocketBase on port $POCKETBASE_PORT..."
/pb/pocketbase serve --http=0.0.0.0:$POCKETBASE_PORT &

# Wait for any process to exit
# This ensures the Docker container stays alive as long as both processes are running
wait -n

# Exit with status of process that exited first
exit $?
