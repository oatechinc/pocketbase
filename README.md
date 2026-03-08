# Pocketbase on Railway

Open Source backend for your next SaaS and Mobile app in 1 file.

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/XfUmjI?referralCode=faraz)

## Runtime behavior

- PocketBase is exposed on the Railway public domain.
- Filebrowser is exposed at `/files/` through an internal reverse proxy.
- Persisted data should be mounted to `/pb`.

## Required Railway variables

- `WEB_USERNAME`
- `WEB_PASSWORD`

## Optional Railway variables

- `POCKETBASE_INTERNAL_PORT` defaults to `8090`
- `FILEBROWSER_INTERNAL_PORT` defaults to `8091`
