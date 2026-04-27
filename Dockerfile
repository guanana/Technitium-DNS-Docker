# syntax=docker.io/docker/dockerfile:1

# Stage 1: Build
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
ARG TARGETARCH
WORKDIR /src
RUN apk add --no-cache git
RUN git clone --depth 1 https://github.com/TechnitiumSoftware/TechnitiumLibrary.git TechnitiumLibrary
COPY . DnsServer/
RUN dotnet build TechnitiumLibrary/TechnitiumLibrary.ByteTree/TechnitiumLibrary.ByteTree.csproj -c Release && \
    dotnet build TechnitiumLibrary/TechnitiumLibrary.Net/TechnitiumLibrary.Net.csproj -c Release && \
    dotnet build TechnitiumLibrary/TechnitiumLibrary.Security.OTP/TechnitiumLibrary.Security.OTP.csproj -c Release
RUN if [ "$TARGETARCH" = "arm64" ]; then RID="linux-musl-arm64"; else RID="linux-musl-x64"; fi && \
    dotnet publish DnsServer/DnsServerApp/DnsServerApp.csproj -c Release -r $RID --self-contained true -p:PublishTrimmed=true -o /app/publish

# Stage 2: Intermediate Assembly
FROM mcr.microsoft.com/dotnet/runtime-deps:9.0-alpine AS base
RUN apk add --no-cache tzdata ca-certificates icu-libs && \
    mkdir -p /etc/dns /opt/technitium/dns
COPY --from=build /app/publish /app

# Stage 3: Flatten to single layer
FROM scratch
COPY --from=base / /
WORKDIR /opt/technitium/dns

## Only append image metadata below this line:
EXPOSE \
    # Standard DNS service
    53/udp 53/tcp      \
    # DNS-over-QUIC (UDP) + DNS-over-TLS (TCP)
    853/udp 853/tcp    \
    # DNS-over-HTTPS (UDP => HTTP/3) (TCP => HTTP/1.1 + HTTP/2)
    443/udp 443/tcp    \
    # DNS-over-HTTP (for when running behind a reverse-proxy that terminates TLS)
    80/tcp 8053/tcp    \
    # Technitium web console + API (HTTP / HTTPS)
    5380/tcp 53443/tcp \
    # DHCP
    67/udp

# https://specs.opencontainers.org/image-spec/annotations/
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="Technitium DNS Server"
LABEL org.opencontainers.image.vendor="Technitium"
LABEL org.opencontainers.image.source="https://github.com/TechnitiumSoftware/DnsServer"
LABEL org.opencontainers.image.url="https://technitium.com/dns/"
LABEL org.opencontainers.image.authors="support@technitium.com"

ENTRYPOINT ["/app/DnsServerApp"]
CMD ["/etc/dns"]
