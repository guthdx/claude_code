# Domain Change Status: relay.netbird.iyeska.net → netbird.iyeska.net

**Date Started:** November 24, 2025
**Date Completed:** November 30, 2025
**Status:** ✅ RESOLVED - Fully Operational

---

## Executive Summary

Successfully migrated NetBird from `relay.netbird.iyeska.net` to `netbird.iyeska.net` and resolved all blocking issues. The system is now fully operational with:
- ✅ Valid Let's Encrypt SSL certificate
- ✅ All containers running without restart loops
- ✅ HTTPS dashboard accessible
- ✅ nginx/Caddy port conflicts resolved
- ✅ Docker container internet connectivity fixed

---

## What We Completed

### 1. ✅ Backup Created
- Backup file: `~/netbird-backup-before-domain-change-20251124-222803.tar.gz`
- Size: 29KB
- Location: `/home/guthdx/`

### 2. ✅ Configuration Files Updated
All occurrences of `relay.netbird.iyeska.net` changed to `netbird.iyeska.net` in:

**Critical Configuration Files:**
- `management.json` - All 14 occurrences updated (STUN, TURN, relay, auth endpoints)
- `Caddyfile` - Domain in server block updated
- `relay.env` - NB_EXPOSED_ADDRESS updated
- `dashboard.env` - All endpoint URLs updated
- `zitadel.env` - ZITADEL_EXTERNALDOMAIN updated
- `.env` - Admin credentials updated

**Documentation Files:**
- `CLAUDE.md`
- `README.md`
- `QUICK_REFERENCE.md`
- `NETBIRD_CREDENTIALS.txt`
- `PASSWORD_CHANGE_LOG.txt`
- `INSTALLATION_PROCESS.md`

### 3. ✅ DNS Verification
- Both domains resolve to 68.168.225.52 ✓
- `netbird.iyeska.net` → 68.168.225.52
- `relay.netbird.iyeska.net` → 68.168.225.52

### 4. ✅ SSL Certificate Obtained
- Valid Let's Encrypt certificate for `netbird.iyeska.net`
- Issued by: Let's Encrypt (ACME v02)
- Expires: February 28, 2026
- Certificate hash: `d3ed3433fb3bba65fbd89e713ea1f9964afbb84704004f4dcb92d7e99190fa9b`

### 5. ✅ Port Conflicts Resolved
- Disabled nginx (was occupying ports 80/443)
- Removed scorecard nginx site configuration
- Caddy now properly bound to ports 80/443 via docker-proxy

### 6. ✅ Docker Networking Fixed
- Fixed iptables `DOCKER-USER` chain (missing RETURN rule)
- Containers now have full internet connectivity
- Made iptables rules persistent across reboots

---

## Issues Encountered and Resolutions

### Issue 1: Port 80/443 Conflicts

**Problem:**
- nginx was running and occupying ports 80/443
- NetBird's Caddy container couldn't bind to these ports
- Accessing `https://netbird.iyeska.net` showed nginx welcome page instead of NetBird dashboard

**Root Cause:**
- nginx was enabled and serving default page
- Multiple nginx sites configured (n8n, scorecard, stoic) but most were redundant
- Cloudflare Tunnel already routing services directly (bypassing nginx)

**Resolution:**
```bash
# Disabled scorecard nginx site
sudo rm /etc/nginx/sites-enabled/scorecard.conf

# Stopped and disabled nginx completely
sudo systemctl stop nginx
sudo systemctl disable nginx

# Restarted NetBird so Caddy could bind to ports
cd ~/netbird && docker compose restart caddy
```

**Why nginx was redundant:**
- All services (n8n, recap, stoic, wowasi) already routed via Cloudflare Tunnel
- nginx configs were proxying to same ports Cloudflare Tunnel uses
- No active nginx-dependent services

### Issue 2: Docker Container Network Unreachable

**Problem:**
```
Error: dial udp 8.8.8.8:53: connect: network is unreachable
Error: dial tcp: lookup acme-v02.api.letsencrypt.org on 8.8.8.8:53: connect: network is unreachable
```

