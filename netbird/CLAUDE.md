# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **NetBird self-hosted VPN installation** deployed via Docker Compose. NetBird is a WireGuard-based VPN platform that provides secure peer-to-peer connectivity. This installation was completed on November 5, 2025.

**✅ IMPORTANT - Domain Migration Completed (Nov 30, 2025):**
- Successfully migrated from relay.netbird.iyeska.net → netbird.iyeska.net
- All issues resolved (nginx port conflicts, Docker networking, SSL certificates)
- See `DOMAIN_CHANGE_STATUS.md` for full migration details
- See `NETBIRD_NGINX_PORT_CONFLICT_2025-11-30.md` for troubleshooting details

**Target URL:** https://netbird.iyeska.net
**Status:** Fully Operational

## Architecture

### Core Components

The system consists of 8 containerized services orchestrated by Docker Compose:

1. **Caddy** - Reverse proxy handling HTTPS termination and routing
   - Routes requests to appropriate backend services
   - Handles automatic HTTPS via Let's Encrypt
   - Configured via `Caddyfile` with security headers and service-specific reverse proxy rules

2. **Dashboard** - Web UI for NetBird management
   - Accessed at https://netbird.iyeska.net
   - Configuration in `dashboard.env`

3. **Management** - Core NetBird management API
   - Central service coordinating peers, networks, and policies
   - Configuration in `management.json` (contains STUN/TURN config, auth endpoints, relay settings)
   - Uses Zitadel for authentication (OIDC)

4. **Signal** - WebRTC signaling server
   - Facilitates peer-to-peer connection establishment
   - Handles gRPC and WebSocket connections

