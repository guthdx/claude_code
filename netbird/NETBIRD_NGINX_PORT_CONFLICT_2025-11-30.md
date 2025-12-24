# NetBird nginx Port Conflict Resolution

**Date:** November 30, 2025
**Issue:** NetBird dashboard showing nginx welcome page instead of NetBird UI
**Root Causes:**
1. nginx occupying ports 80/443
2. Missing iptables DOCKER-USER RETURN rule blocking container internet access

**Status:** ✅ RESOLVED

---

## Problem Statement

When accessing `https://netbird.iyeska.net`, the server was displaying the nginx welcome page instead of the NetBird dashboard. This occurred after a domain migration from `relay.netbird.iyeska.net` to `netbird.iyeska.net`.

### Initial Symptoms

1. `https://netbird.iyeska.net` showed nginx default page
2. NetBird Caddy container couldn't bind to ports 80/443
3. `netbird-management-1` container in restart loop
4. Caddy logs showing "network is unreachable" errors when trying to obtain SSL certificate

---

## Diagnostic Process

### Phase 1: Identify What's Serving Port 80/443

```bash
# Check what's listening on ports 80/443
sudo ss -tlnp | grep -E ":(80|443)"
# Result: nginx processes bound to ports 80 and 443

# Test what's actually serving
curl -I http://localhost:80
# Result: nginx/1.24.0 (Ubuntu) - showing nginx welcome page
```

**Finding:** nginx was actively serving on ports 80/443, preventing Caddy from binding.

### Phase 2: Check nginx Configuration

```bash
# List enabled nginx sites
ls -la /etc/nginx/sites-enabled/
# Result: default, n8n, scorecard.conf, stoic.conf

# Check Cloudflare Tunnel configuration
cat ~/.cloudflared/config.yml
# Result: All services (n8n, stoic, etc.) already routed via Cloudflare Tunnel
```

**Finding:** nginx configurations were redundant. Cloudflare Tunnel was already handling routing for all services directly to localhost ports, bypassing nginx entirely.

### Phase 3: Check NetBird Docker Status

```bash
# Check NetBird containers
cd ~/netbird && docker compose ps
# Result: All containers running, but management-1 restarting

# Check Caddy logs
docker logs netbird-caddy-1 --tail=50
# Result: "dial udp 8.8.8.8:53: connect: network is unreachable"
```

**Finding:** Caddy couldn't reach the internet to obtain SSL certificates from Let's Encrypt.

### Phase 4: Test Container Networking

```bash
# Test container internet connectivity
docker exec netbird-caddy-1 ping -c 2 8.8.8.8
# Result: "ping: sendto: Network unreachable"

# Test host internet connectivity
ping -c 2 8.8.8.8
# Result: SUCCESS - host can reach internet

# Check container routing
docker exec netbird-caddy-1 ip route
# Result: default via 172.21.0.1 dev eth0 (route exists)

# Traceroute from container
docker exec netbird-caddy-1 traceroute -n -m 3 8.8.8.8
# Result: FAILED initially, then SUCCESS after iptables fix
```

**Finding:** Docker containers couldn't reach the internet despite having correct routing configuration.

### Phase 5: iptables Analysis

```bash
# Check FORWARD chain policy
sudo iptables -L FORWARD -n -v
# Result: Chain FORWARD (policy DROP)

# Check DOCKER-USER chain
sudo iptables -L DOCKER-USER -n -v
# Result: Empty chain (no rules)

# Check if UFW is enabled
sudo ufw status
# Result: "Firewall not enabled (skipping reload)"
```