**Symptoms:**
- Caddy couldn't reach Let's Encrypt to obtain SSL certificate
- Management container restarting (couldn't reach Zitadel OIDC endpoint)
- Containers couldn't ping external IPs (8.8.8.8, google.com)
- Host machine COULD reach internet successfully

**Root Cause:**
- iptables `DOCKER-USER` chain was missing a `RETURN` rule
- FORWARD chain had `policy DROP` as default
- Traffic from Docker containers hit DOCKER-USER chain, then fell through to FORWARD DROP
- This blocked all forwarded packets (container → internet)

**What Was Incorrectly Suspected:**
- Initially suspected UFW (Uncomplicated Firewall) was blocking traffic
- UFW was actually **not even enabled** on the system
- The real culprit was the missing iptables rule

**Resolution:**
```bash
# Added RETURN rule to DOCKER-USER chain
sudo iptables -A DOCKER-USER -j RETURN

# Saved iptables rules
sudo mkdir -p /etc/iptables
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

# Created systemd service to restore rules on boot
sudo nano /etc/systemd/system/iptables-restore.service
# [Service content in section below]

sudo systemctl daemon-reload
sudo systemctl enable iptables-restore.service
```

**Verification:**
```bash
# Test container can reach internet
docker exec netbird-caddy-1 ping -c 2 8.8.8.8
# PING 8.8.8.8: 56 data bytes
# 64 bytes from 8.8.8.8: seq=0 ttl=117 time=38.922 ms
# 64 bytes from 8.8.8.8: seq=1 ttl=117 time=14.735 ms

# Test DNS resolution
docker exec netbird-caddy-1 ping -c 2 google.com
# PING google.com (173.194.193.100): 56 data bytes
# 64 bytes from 173.194.193.100: seq=0 ttl=105 time=24.344 ms
```

### Issue 3: Management Container Restart Loop

**Problem:**
- `netbird-management-1` constantly restarting with error:
```
failed fetching OIDC configuration from endpoint https://netbird.iyeska.net/.well-known/openid-configuration
Get "https://netbird.iyeska.net/.well-known/openid-configuration": EOF
```

**Root Cause:**
- Management depends on Zitadel's OIDC endpoint via HTTPS
- Caddy didn't have SSL certificate (due to network issue above)
- Without HTTPS, management couldn't authenticate

**Resolution:**
- Once Docker networking was fixed, Caddy obtained SSL certificate
- Management container successfully connected to Zitadel OIDC
- Container stabilized and stopped restarting

---

## Final Configuration

### iptables Persistence

**File: `/etc/systemd/system/iptables-restore.service`**
```ini
[Unit]
Description=Restore iptables rules
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
ExecStart=/sbin/ip6tables-restore /etc/iptables/rules.v6

[Install]
WantedBy=multi-user.target
```

**Enabled with:**
```bash
sudo systemctl enable iptables-restore.service
```

**Critical iptables rule (in `/etc/iptables/rules.v4`):**
```
-A DOCKER-USER -j RETURN
```

This allows Docker container traffic to pass through the FORWARD chain rules instead of hitting the DROP policy.

### Services Status (Post-Fix)

```
✅ netbird-zitadel-1      - Up
✅ netbird-zdb-1          - Up (healthy)
✅ netbird-signal-1       - Up
✅ netbird-relay-1        - Up
✅ netbird-management-1   - Up (stable, no longer restarting)
✅ netbird-dashboard-1    - Up
✅ netbird-coturn-1       - Up
✅ netbird-caddy-1        - Up (SSL cert obtained successfully)
```

### nginx Status

```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: enabled)
     Active: inactive (dead)
```

**nginx sites disabled:**
- `/etc/nginx/sites-enabled/scorecard.conf` - Removed
- `/etc/nginx/sites-enabled/n8n` - Still present but nginx disabled
- `/etc/nginx/sites-enabled/stoic.conf` - Still present but nginx disabled
- `/etc/nginx/sites-enabled/default` - Still present but nginx disabled

**Note:** nginx site configs remain in `sites-available/` for future reference, but nginx service is disabled and won't start on boot.

---

## Verification Tests

### HTTPS Dashboard
```bash
curl -I https://netbird.iyeska.net
# HTTP/2 200
# strict-transport-security: max-age=3600; includeSubDomains; preload
# x-content-type-options: nosniff
# x-frame-options: SAMEORIGIN
```

### OIDC Configuration
```bash
curl -s https://netbird.iyeska.net/.well-known/openid-configuration | jq .issuer
# "https://netbird.iyeska.net"
```

### SSL Certificate
```bash
echo | openssl s_client -connect netbird.iyeska.net:443 2>/dev/null | openssl x509 -noout -dates
# notBefore=Nov 30 12:53:08 2025 GMT
# notAfter=Feb 28 12:53:07 2026 GMT
```

### Container Logs (Caddy)
```
{"level":"debug","ts":1764510873.1738348,"logger":"tls.handshake","msg":"matched certificate in cache",
"subjects":["netbird.iyeska.net"],"managed":true,"expiration":1772242788}
```

### Port Binding
```bash
sudo ss -tlnp | grep -E ":(80|443)"
# LISTEN 0 4096   0.0.0.0:80    0.0.0.0:*    users:(("docker-proxy",pid=280204,fd=7))
# LISTEN 0 4096   0.0.0.0:443   0.0.0.0:*    users:(("docker-proxy",pid=280227,fd=7))
# LISTEN 0 4096      [::]:80       [::]:*    users:(("docker-proxy",pid=280211,fd=7))
# LISTEN 0 4096      [::]:443      [::]:*    users:(("docker-proxy",pid=280234,fd=7))
```

---

## Lessons Learned

### 1. UFW vs iptables
- UFW being installed doesn't mean it's enabled
- Check with `sudo systemctl status ufw` AND `sudo ufw status`
- iptables rules can exist even when UFW is disabled
- Docker modifies iptables directly (not through UFW)

### 2. Docker DOCKER-USER Chain
- The `DOCKER-USER` chain is specifically for user-defined firewall rules
- **Must end with `-A DOCKER-USER -j RETURN`** to pass traffic to Docker's internal chains
- Without RETURN, traffic hits the FORWARD DROP policy
- This is a common issue when iptables rules are flushed or reset

### 3. Port Conflicts
- Always check what's listening on a port before assuming service is running: `sudo ss -tlnp | grep :PORT`
- nginx can be enabled without being useful (redundant configs)
- Cloudflare Tunnel bypasses local reverse proxies entirely
- Test with `curl -I http://localhost:80` to see what's actually serving

### 4. Docker Networking Debugging
- Test container internet: `docker exec CONTAINER ping 8.8.8.8`
- Test DNS resolution: `docker exec CONTAINER ping google.com`
- Check routes: `docker exec CONTAINER ip route`
- Verify MASQUERADE in NAT table: `sudo iptables -t nat -L -n -v | grep MASQUERADE`
- Check FORWARD chain policy: `sudo iptables -L FORWARD -n -v` (should see DOCKER-USER and DOCKER-FORWARD)

### 5. Caddy SSL Certificate Acquisition
- Requires outbound HTTPS (443) to Let's Encrypt
- Requires HTTP (80) for HTTP-01 challenge validation
- Will retry with exponential backoff on failure
- Check logs: `docker logs netbird-caddy-1 | grep -i "obtain"`
- Certificate cached in `/data/caddy` volume

---

## Files Modified During Resolution

### System Files
- `/etc/nginx/sites-enabled/scorecard.conf` - Removed (symlink deleted)
- `/etc/iptables/rules.v4` - Created (iptables IPv4 rules)
- `/etc/iptables/rules.v6` - Created (iptables IPv6 rules)
- `/etc/systemd/system/iptables-restore.service` - Created (systemd service)

### nginx Service
- Stopped: `sudo systemctl stop nginx`
- Disabled: `sudo systemctl disable nginx`
- Removed from multi-user.target

### iptables Rules
- Added: `DOCKER-USER -j RETURN` rule
- Persisted via iptables-save

---

## Persists After Reboot

The following configurations will persist across reboots:

1. **nginx disabled** - Won't start automatically
2. **iptables rules restored** - Via `/etc/systemd/system/iptables-restore.service`
3. **NetBird auto-starts** - Docker Compose `restart: unless-stopped` policy
4. **SSL certificate renewed** - Caddy handles automatic renewal

---

## Commands for Future Reference

### Check Everything is Working
```bash
# Verify NetBird containers
docker ps --filter 'name=netbird' --format 'table {{.Names}}\t{{.Status}}'

# Test HTTPS access
curl -I https://netbird.iyeska.net

# Check iptables DOCKER-USER has RETURN
sudo iptables -L DOCKER-USER -n -v

# Verify nginx is disabled
systemctl is-enabled nginx  # Should show: disabled

# Test container internet connectivity
docker exec netbird-caddy-1 ping -c 2 8.8.8.8
```

### Restart NetBird
```bash
cd ~/netbird
docker compose restart
```

### View Logs
```bash
# All containers
docker compose logs -f

# Specific container
docker logs netbird-caddy-1 -f
docker logs netbird-management-1 -f
```

### If iptables Rules Get Lost
```bash
# Check if DOCKER-USER has RETURN
sudo iptables -L DOCKER-USER -n -v

# If missing, add it
sudo iptables -A DOCKER-USER -j RETURN

# Save rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Verify restore service enabled
sudo systemctl status iptables-restore.service
```

---

## Backup Information

**Original Backup (before domain change):**
```bash
~/netbird-backup-before-domain-change-20251124-222803.tar.gz
```

**Restore if needed:**
```bash
cd ~
tar xzf netbird-backup-before-domain-change-20251124-222803.tar.gz
# Note: This will restore OLD domain (relay.netbird.iyeska.net)
# You'll need to re-update configs to netbird.iyeska.net
```

---

## Access Information

**Dashboard:** https://netbird.iyeska.net
**Admin User:** admin@netbird.iyeska.net
**Credentials:** See `NETBIRD_CREDENTIALS.txt` and `.env`

**SSL Certificate Expiry:** February 28, 2026
**Auto-Renewal:** Handled by Caddy (will renew ~30 days before expiry)

---

## Related Documentation

- `NETBIRD_NGINX_PORT_CONFLICT_2025-11-30.md` - Detailed troubleshooting log
- `CLAUDE.md` - Updated with new troubleshooting procedures
- `INSTALLATION_PROCESS.md` - Original installation guide
- `QUICK_REFERENCE.md` - Quick command reference

---

**Status:** ✅ Migration Complete - All Systems Operational
**Next Review:** Monitor SSL certificate auto-renewal in late January 2026
