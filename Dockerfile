FROM filebrowser/filebrowser:latest

ARG PB_VERSION=0.22.19

RUN apk add --no-cache \
    unzip \
    ca-certificates

# download and unzip PocketBase
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/

EXPOSE 443
EXPOSE 8080

ARG WEB_PASSWORD
ARG WEB_USERNAME

ENV WEB_PASSWORD=${WEB_PASSWORD}
ENV WEB_USERNAME=${WEB_USERNAME}

# copy start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# start PocketBase and filebrowser via start.sh
ENTRYPOINT ["/start.sh"]