**Finding:**
- FORWARD chain has DROP policy
- DOCKER-USER chain was empty (missing RETURN rule)
- UFW was NOT enabled (wasn't the culprit)
- Traffic from containers hits DOCKER-USER → falls through → hits FORWARD DROP

---

## Root Cause Analysis

### Issue 1: nginx Port Conflict

**Why it happened:**
- nginx was installed and enabled for previous projects (n8n, scorecard, stoic)
- When Cloudflare Tunnel was set up, it bypassed nginx by routing directly to localhost ports
- nginx became redundant but remained running
- When NetBird was installed, Caddy couldn't bind to ports 80/443

**Architecture conflict:**
```
Before (redundant):
Internet → Cloudflare Tunnel → nginx → localhost:PORT

After Cloudflare Tunnel (nginx redundant):
Internet → Cloudflare Tunnel → localhost:PORT
                └→ nginx still running but unused

NetBird needs:
Internet → Caddy (ports 80/443) → NetBird services
```

### Issue 2: Docker Container Internet Blockage

**Why it happened:**
- The `DOCKER-USER` chain is a hook for user-defined iptables rules
- It **must** end with `-j RETURN` to pass traffic back to Docker's internal chains
- Without RETURN, traffic falls through to the FORWARD chain
- FORWARD chain has `policy DROP`, blocking all forwarded packets
- This prevented containers from reaching the internet

**Traffic flow:**
```
Container → DOCKER-USER (empty, no RETURN)
         → Falls through to FORWARD DROP
         → Packet blocked ❌

With fix:
Container → DOCKER-USER (-j RETURN)
         → DOCKER-FORWARD → DOCKER-CT/DOCKER-BRIDGE
         → MASQUERADE in NAT
         → Internet ✅
```

---

## Resolution Steps

### Step 1: Disable nginx

```bash
# Remove scorecard nginx site
sudo rm /etc/nginx/sites-enabled/scorecard.conf

# Stop nginx
sudo systemctl stop nginx

# Disable nginx from starting on boot
sudo systemctl disable nginx
# Output: Removed "/etc/systemd/system/multi-user.target.wants/nginx.service"

# Verify nginx is stopped
systemctl is-active nginx
# Output: inactive
```

**Why nginx was safe to disable:**
- All services routed via Cloudflare Tunnel (n8n, recap, stoic, wowasi)
- nginx configs were proxying to same ports Cloudflare uses
- No active services depending on nginx

### Step 2: Fix iptables DOCKER-USER Chain

```bash
# Add RETURN rule to DOCKER-USER
sudo iptables -A DOCKER-USER -j RETURN

# Verify rule was added
sudo iptables -L DOCKER-USER -n -v
# Output: Chain DOCKER-USER (1 references)
#         pkts bytes target  prot opt in  out  source   destination
#            0     0 RETURN  0    --  *   *    0.0.0.0/0 0.0.0.0/0
```

**Verification:**
```bash
# Test container can ping internet
docker exec netbird-caddy-1 ping -c 2 8.8.8.8
# PING 8.8.8.8 (8.8.8.8): 56 data bytes
# 64 bytes from 8.8.8.8: seq=0 ttl=117 time=38.922 ms
# 64 bytes from 8.8.8.8: seq=1 ttl=117 time=14.735 ms
# SUCCESS! ✅

# Test DNS resolution
docker exec netbird-caddy-1 ping -c 2 google.com
# PING google.com (173.194.193.100): 56 data bytes
# 64 bytes from 173.194.193.100: seq=0 ttl=105 time=24.344 ms
# SUCCESS! ✅
```

### Step 3: Make iptables Rules Persistent

```bash
# Create iptables config directory
sudo mkdir -p /etc/iptables

# Save current rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6

# Create systemd service for automatic restore
sudo nano /etc/systemd/system/iptables-restore.service
```

**Service content:**
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

```bash
# Enable service
sudo systemctl daemon-reload
sudo systemctl enable iptables-restore.service
# Output: Created symlink /etc/systemd/system/multi-user.target.wants/iptables-restore.service
```

### Step 4: Restart NetBird Services

```bash
# Restart all NetBird containers
cd ~/netbird
docker compose restart

# Wait for startup (10 seconds)
sleep 10

# Check container status
docker ps --filter 'name=netbird' --format 'table {{.Names}}\t{{.Status}}'
```

**Result:**
```
NAMES                  STATUS
netbird-zitadel-1      Up
netbird-zdb-1          Up (healthy)
netbird-coturn-1       Up
netbird-caddy-1        Up
netbird-dashboard-1    Up
netbird-relay-1        Up
netbird-signal-1       Up
netbird-management-1   Up  (no longer restarting!)
```

### Step 5: Verify SSL Certificate Acquisition

```bash
# Check Caddy logs for certificate
docker logs netbird-caddy-1 --tail=30 | grep -i certificate
# Output: "matched certificate in cache","subjects":["netbird.iyeska.net"],"managed":true
```

**SSL Certificate Details:**
- Domain: `netbird.iyeska.net`
- Issuer: Let's Encrypt (ACME v02)
- Expires: February 28, 2026
- Auto-renewal: Managed by Caddy

---

## Verification Tests

### Test 1: HTTPS Dashboard Access

```bash
curl -I https://netbird.iyeska.net
```

**Expected Output:**
```
HTTP/2 200
alt-svc: h3=":443"; ma=2592000
strict-transport-security: max-age=3600; includeSubDomains; preload
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
```

✅ **Result:** PASS - Dashboard accessible with proper security headers

### Test 2: OIDC Configuration Endpoint

```bash
curl -s https://netbird.iyeska.net/.well-known/openid-configuration | jq .issuer
```

**Expected Output:**
```json
"https://netbird.iyeska.net"
```

✅ **Result:** PASS - OIDC endpoint working

### Test 3: SSL Certificate Validation

```bash
echo | openssl s_client -connect netbird.iyeska.net:443 2>/dev/null | openssl x509 -noout -dates
```

**Expected Output:**
```
notBefore=Nov 30 12:53:08 2025 GMT
notAfter=Feb 28 12:53:07 2026 GMT
```

✅ **Result:** PASS - Valid SSL certificate

### Test 4: Port Binding

```bash
sudo ss -tlnp | grep -E ":(80|443)"
```

**Expected Output:**
```
LISTEN  0  4096  0.0.0.0:80     0.0.0.0:*    users:(("docker-proxy",pid=280204,fd=7))
LISTEN  0  4096  0.0.0.0:443    0.0.0.0:*    users:(("docker-proxy",pid=280227,fd=7))
```

✅ **Result:** PASS - Caddy (via docker-proxy) listening on ports 80/443

### Test 5: Container Internet Connectivity

```bash
docker exec netbird-caddy-1 ping -c 2 8.8.8.8
docker exec netbird-caddy-1 ping -c 2 google.com
```

✅ **Result:** PASS - Both pings successful

### Test 6: Management Container Stability

```bash
docker ps --filter 'name=netbird-management' --format '{{.Status}}'
```

**Expected Output:**
```
Up 5 minutes
```

✅ **Result:** PASS - No longer restarting

---

## Post-Resolution Configuration

### nginx Status

```bash
systemctl status nginx
```

**Output:**
```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: enabled)
     Active: inactive (dead)
```

- Service: **disabled** (won't start on boot)
- State: **inactive** (not running)
- Config files: Remain in `/etc/nginx/sites-available/` for reference
- Enabled sites: None (scorecard removed, nginx disabled)

### iptables Configuration

**Critical rule in `/etc/iptables/rules.v4`:**
```
-A DOCKER-USER -j RETURN
```

**Auto-restore service:**
```bash
systemctl status iptables-restore.service
```

**Output:**
```
○ iptables-restore.service - Restore iptables rules
     Loaded: loaded (/etc/systemd/system/iptables-restore.service; enabled; preset: enabled)
     Active: inactive (dead)
```

- Service: **enabled** (will run on boot)
- Type: oneshot (runs once at boot, then exits)

### NetBird Service Status

All 8 containers running:
- ✅ netbird-caddy-1 (ports 80, 443, 443/UDP)
- ✅ netbird-dashboard-1
- ✅ netbird-management-1 (stable)
- ✅ netbird-signal-1
- ✅ netbird-relay-1
- ✅ netbird-coturn-1
- ✅ netbird-zitadel-1
- ✅ netbird-zdb-1 (healthy)

---

## Lessons Learned

### 1. Check What's Actually Listening

Don't assume based on configuration - verify what's actually bound to ports:
```bash
sudo ss -tlnp | grep :PORT
curl -I http://localhost:PORT
```

### 2. Understand Reverse Proxy Architecture

Map out the full request flow:
```
Internet → Entry Point → Proxy Layer → Backend Service
```

In this case:
- Cloudflare Tunnel was the entry point
- nginx was an unused proxy layer
- Services listening on localhost ports were the backend

### 3. Docker iptables Requirements

Docker requires specific iptables configuration:
- `DOCKER-USER` chain must end with `-j RETURN`
- Without RETURN, traffic hits FORWARD DROP policy
- This is not UFW-related - it's pure iptables

**Common mistake:**
Thinking "UFW is installed = UFW is blocking traffic"

**Reality:**
```bash
# UFW can be installed but not enabled
sudo ufw status
# Firewall not enabled (skipping reload)

# Check iptables directly
sudo iptables -L DOCKER-USER -n -v
# If empty or missing RETURN = problem
```

### 4. Docker Networking Debug Process

1. Test from container: `docker exec CONTAINER ping 8.8.8.8`
2. Test from host: `ping 8.8.8.8`
3. Check container routes: `docker exec CONTAINER ip route`
4. Check iptables FORWARD: `sudo iptables -L FORWARD -n -v`
5. Check DOCKER-USER: `sudo iptables -L DOCKER-USER -n -v`
6. Check NAT MASQUERADE: `sudo iptables -t nat -L -n -v | grep MASQUERADE`

### 5. Service Redundancy Identification

Questions to ask:
- What's the actual request path to the service?
- Is nginx/Apache actually being used?
- Could a reverse proxy be bypassed?
- Are there multiple layers doing the same thing?

In this case, nginx was completely bypassed by Cloudflare Tunnel.

---

## Future Troubleshooting

### If NetBird Dashboard Shows nginx Again

```bash
# 1. Check nginx status
systemctl is-active nginx
# If "active": nginx got re-enabled somehow

# 2. Stop and disable again
sudo systemctl stop nginx
sudo systemctl disable nginx

# 3. Restart Caddy
cd ~/netbird && docker compose restart caddy
```

### If Containers Lose Internet Again

```bash
# 1. Check DOCKER-USER chain
sudo iptables -L DOCKER-USER -n -v
# Should show: RETURN rule

# 2. If missing, add it
sudo iptables -A DOCKER-USER -j RETURN

# 3. Save rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# 4. Restart containers
cd ~/netbird && docker compose restart
```

### If SSL Certificate Fails to Renew

```bash
# 1. Check Caddy can reach internet
docker exec netbird-caddy-1 ping -c 2 8.8.8.8

# 2. Check Caddy logs
docker logs netbird-caddy-1 | grep -i "cert\|ssl\|acme"

# 3. Verify ports 80/443 accessible
sudo ss -tlnp | grep -E ":(80|443)"

# 4. Test Let's Encrypt reachability
curl -I https://acme-v02.api.letsencrypt.org/directory
```

---

## Related Files Modified

### System Configuration
- `/etc/nginx/sites-enabled/scorecard.conf` - Deleted
- `/etc/iptables/rules.v4` - Created
- `/etc/iptables/rules.v6` - Created
- `/etc/systemd/system/iptables-restore.service` - Created

### NetBird Configuration
- No changes required (configurations were correct)

### Documentation
- `DOMAIN_CHANGE_STATUS.md` - Updated with resolution
- `CLAUDE.md` - Updated with troubleshooting procedures
- `NETBIRD_NGINX_PORT_CONFLICT_2025-11-30.md` - This file

---

## Commands Quick Reference

```bash
# Check NetBird status
cd ~/netbird && docker ps --filter 'name=netbird'

# Check nginx status
systemctl is-active nginx  # Should be: inactive

# Check iptables DOCKER-USER
sudo iptables -L DOCKER-USER -n -v  # Should show RETURN rule

# Test container internet
docker exec netbird-caddy-1 ping -c 2 8.8.8.8

# Test HTTPS dashboard
curl -I https://netbird.iyeska.net

# View Caddy logs
docker logs netbird-caddy-1 -f

# Restart NetBird
cd ~/netbird && docker compose restart
```

---

**Resolution Date:** November 30, 2025
**Time to Resolution:** ~2 hours
**Status:** ✅ RESOLVED - All systems operational
