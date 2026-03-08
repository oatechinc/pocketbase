# Stage 1: Grab the filebrowser binary
FROM filebrowser/filebrowser:latest AS fb-base

# Stage 2: Build the final image using Alpine
FROM alpine:latest

ARG PB_VERSION=0.22.19

# Install dependencies
RUN apk add --no-cache \
    caddy \
    unzip \
    ca-certificates

# Copy Filebrowser from Stage 1 (Fixed path!)
COPY --from=fb-base /bin/filebrowser /usr/local/bin/filebrowser

# Download, unzip, and place PocketBase, then clean up the zip file
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /tmp/pb && \
    mv /tmp/pb/pocketbase /usr/local/bin/pocketbase && \
    rm -rf /tmp/pb /tmp/pb.zip

EXPOSE 443 8080

ARG WEB_USERNAME
ARG PORT

ENV WEB_USERNAME=${WEB_USERNAME}
ENV PORT=${PORT}

# Copy start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Start PocketBase and Filebrowser via start.sh
ENTRYPOINT ["/start.sh"]
