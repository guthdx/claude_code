# NetBird Self-Hosted VPN Installation Guide

## Overview
Self-hosted NetBird VPN installation on Ubuntu 24.04.3 LTS server using domain `iyeska.net` with Cloudflare DNS.

## System Information
- **Server OS**: Ubuntu 24.04.3 LTS (Noble)
- **Server IP (LAN)**: 192.168.11.20
- **Public IP**: 68.168.225.52
- **Domain**: iyeska.net
- **NetBird Domain**: netbird.iyeska.net
- **Router**: pfSense running on Protectli device at 192.168.11.1
- **Docker Version**: 28.5.1
- **Docker Compose**: v2.40.3

## Installation Approach
**Selected Option**: Direct DNS + Port Forwarding (Option B)
- Self-hosted NetBird (not cloud)
- Minimal ongoing management
- No Cloudflare Tunnel (DNS only via Cloudflare)
- Let's Encrypt SSL certificates via Caddy

---

## Phase 1: DNS Configuration (COMPLETED ✅)

### DNS A Records Created in Cloudflare
All records pointing to `68.168.225.52` with **gray cloud (DNS only, not proxied)**:

| Hostname | Type | Value | Proxy Status |
|----------|------|-------|--------------|
| netbird.iyeska.net | A | 68.168.225.52 | DNS only (gray) |
| api.netbird.iyeska.net | A | 68.168.225.52 | DNS only (gray) |
| signal.netbird.iyeska.net | A | 68.168.225.52 | DNS only (gray) |
| relay.netbird.iyeska.net | A | 68.168.225.52 | DNS only (gray) |

### DNS Verification
```bash
dig netbird.iyeska.net +short
dig api.netbird.iyeska.net +short
dig signal.netbird.iyeska.net +short
dig relay.netbird.iyeska.net +short
```
All records resolving correctly to 68.168.225.52.

---

## Phase 2: pfSense Port Forwarding Configuration (COMPLETED ✅)

### Port Forwarding Rules
All rules forward from WAN to internal server 192.168.11.20:

