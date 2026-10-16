# syntax=docker/dockerfile:1
#
# Builds both halves of BuildQuantify from the repository root:
#
#   docker build --target backend  -t buildquantify-backend  .
#   docker build --target frontend -t buildquantify-frontend .
#
# docker-compose.yml builds both. Each image builds for the machine it
# runs on, so the same file works on Intel/AMD and ARM (Oracle Ampere).

ARG FLUTTER_VERSION=3.47.7

# ---------------------------------------------------------------------
# Backend: the Dart API, compiled ahead of time.

FROM dart:stable AS backend-build
WORKDIR /src
COPY backend/pubspec.yaml backend/pubspec.lock ./
RUN dart pub get
COPY backend/bin bin
COPY backend/lib lib
RUN mkdir -p /out \
 && dart pub get --offline \
 && dart compile exe bin/server.dart -o /out/server \
 && dart compile exe bin/admin.dart -o /out/admin

FROM debian:bookworm-slim AS backend
# CA certificates for HTTPS to Google and TLS to Gmail, taken from the
# build image so no package download is needed here.
COPY --from=backend-build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=backend-build /out/server /usr/local/bin/server
COPY --from=backend-build /out/admin /usr/local/bin/admin
USER 10001:10001
EXPOSE 8080
CMD ["server"]

# ---------------------------------------------------------------------
# Frontend: the Flutter web app, built here and served by nginx, which
# also passes /api/ to the backend.

# The Dart image already has git, curl and unzip: all Flutter needs.
FROM dart:stable AS frontend-build
ARG FLUTTER_VERSION
RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" \
      https://github.com/flutter/flutter.git /flutter
ENV PATH=/flutter/bin:$PATH
RUN flutter config --no-analytics --no-cli-animations \
 && flutter precache --web --no-android --no-ios
WORKDIR /app
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get
COPY frontend/ ./
# The app calls the API at its own address under /api, so it works on
# any domain without CORS. GOOGLE_CLIENT_ID turns Google sign-in on.
ARG API_URL=/api
ARG GOOGLE_CLIENT_ID=
RUN flutter build web --release --no-web-resources-cdn \
      --dart-define=API_URL="${API_URL}" \
      --dart-define=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID}"

FROM nginx:1.27-alpine AS frontend
COPY --from=frontend-build /app/build/web /usr/share/nginx/html
COPY deploy/nginx/ /etc/nginx/buildquantify/
RUN mv /etc/nginx/buildquantify/40-buildquantify.sh /docker-entrypoint.d/ \
 && chmod +x /docker-entrypoint.d/40-buildquantify.sh \
 && mkdir -p /var/www/certbot
EXPOSE 80 443
