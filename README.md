<div align="center">
  <img src="https://raw.githubusercontent.com/TechnitiumSoftware/DnsServer/master/DnsServerApp/wwwroot/images/logo.png" alt="Technitium Logo" width="128">
  
  # Technitium DNS Server - Optimized Alpine Docker Image
  
  **Lightweight** • **Single-Layer** • **Under 60MB**

  [![Docker Build & Publish](https://github.com/guanana/Technitium-DNS-Docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/guanana/Technitium-DNS-Docker/actions/workflows/docker-publish.yml)
</div>

---

This repository houses an automated workflow to build an alternative, highly optimized Alpine Linux Docker image for the open-source **[Technitium DNS Server](https://technitium.com/dns/)**.

By employing `.NET` trimming and advanced multi-stage layer squashing, this project delivers the fully-featured DNS Server inside a featherweight **~59MB single-layer image** instead of the official ~175MB multi-layer container.

## ⚖️ The Architecture Compromise
Achieving a sub-50MB final footprint requires dropping heavily bloated system dependencies.

**The Trade-off:**
The official Technitium container is based on Debian because it requires the `libmsquic` and `dnsutils` apt packages to support **DNS-over-QUIC**. Unfortunately, including `libmsquic` bloats the image to ~175MB because it demands a slew of heavy system libraries (krb5, numactl, openssl modules, etc.).

**The Alpine Solution:**  
To slash the image size, this custom build strips out `libmsquic` and builds natively on Alpine Linux. 
* **Pros**: Blistering fast startup times, radically smaller cache/pull sizes (~43MB), minimal attack surface (Alpine-based, exactly 1 consolidated layer).
* **Cons**: **DNS-over-QUIC is disabled.** (Standard DNS, DNS-over-HTTPS, and DNS-over-TLS remain fully supported).

If you are running the DNS server in a home lab or a behind a reverse-proxy (e.g., Traefik/Nginx) where standard DNS (UDP 53) or DoH via HTTP/1.1 is sufficient, this image is perfect for you.

## ⚙️ How Automation Works
This repository is entirely self-updating thanks to a zero-maintenance CI pipeline. You never need to manually build the image.

The `.github/workflows/docker-publish.yml` GitHub Action handles everything automatically:
1. **Daily Scheduler**: Every night at midnight UTC, a cron job spins up to check for updates.
2. **Upstream Sync**: The pipeline checks out the master branch directly from the official `TechnitiumSoftware/DnsServer` repository, securing their bleeding-edge code.
3. **Optimized Injection**: The pipeline forces its highly optimized, single-layer `Dockerfile` over top of the official one.
4. **Publish to GHCR**: It builds via Docker Buildx and pushes the compressed image straight to this repository's GitHub Container Registry (GHCR).

## 🚀 Usage

You can safely run this image using the standard Docker commands or docker-compose files you'd use for the official binary. 

*Simply swap the image repository to this GitHub fork.*

### Docker Compose Example:
```yaml
services:
  technitium:
    # Use the optimized Alpine single-layer image
    image: ghcr.io/guanana/technitium-dns-docker:latest
    container_name: dns-server
    hostname: dns-server
    restart: unless-stopped
    ports:
      - "5380:5380/tcp"    # Web UI HTTP
      - "53:53/udp"        # DNS UDP
      - "53:53/tcp"        # DNS TCP
      - "853:853/udp"      # DNS-over-QUIC (UDP) (Unsupported in this build - port exposed safely)
      - "853:853/tcp"      # DNS-over-TLS (TCP)
      - "443:443/udp"      # DNS-over-HTTPS (UDP/QUIC)
      - "443:443/tcp"      # DNS-over-HTTPS (TCP)
    environment:
      - DNS_SERVER_DOMAIN=dns-server
    volumes:
      - config:/etc/dns
    sysctls:
      - net.ipv4.ping_group_range=0 2147483647

volumes:
    config:
```

---
*Disclaimer: This repository is an unofficial fork aimed strictly at DevOps optimization and sizing constraints. For support regarding the DNS Server application itself, please refer to the official [Technitium repository](https://github.com/TechnitiumSoftware/DnsServer).*