| Rule Name | Protocol | WAN Port | Internal IP | Internal Port | Description |
|-----------|----------|----------|-------------|---------------|-------------|
| NetBird HTTP | TCP | 80 | 192.168.11.20 | 80 | HTTP (Let's Encrypt challenges) |
| NetBird HTTPS | TCP | 443 | 192.168.11.20 | 443 | HTTPS (Dashboard, API) |
| NetBird TURN Relay | UDP | 33073 | 192.168.11.20 | 33073 | TURN relay for NAT traversal |
| NetBird Signal | TCP | 10000 | 192.168.11.20 | 10000 | Signal server |
| NetBird Relay Service | TCP | 33080 | 192.168.11.20 | 33080 | Relay service |
| NetBird STUN/TURN | UDP | 3478 | 192.168.11.20 | 3478 | STUN/TURN server |
| NetBird Dynamic Relay | UDP | 49152-65535 | 192.168.11.20 | 49152-65535 | Dynamic port range for relay |

---

## Phase 3: Ubuntu Firewall Configuration (COMPLETED ✅)

### UFW Firewall Rules
```bash
# HTTP/HTTPS
sudo ufw allow 80/tcp comment 'NetBird HTTP'
sudo ufw allow 443/tcp comment 'NetBird HTTPS'

# Signal and TURN services
sudo ufw allow 10000/tcp comment 'NetBird Signal'
sudo ufw allow 3478/udp comment 'NetBird STUN/TURN'

# Relay services
sudo ufw allow 33073/udp comment 'NetBird TURN Relay'
sudo ufw allow 33080/tcp comment 'NetBird Relay'
sudo ufw allow 49152:65535/udp comment 'NetBird Dynamic Relay Range'

# Verify
sudo ufw status numbered
```

---

## Phase 4: NetBird Installation

### Prerequisites Verified
- ✅ Docker installed (version 28.5.1)
- ✅ Docker Compose installed (v2.40.3)
- ✅ jq installed
- ✅ nginx stopped (was using port 80, now free for Caddy)

### Installation Command
```bash
export NETBIRD_DOMAIN=netbird.iyeska.net
export NETBIRD_HTTP_PORT=80
export NETBIRD_HTTPS_PORT=443

curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh | bash
```

### Installation Directory
All NetBird files generated in: `~/netbird/`

### Generated Files
- `docker-compose.yml` - Container orchestration
- `Caddyfile` - Reverse proxy and SSL configuration
- `zitadel.env` - Zitadel identity provider config
- `dashboard.env` - Dashboard configuration
- `management.json` - Management service config
- `relay.env` - Relay service config
- `turnserver.conf` - TURN server config
- `zdb.env` - PostgreSQL database config

---

## Problems Encountered and Solutions

### Problem 1: AppArmor Corruption (RESOLVED ✅)
**Symptom**: Docker containers failing with AppArmor parser error
```
AppArmor parser error for /var/lib/docker/tmp/docker-default in profile
/etc/apparmor.d/tunables/home.d/ubuntu at line 7: Lexer found unexpected character: '' (0x0)
```

**Cause**: Corrupted file `/etc/apparmor.d/tunables/home.d/ubuntu` with null bytes

**Solution**:
```bash
sudo dpkg-reconfigure -p low apparmor
sudo systemctl start apparmor
sudo systemctl restart docker
```

**Verification**:
```bash
sudo cat /etc/apparmor.d/tunables/home.d/ubuntu
# Should show clean output without null bytes
```

---

### Problem 2: Port 80 Conflict (RESOLVED ✅)
**Symptom**: Caddy couldn't bind to port 80
```
failed to bind host port for 0.0.0.0:80:172.20.0.2:80/tcp: address already in use
```

**Cause**: nginx web server already using port 80

**Solution**:
```bash
# Identify process
sudo lsof -i :80

# Stop nginx
sudo systemctl stop nginx

# Optional: Disable nginx from auto-starting
sudo systemctl disable nginx
```

---

### Problem 3: Installation Script Timeout (CURRENT ISSUE ⚠️)
**Symptom**: Installation script times out during Zitadel initialization

**Current State**:
- ✅ SSL certificate obtained successfully from Let's Encrypt
- ✅ 3/9 containers running: caddy, zdb (PostgreSQL), zitadel
- ❌ Missing 6 containers: dashboard, management, signal, relay, coturn
- ❌ Docker DNS errors: `dial tcp: lookup dashboard on 127.0.0.11:53: server misbehaving`

**Verification**:
```bash
cd ~/netbird
docker compose ps
```

Current output shows only:
```
netbird-caddy-1     - Up 5 minutes
netbird-zdb-1       - Up 5 minutes (healthy)
netbird-zitadel-1   - Up 5 minutes
```

---

### Problem 4: Empty Configuration Files (LIKELY CAUSE)
**In previous installation attempts**, the following files were found to be empty:
- `management.json` - Completely empty (0 bytes)
- `relay.env` - Completely empty (0 bytes)

This caused management and relay containers to crash on startup with errors:
```
management: failed reading provided config file: /etc/netbird/management.json:
            unexpected end of JSON input

relay: invalid config: exposed address is required
```

---

## Next Steps to Complete Installation

### Step 1: Check if Installation Script is Still Running
```bash
ps aux | grep getting-started
```

If running, let it complete. If not running or stuck, proceed to Step 2.

### Step 2: Manually Start All Services
```bash
cd ~/netbird
docker compose up -d
```

This should pull and start all missing containers:
- netbird-dashboard-1
- netbird-management-1
- netbird-signal-1
- netbird-relay-1
- netbird-coturn-1

### Step 3: Verify All Containers Are Running
```bash
docker compose ps
```

Expected output should show 9 containers all with status "Up" or "Healthy":
```
netbird-caddy-1        Up
netbird-coturn-1       Up
netbird-dashboard-1    Up
netbird-management-1   Up
netbird-relay-1        Up
netbird-signal-1       Up
netbird-zdb-1          Up (healthy)
netbird-zitadel-1      Up
```

### Step 4: Check Container Logs for Errors
```bash
# Check all logs
docker compose logs --tail=50

# Check specific services
docker compose logs management --tail=50
docker compose logs relay --tail=50
docker compose logs dashboard --tail=50
```

### Step 5: Fix Configuration Files if Needed

If `management.json` is empty or corrupt:
```bash
cat > ~/netbird/management.json << 'EOF'
{
  "Stuns": [
    {
      "Proto": "udp",
      "URI": "stun:signal.netbird.iyeska.net:3478"
    }
  ],
  "TURNConfig": {
    "Turns": [
      {
        "Proto": "udp",
        "URI": "turn:signal.netbird.iyeska.net:3478",
        "Username": "netbird",
        "Password": ""
      }
    ]
  },
  "Signal": {
    "Proto": "https",
    "URI": "signal.netbird.iyeska.net:443"
  },
  "Datastore": {
    "Engine": "postgres"
  },
  "HttpConfig": {
    "Address": "0.0.0.0:443",
    "AuthIssuer": "https://netbird.iyeska.net/",
    "AuthAudience": "netbird",
    "OIDCConfigEndpoint": "https://netbird.iyeska.net/.well-known/openid-configuration"
  }
}
EOF
```

If `relay.env` is empty or corrupt:
```bash
cat > ~/netbird/relay.env << 'EOF'
NB_LISTEN_ADDRESS=:33080
NB_EXPOSED_ADDRESS=relay.netbird.iyeska.net:33080
NB_AUTH_SECRET=netbird-relay-secret
NB_LOG_LEVEL=info
EOF
```

After fixing configs, restart services:
```bash
docker compose restart management relay
```

### Step 6: Access NetBird Dashboard
Once all containers are running successfully, access the dashboard:

**URL**: https://netbird.iyeska.net

**Expected**: You should see the NetBird dashboard login page with Zitadel authentication.

---

## Phase 5: Initial Configuration (PENDING)

### Access Zitadel Console
If you need direct access to Zitadel for troubleshooting:

**URL**: https://netbird.iyeska.net:443/ui/console

### Complete NetBird Setup
1. Access https://netbird.iyeska.net
2. Log in with Zitadel (credentials may be in installation script output)
3. Create admin user
4. Configure NetBird network settings
5. Add first peer/device to test

### Test Peer-to-Peer Connectivity
1. Install NetBird client on test devices
2. Connect devices to NetBird network
3. Test connectivity between peers
4. Verify relay/TURN services working for NAT traversal

---

## Useful Commands

### Container Management
```bash
cd ~/netbird

# View all containers
docker compose ps

# View logs
docker compose logs --tail=100
docker compose logs -f              # Follow logs in real-time
docker compose logs caddy --tail=50 # Specific service

# Restart services
docker compose restart
docker compose restart <service>

# Stop all services
docker compose down

# Stop and remove volumes (CAUTION: Deletes data)
docker compose down --volumes

# Start all services
docker compose up -d
```

### Troubleshooting
```bash
# Check if ports are listening
sudo netstat -tlnp | grep -E ':(80|443|3478|10000|33073|33080)'

# Check firewall rules
sudo ufw status numbered

# Check DNS resolution
dig netbird.iyeska.net +short

# Test HTTPS access
curl -I https://netbird.iyeska.net

# Check SSL certificate
echo | openssl s_client -connect netbird.iyeska.net:443 -servername netbird.iyeska.net 2>/dev/null | openssl x509 -noout -dates
```

### Restart nginx (if needed later)
```bash
sudo systemctl start nginx
sudo systemctl enable nginx  # Auto-start on boot
```

---

## Current Status Summary

### ✅ Completed
1. DNS A records configured in Cloudflare
2. pfSense port forwarding rules (7 rules)
3. Ubuntu UFW firewall rules
4. Docker and Docker Compose verified
5. nginx stopped (port 80 freed)
6. NetBird installation script executed
7. SSL certificate obtained from Let's Encrypt

### ⚠️ In Progress
1. Complete container startup (only 3/9 containers running)
2. Verify all NetBird services are healthy

### 📋 Pending
1. Access NetBird dashboard
2. Complete Zitadel/NetBird initial configuration
3. Add first peer and test connectivity

---

## Additional Notes

### Security Considerations
- All traffic uses HTTPS with Let's Encrypt certificates
- Caddy handles SSL termination automatically
- Zitadel provides enterprise-grade identity management
- WireGuard protocol for secure peer-to-peer connections

### Maintenance
- SSL certificates auto-renew via Caddy
- Docker containers will auto-start on server reboot
- Regular updates: `docker compose pull && docker compose up -d`

### Backup Important Files
Before making changes, backup:
```bash
cp ~/netbird/docker-compose.yml ~/netbird/docker-compose.yml.backup
cp ~/netbird/management.json ~/netbird/management.json.backup
cp ~/netbird/relay.env ~/netbird/relay.env.backup
```

---

## Contact & Resources

- **NetBird Documentation**: https://docs.netbird.io
- **NetBird GitHub**: https://github.com/netbirdio/netbird
- **Zitadel Documentation**: https://zitadel.com/docs
- **Installation Script Source**: https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh

---

## Quick Recovery Steps

If you need to start completely fresh:

```bash
# Stop and remove everything
cd ~/netbird
docker compose down --volumes

# Remove all files
cd ~
rm -rf ~/netbird

# Start fresh installation
export NETBIRD_DOMAIN=netbird.iyeska.net
export NETBIRD_HTTP_PORT=80
export NETBIRD_HTTPS_PORT=443
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh | bash
```

---

**Last Updated**: 2025-11-04
**Installation Status**: 70% Complete - Waiting for all containers to start successfully