5. **Relay** - NetBird relay server for NAT traversal
   - Used when direct peer connections fail
   - Configuration in `relay.env`
   - Uses relay protocol over HTTPS (rels://)

6. **Coturn** - TURN/STUN server for NAT traversal
   - Runs in `network_mode: host` (bypasses Docker networking)
   - Configuration in `turnserver.conf`
   - Handles UDP port range 49152-65535 for TURN

7. **Zitadel** - Identity provider (IdP)
   - Provides OAuth2/OIDC authentication
   - Version: v2.64.1
   - Backed by PostgreSQL database
   - Machine key stored in `machinekey/` directory

8. **zdb** - PostgreSQL database for Zitadel
   - Version: postgres:16-alpine
   - Persistent storage via `netbird_zdb_data` volume
   - Configuration in `zdb.env`

### Service Communication

- All services (except coturn) communicate via the `netbird` Docker network
- Caddy routes external HTTPS traffic to internal HTTP services
- Zitadel handles authentication for Management API
- Services use container names for DNS resolution (Docker internal DNS)

### Key Configuration Files

- `docker-compose.yml` - Service definitions and orchestration
- `management.json` - Management service configuration (auth, STUN/TURN, relay)
- `Caddyfile` - Reverse proxy routing and security headers
- `turnserver.conf` - Coturn TURN/STUN server settings
- `*.env` files - Environment variables for each service (dashboard, relay, zitadel, zdb)
- `.env` - Contains admin credentials (SENSITIVE)

## Common Commands

### Service Management

```bash
# View running containers
docker ps | grep netbird

# Restart all services
cd ~/netbird && docker-compose restart

# Stop all services
cd ~/netbird && docker-compose down

# Start all services
cd ~/netbird && docker-compose up -d

# Restart specific service
docker restart netbird-management-1
```

### Viewing Logs

```bash
# Follow logs for management service
docker logs netbird-management-1 -f

# View last 20 lines
docker logs netbird-management-1 --tail 20

# Check Caddy logs (for HTTPS/routing issues)
docker logs netbird-caddy-1 -f

# Check Zitadel logs (for auth issues)
docker logs netbird-zitadel-1 -f
```

### Debugging

```bash
# Check port 443 is listening
ss -tlnp | grep :443

# Verify SSL certificate
echo | openssl s_client -connect netbird.iyeska.net:443 2>/dev/null | openssl x509 -noout -dates

# Check container health
docker ps --filter "name=netbird" --format "table {{.Names}}\t{{.Status}}"

# Inspect Docker network
docker network inspect netbird_netbird
```

### Backup

```bash
# Create timestamped backup
tar czf ~/netbird-backup-$(date +%Y%m%d).tar.gz ~/netbird/

# Important: Backup includes sensitive credentials in .env and management.json
```

## Important Implementation Details

### Domain and Certificates

- **Domain**: netbird.iyeska.net
- **Original domain** (netbird.iyeska.net) hit Let's Encrypt rate limit (5 certs/week)
- Caddy handles automatic HTTPS certificate provisioning
- HSTS enabled with 1-hour max-age (set to 3600 for testing, not 2 years yet)

### Authentication Flow

- Management service uses Zitadel for OIDC authentication
- Two auth flows configured:
  1. **Device Authorization Flow** - For CLI clients
  2. **PKCE Authorization Flow** - For web/mobile apps with redirect URLs
- Auth audience: `345364864828506116`
- Service account: `netbird-service-account` (credentials in `management.json`)

### Network Configuration

- **External IP**: 68.168.225.52 (configured in `turnserver.conf`)
- **NAT Reflection**: Enabled in pfSense for internal access to public domain
- **coturn** runs in host networking mode - cannot use Docker internal networking
- Port forwarding configured for 443/TCP, 443/UDP, 3478/UDP, and TURN range

### Secrets and Credentials

**CRITICAL**: The following files contain sensitive data:
- `.env` - Admin username and password
- `management.json` - Relay secret, data store encryption key, client secrets
- `turnserver.conf` - TURN credentials
- `machinekey/zitadel-admin-sa.token` - Zitadel service account token

Never commit these files or include them in public documentation.

### Port Mapping

- **80/TCP** - HTTP (redirects to HTTPS)
- **443/TCP** - HTTPS (Dashboard, API, all services)
- **443/UDP** - HTTP/3 / QUIC
- **3478/UDP** - STUN
- **10000/TCP** - Signal gRPC (internal)
- **33073/UDP** - Signal WebRTC (internal)
- **49152-65535/UDP** - TURN port range

### Docker Volumes

Persistent data stored in named volumes:
- `netbird_management` - Management service data (/var/lib/netbird)
- `netbird_zdb_data` - PostgreSQL database
- `netbird_caddy_data` - Caddy certificates and data
- `netbird_zitadel_certs` - Zitadel certificates

## Known Issues and Solutions

### Management Container Restarting

Check logs to identify auth or configuration issues:
```bash
docker logs netbird-management-1 --tail 50
```

Common causes:
- Zitadel not ready (wait for zdb health check)
- Invalid `management.json` configuration
- Auth endpoint unreachable

### Dashboard Inaccessible

1. Check Caddy is running and has valid certificates
2. Verify DNS resolves to correct IP
3. Check firewall allows 443/TCP and 443/UDP
4. Verify NAT reflection enabled if accessing from internal network

### Container-to-Container Communication

- **Do NOT** add `/etc/hosts` entries for inter-container communication
- Containers resolve each other via Docker's internal DNS using service names
- Only coturn uses host networking and needs external IP configuration

### Docker Container Internet Connectivity Issues

If containers cannot reach the internet (e.g., Caddy can't obtain SSL certificates):

```bash
# Test container connectivity
docker exec netbird-caddy-1 ping -c 2 8.8.8.8

# Check DOCKER-USER iptables chain
sudo iptables -L DOCKER-USER -n -v
# Must show: RETURN rule

# If missing, add it
sudo iptables -A DOCKER-USER -j RETURN

# Save rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Restart containers
cd ~/netbird && docker compose restart
```

**Root cause:** Docker requires `DOCKER-USER` chain to end with `-j RETURN` rule. Without it, traffic hits the FORWARD DROP policy and blocks container internet access.

**Persistence:** iptables rules are restored on boot via `/etc/systemd/system/iptables-restore.service`

### nginx Port Conflicts

If accessing `https://netbird.iyeska.net` shows nginx page instead of NetBird:

```bash
# Check what's on port 80/443
sudo ss -tlnp | grep -E ":(80|443)"

# If nginx is running, stop and disable it
sudo systemctl stop nginx
sudo systemctl disable nginx

# Restart NetBird's Caddy
cd ~/netbird && docker compose restart caddy

# Verify Caddy is now listening
sudo ss -tlnp | grep -E ":(80|443)"
# Should show docker-proxy processes
```

**Context:** Cloudflare Tunnel routes services directly to localhost ports, making nginx redundant. NetBird's Caddy needs ports 80/443 for HTTPS and Let's Encrypt certificate validation.

**See also:** `NETBIRD_NGINX_PORT_CONFLICT_2025-11-30.md` for detailed troubleshooting

## Development Workflow

### Modifying Configuration

1. Edit relevant configuration file (`.env`, `management.json`, `Caddyfile`, etc.)
2. Restart affected service: `docker-compose restart <service>`
3. Check logs to verify change took effect
4. For Caddy changes, configuration reloads automatically

### Testing Changes

```bash
# Test auth endpoints
curl -k https://netbird.iyeska.net/.well-known/openid-configuration

# Test management API (requires auth token)
curl -H "Authorization: Bearer <token>" https://netbird.iyeska.net/api/peers

# Check service health
docker-compose ps
```

### Emergency Recovery

If the system becomes unrecoverable:
```bash
# Stop and remove all containers and volumes
cd ~/netbird && docker-compose down -v

# Restore from backup
tar xzf ~/netbird-backup-YYYYMMDD.tar.gz -C ~/

# Or reinstall from scratch
export NETBIRD_DOMAIN=netbird.iyeska.net
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh -o netbird-install.sh
bash netbird-install.sh
```

## Additional Resources

- **Dashboard**: https://netbird.iyeska.net
- **Admin User**: admin@netbird.iyeska.net
- **Installation Documentation**: INSTALLATION_PROCESS.md (15-page detailed guide)
- **Quick Reference**: QUICK_REFERENCE.md
- **NetBird Official Docs**: https://docs.netbird.io/
- **GitHub Repository**: https://github.com/netbirdio/netbird
