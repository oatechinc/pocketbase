FROM filebrowser/filebrowser:latest

ARG PB_VERSION=0.22.14

RUN apk add --no-cache \
    unzip \
    ca-certificates

# download and unzip PocketBase
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/

EXPOSE 443
EXPOSE 8080

# start PocketBase
CMD ["-r", "/pb", "-p", "8080", "; /pb/pocketbase serve --http=0.0.0.0:443"]
