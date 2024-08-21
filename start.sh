#!/bin/sh

# 僅當 /pb/pocketbase 不存在時才移動內容
if [ ! -f "/pb/pocketbase" ]; then
    mv /tmp/pb/* /pb/  # 移動 /tmp/pb 中的所有內容到 /pb
    if [ $? -ne 0 ]; then
        echo "Failed to move PocketBase contents" >&2
        exit 1
    fi
fi

echo "WEB_USERNAME: $WEB_USERNAME"
echo "WEB_PASSWORD: $WEB_PASSWORD"
echo "PORT: $PORT"

/filebrowser config init
/filebrowser users add $WEB_USERNAME $WEB_PASSWORD


/filebrowser -r /pb -p 8080 &

/pb/pocketbase serve --http=0.0.0.0:$PORT &

# 等待所有后台进程
wait
