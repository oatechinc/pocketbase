#!/bin/sh

echo "WEB_USERNAME: $WEB_USERNAME"
echo "WEB_PASSWORD: $WEB_PASSWORD"

/filebrowser -r /pb -p 8080 --username=$WEB_USERNAME --password=$WEB_PASSWORD &

/pb/pocketbase serve --http=0.0.0.0:443 &

# 等待所有后台进程
wait
