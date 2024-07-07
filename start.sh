/filebrowser -r /pb -p 8080 &

# 启动第二个服务
/pb/pocketbase serve --http=0.0.0.0:443 &

# 等待所有后台进程
wait -n
