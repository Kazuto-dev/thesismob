# The API, compiled ahead of time. Builds for the machine it runs on, so
# the same file works on Intel/AMD and on ARM (Oracle Ampere) servers.
FROM dart:stable AS build
WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get
COPY bin bin
COPY lib lib
RUN mkdir -p /out \
 && dart pub get --offline \
 && dart compile exe bin/server.dart -o /out/server \
 && dart compile exe bin/admin.dart -o /out/admin

FROM debian:bookworm-slim
# CA certificates for HTTPS to Google and TLS to the mail server, taken
# from the build image so no package download is needed here.
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /out/server /usr/local/bin/server
COPY --from=build /out/admin /usr/local/bin/admin
# An unprivileged user.
USER 10001:10001
EXPOSE 8080
CMD ["server"]
