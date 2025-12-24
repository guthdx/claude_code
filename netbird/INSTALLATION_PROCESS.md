# NetBird Self-Hosted Installation - Complete Process Documentation

**Date:** November 5, 2025
**Server:** Ubuntu 24.04.3 LTS (192.168.11.20)
**Final Domain:** netbird.iyeska.net
**Status:** ✅ Successfully Completed

---

## Table of Contents
1. [Initial Setup & Pre-requisites](#initial-setup--pre-requisites)
2. [First Installation Attempt](#first-installation-attempt)
3. [Issues Encountered](#issues-encountered)
4. [Troubleshooting Journey](#troubleshooting-journey)
5. [Final Solution](#final-solution)
6. [Post-Installation](#post-installation)
7. [Lessons Learned](#lessons-learned)

---

## Initial Setup & Pre-requisites

### Infrastructure Already Configured
Before starting the NetBird installation, the following was already in place:

#### 1. DNS Records (Cloudflare)
All DNS records pointed to public IP `68.168.225.52` (gray cloud/DNS only mode):
- `netbird.iyeska.net` → 68.168.225.52
- `api.netbird.iyeska.net` → 68.168.225.52
- `signal.netbird.iyeska.net` → 68.168.225.52
- `netbird.iyeska.net` → 68.168.225.52

#### 2. pfSense Port Forwarding Rules
All configured to forward to internal server `192.168.11.20`:
- Port 80/TCP → HTTP traffic
- Port 443/TCP → HTTPS traffic
- Port 443/UDP → HTTP/3 / QUIC
- Port 3478/UDP → STUN server
- Port 10000/TCP → Signal gRPC
- Port 33073/UDP → Signal WebRTC
- Port 33080/TCP → Relay service
- Ports 49152-65535/UDP → TURN port range

#### 3. UFW Firewall (Ubuntu)
All required ports opened on the Ubuntu server

#### 4. Server Details
- OS: Ubuntu 24.04.3 LTS
- Internal IP: 192.168.11.20
- Docker and Docker Compose installed

---

## First Installation Attempt

### Attempt 1: Using netbird.iyeska.net

#### Commands Used:
```bash
# Create installation directory
mkdir -p ~/netbird
cd ~/netbird

# Download NetBird installation script
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh -o netbird-install.sh
chmod +x netbird-install.sh

# Run installation
export NETBIRD_DOMAIN=netbird.iyeska.net
bash netbird-install.sh
```

#### What Happened:
1. ✅ Script downloaded successfully
2. ✅ Docker containers started (caddy, zdb, zitadel)
3. ✅ Zitadel PAT token created
4. ❌ **FAILED:** Installation script timed out during Zitadel initialization

#### Error Message:
```
Waiting for Zitadel to become ready  . . . . . . . . . . . . . (timeout after 180s)
Unable to connect to Zitadel for more than 180s
curl: (28) Failed to connect to netbird.iyeska.net port 443 after 1002 ms: Timeout was reached
```

#### Investigation:
```bash
# Checked what was running
docker ps
# Result: Only 3 containers running (caddy, zdb, zitadel)
# Missing: dashboard, management, signal, relay, coturn

# Checked logs
docker logs netbird-caddy-1 --tail 50
```

---

## Issues Encountered

### Issue #1: Let's Encrypt Rate Limit

**Discovery:** Caddy logs showed:
```
HTTP 429 urn:ietf:params:acme:error:rateLimited -
too many certificates (5) already issued for this exact set of identifiers
in the last 168h0m0s, retry after 2025-11-06 12:04:55 UTC
```

**Explanation:**
- Previous installation attempts had requested 5 Let's Encrypt certificates for `netbird.iyeska.net`
- Let's Encrypt rate limit: Maximum 5 certificates per exact domain name per week
- Caddy fell back to Let's Encrypt **staging environment** (untrusted certificate)
- The staging certificate caused SSL/TLS handshake failures

**Impact:**
- Installation script couldn't connect to Zitadel API via HTTPS
- SSL errors: `OpenSSL error:0A000438:SSL routines::tlsv1 alert internal error`

---

### Issue #2: NAT Hairpinning / Reflection

**Discovery:** The server was trying to connect to `netbird.iyeska.net`, which resolved to the public IP `68.168.225.52`, but couldn't reach itself from inside the network.

**Explanation:**
- **NAT Hairpinning** is when an internal device tries to access another internal device using the external/public IP
- pfSense didn't have NAT reflection enabled by default
- Server at 192.168.11.20 tried to reach netbird.iyeska.net → 68.168.225.52 → failed to loop back

**Attempted Solutions:**

#### Solution Attempt 1: Enable NAT Reflection in pfSense
```
Location: System → Advanced → Firewall & NAT → NAT Reflection
Changed: Per-rule basis
For each port forward rule (80, 443): Enabled "NAT + Proxy" mode
```

**Result:** Partially worked, but SSL certificate issues persisted

#### Solution Attempt 2: Add Local Hosts Entry
```bash
# Add entry to /etc/hosts to bypass DNS resolution
echo "127.0.0.1 netbird.iyeska.net" | sudo tee -a /etc/hosts
```

**Result:** DNS resolved to localhost, but SSL/TLS handshake still failed due to staging certificate

---

### Issue #3: SSL/TLS SNI Mismatch

**Discovery:** Research revealed that curl sends the SNI (Server Name Indication) based on the hostname, but when connecting to 127.0.0.1, there's a mismatch.

**Technical Explanation:**
- Server Name Indication (SNI) is part of TLS handshake
- When connecting to `https://127.0.0.1`, curl sends SNI "127.0.0.1"
- Caddy expects SNI "netbird.iyeska.net"
- Mismatch causes: `error:0A000438:SSL routines::tlsv1 alert internal error`

**Attempted Fix:**
```bash
# Modified installation script to add -k flag (ignore SSL verification)
sed -i 's/curl -sS/curl -k -sS/g' netbird-install.sh

# Result: Still failed - the issue was deeper than cert validation
```

---

## Troubleshooting Journey

### Research Phase

#### Web Search Findings:
1. **Caddy Community Forums:** Found similar `tlsv1 alert internal error` issues related to SNI mismatches and Let's Encrypt staging certificates
2. **NetBird GitHub Issues:** Discovered other users had SSL handshake problems with self-hosted installations
3. **Stack Overflow:** Learned about curl's `--resolve` flag to override DNS resolution
4. **NetBird Documentation:** Found that custom reverse proxies are supported with `NETBIRD_DISABLE_LETSENCRYPT=true`

#### Key Insight:
The combination of:
- Let's Encrypt rate limit (untrusted staging cert)
- NAT hairpinning issues
- SNI mismatch when using localhost

Created a "perfect storm" preventing installation completion.

---

### Solution Attempts (Chronological)

#### Attempt 1: Modify curl commands in script ❌
- Added `-k` flag to ignore SSL verification
- **Result:** Failed - TLS handshake error persists even with -k

#### Attempt 2: Use HTTP instead of HTTPS ❌
- Tried accessing via `http://netbird.iyeska.net`
- **Result:** Caddy forces 308 redirect to HTTPS

#### Attempt 3: Use curl --resolve flag ❌
```bash
curl --resolve netbird.iyeska.net:443:127.0.0.1 -k -I https://netbird.iyeska.net
```
- **Result:** Still got SSL handshake errors

#### Attempt 4: Manual Zitadel initialization ❌
- Tried to manually call Zitadel API endpoints
- **Result:** Same SSL errors prevented API access

#### Attempt 5: Complete reinstallation ❌
```bash
# Full cleanup
docker-compose down -v
docker volume rm $(docker volume ls | grep netbird)
rm -rf ~/netbird/*

# Fresh installation attempt
# Result: Same issues - rate limit still in effect
```

---

## Final Solution

### The Winning Strategy: Use a Different Subdomain

**Realization:** Since `netbird.iyeska.net` had hit the rate limit, we needed a fresh domain that:
1. Had no Let's Encrypt certificate history
2. Was already configured in DNS
3. Could get a new, trusted certificate immediately

**Decision:** Use `netbird.iyeska.net`
- Already had DNS A record pointing to correct IP
- Zero certificate requests (fresh slate)
- Would get trusted Let's Encrypt certificate on first try

### Complete Fresh Installation Process

#### Step 1: Complete Cleanup
```bash
# Stop and remove all containers
cd ~/netbird
docker-compose down -v

# Force remove any stuck containers
docker stop netbird-caddy-1 netbird-zitadel-1 netbird-zdb-1
docker rm netbird-caddy-1 netbird-zitadel-1 netbird-zdb-1

# Remove all volumes
docker volume rm netbird_netbird_caddy_data \
                 netbird_netbird_zdb_data \
                 netbird_netbird_zitadel_certs \
                 netbird_netbird_management

# Remove all files
cd ~/netbird
rm -rf *
```

#### Step 2: Add Temporary Hosts Entry
**Why needed:** Installation script runs curl from host system, needs to resolve domain to localhost during initial setup.

```bash
# Add temporary entry
echo "127.0.0.1 netbird.iyeska.net" | sudo tee -a /etc/hosts

# Verify
grep netbird.iyeska.net /etc/hosts
# Output: 127.0.0.1 netbird.iyeska.net
```

#### Step 3: Run Installation with New Domain
```bash
# Download fresh installation script
cd ~/netbird
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh -o netbird-install.sh
chmod +x netbird-install.sh

# Run installation with relay subdomain
export NETBIRD_DOMAIN=netbird.iyeska.net
bash netbird-install.sh 2>&1 | tee install-relay.log
```

#### Step 4: Installation Progress
```
✅ Rendering initial files...
✅ Starting Zitadel IDP for user management
✅ Creating Docker volumes
✅ Starting containers: caddy, zdb, zitadel
✅ Waiting for Zitadel's PAT to be created... done
✅ Reading Zitadel PAT
✅ Waiting for Zitadel to become ready... done  # This time it worked!
✅ Deleting default zitadel-admin user...
✅ Creating new zitadel project
✅ Creating new Zitadel SPA Dashboard application
✅ Creating new Zitadel SPA Cli application
✅ Rendering NetBird files...
✅ Starting NetBird services
✅ All containers started successfully

Done!
```

**Success!** The installation completed because:
1. Let's Encrypt issued a fresh, trusted certificate for `netbird.iyeska.net`
2. No rate limit issues
3. SSL/TLS handshake worked properly
4. All Zitadel initialization steps completed

#### Step 5: Fix Management Container Issue

**Issue Discovered:** After installation, the `netbird-management-1` container was restarting.

**Diagnosis:**
```bash
docker logs netbird-management-1 --tail 20
```

**Error:**
```
Get "https://netbird.iyeska.net/.well-known/openid-configuration":
dial tcp 127.0.0.1:443: connect: connection refused
```

**Cause:** The management container was trying to connect via the `/etc/hosts` entry (127.0.0.1), but containers need to communicate via Docker's internal network.

**Solution:** Remove the temporary hosts entry
```bash
# Remove the hosts entry we added for installation
sudo sed -i '/netbird.iyeska.net/d' /etc/hosts

# Verify removal
grep netbird /etc/hosts
# Output: (empty)

# Restart management container
docker restart netbird-management-1

# Verify it's running
docker ps | grep management
# Output: netbird-management-1  Up X seconds

# Check logs - should show successful connection
docker logs netbird-management-1 --tail 10
```

**Result:** ✅ Management container started successfully and connected to Zitadel via Docker internal network

---

## Post-Installation

### Verification Steps

#### 1. Check All Containers Running
```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep netbird
```

**Expected Output:**
```
netbird-dashboard-1    Up X minutes
netbird-coturn-1       Up X minutes
netbird-signal-1       Up X minutes
netbird-management-1   Up X minutes
netbird-relay-1        Up X minutes
netbird-zitadel-1      Up X minutes
netbird-caddy-1        Up X minutes
netbird-zdb-1          Up X minutes (healthy)
```

**Result:** ✅ All 8 containers running

#### 2. Verify SSL Certificate
```bash
# Check certificate from external perspective
curl -vI https://netbird.iyeska.net 2>&1 | grep -i "certificate\|issuer"
```

**Expected:** Let's Encrypt production certificate (not staging)

#### 3. Test Dashboard Access
- **URL:** https://netbird.iyeska.net
- **Expected:** Login page loads with valid SSL certificate
- **Browser:** Should show green padlock (trusted certificate)

#### 4. Verify Services
```bash
# Check management API
curl -k https://netbird.iyeska.net/api/dns/nameservers

# Check Zitadel
curl -s https://netbird.iyeska.net/.well-known/openid-configuration | jq .issuer
# Expected: "https://netbird.iyeska.net"
```

### Admin Credentials

**Saved to:** `/home/guthdx/netbird/NETBIRD_CREDENTIALS.txt`

```
Dashboard URL: https://netbird.iyeska.net
Username: admin@netbird.iyeska.net
Password: B13sSOR7GuHUPoIkYBfYtTATS7Mo6ZdygmuErqYuOAM@
```

⚠️ **Critical:** Change password immediately after first login!

---

## Lessons Learned

### 1. Let's Encrypt Rate Limits Are Real
**Lesson:** During testing/troubleshooting, it's easy to exhaust the 5 certificates per week limit.

**Best Practices:**
- Use Let's Encrypt **staging environment** during testing
- Keep track of certificate requests
- Consider using a wildcard certificate (requires DNS challenge)
- Have backup subdomain ready for emergencies

**Prevention:**
```bash
# For testing, can modify Caddyfile to use staging:
# Add to Caddyfile:
{
    acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}
```

### 2. NAT Hairpinning/Reflection Configuration
**Lesson:** Internal servers accessing services via public IP need NAT reflection enabled in firewall.

**pfSense Configuration:**
- Location: `Firewall → NAT → Port Forward`
- For each rule: Enable "NAT reflection" → "NAT + Proxy"
- OR: System-wide at `System → Advanced → Firewall & NAT`

**Alternative:** Use split-horizon DNS (internal DNS returns internal IP, external DNS returns public IP)

### 3. Docker Container Networking
**Lesson:** Containers communicate via Docker's internal network, not via host networking stack.

**Key Points:**
- Containers resolve service names (e.g., `zitadel`, `caddy`) via Docker DNS
- `/etc/hosts` on host doesn't affect container networking
- Containers see each other via internal IPs (172.x.x.x range)
- Only Caddy needs to bind to host ports (80, 443)

### 4. Debugging SSL/TLS Issues
**Lesson:** SSL handshake errors have many potential causes.

**Debugging Tools:**
```bash
# Test SSL/TLS connection
openssl s_client -connect domain.com:443 -servername domain.com

# Check certificate details
echo | openssl s_client -connect domain.com:443 2>/dev/null | openssl x509 -noout -text

# Test with curl (verbose)
curl -vI https://domain.com

# Check SNI specifically
openssl s_client -connect domain.com:443 -servername domain.com -tlsextdebug
```

**Common Causes:**
1. Certificate not trusted (self-signed, staging, expired)
2. SNI mismatch (hostname doesn't match certificate)
3. Protocol/cipher mismatch (TLS version incompatibility)
4. Certificate chain incomplete
5. Wrong certificate being served

### 5. NetBird-Specific Learnings

**Installation Requirements:**
- Clean slate works best - don't try to resume failed installations
- Installation script expects to connect to domain via HTTPS
- Zitadel must be accessible before other services can start
- All config files generated in specific order

**Architecture Understanding:**
```
Internet → pfSense (Port Forwarding) → Server:443 → Caddy (Reverse Proxy)
                                                        ↓
                                            ┌───────────┴───────────┐
                                            ↓                       ↓
                                        Zitadel              NetBird Services
                                        (Auth)               (Management, Signal, etc)
                                            ↓
                                        PostgreSQL
```

**Service Dependencies:**
1. PostgreSQL (zdb) - Database
2. Zitadel - Identity Provider (depends on PostgreSQL)
3. Caddy - Reverse Proxy & SSL Termination
4. NetBird Management - Core service (depends on Zitadel)
5. NetBird Dashboard - Web UI (depends on Management)
6. NetBird Signal - Signaling service
7. NetBird Relay - Relay service
8. Coturn - TURN/STUN server

### 6. When Things Go Wrong - Troubleshooting Checklist

**Network Issues:**
```bash
# Check DNS resolution
dig +short domain.com
nslookup domain.com

# Check port connectivity
telnet domain.com 443
nc -zv domain.com 443

# Check firewall
sudo ufw status
sudo iptables -L -n
```

**Docker Issues:**
```bash
# Check all containers
docker ps -a

# View logs
docker logs <container-name> --tail 50 --follow

# Restart specific service
docker restart <container-name>

# Check resource usage
docker stats

# Inspect container
docker inspect <container-name>
```

**NetBird Specific:**
```bash
# Check config files
cat ~/netbird/management.json
cat ~/netbird/dashboard.env
cat ~/netbird/relay.env
cat ~/netbird/turnserver.conf

# Verify Zitadel connectivity
curl -k https://domain.com/.well-known/openid-configuration

# Check Zitadel PAT token
cat ~/netbird/machinekey/zitadel-admin-sa.token
```

---

## Management Commands

### Daily Operations

#### View Service Status
```bash
docker ps | grep netbird
```

#### View Logs
```bash
# All services
docker-compose -f ~/netbird/docker-compose.yml logs

# Specific service
docker logs netbird-management-1 --tail 50 --follow
docker logs netbird-caddy-1 --tail 50 --follow
```

#### Restart Services
```bash
# All services
cd ~/netbird
docker-compose restart

# Specific service
docker restart netbird-management-1
```

#### Stop/Start All Services
```bash
# Stop
cd ~/netbird
docker-compose down

# Start
cd ~/netbird
docker-compose up -d
```

#### Update NetBird
```bash
# Pull latest images
cd ~/netbird
docker-compose pull

# Restart with new images
docker-compose up -d
```

### Backup Commands

#### Backup Configuration
```bash
# Create backup directory
mkdir -p ~/netbird-backups/$(date +%Y%m%d)

# Backup config files
cp ~/netbird/*.env ~/netbird-backups/$(date +%Y%m%d)/
cp ~/netbird/*.json ~/netbird-backups/$(date +%Y%m%d)/
cp ~/netbird/*.conf ~/netbird-backups/$(date +%Y%m%d)/
cp ~/netbird/Caddyfile ~/netbird-backups/$(date +%Y%m%d)/
cp -r ~/netbird/machinekey ~/netbird-backups/$(date +%Y%m%d)/
```

#### Backup Database
```bash
# Export PostgreSQL database
docker exec netbird-zdb-1 pg_dump -U root postgres > ~/netbird-backups/$(date +%Y%m%d)/netbird-db.sql

# Export Zitadel database
docker exec netbird-zdb-1 pg_dump -U zitadel zitadel > ~/netbird-backups/$(date +%Y%m%d)/zitadel-db.sql
```

#### Backup Docker Volumes
```bash
# Create volume backups
docker run --rm \
  -v netbird_netbird_management:/data \
  -v ~/netbird-backups/$(date +%Y%m%d):/backup \
  ubuntu tar czf /backup/management-volume.tar.gz /data
```

---

## Troubleshooting Guide

### Common Issues & Solutions

#### Issue: Containers Won't Start
**Symptoms:** `docker ps` shows containers constantly restarting

**Solutions:**
```bash
# Check logs
docker logs netbird-<service>-1 --tail 50

# Check disk space
df -h

# Check memory
free -h

# Restart Docker daemon
sudo systemctl restart docker
```

#### Issue: Can't Access Dashboard
**Symptoms:** https://netbird.iyeska.net times out or shows error

**Solutions:**
```bash
# Verify Caddy is running
docker ps | grep caddy

# Check Caddy logs
docker logs netbird-caddy-1 --tail 50

# Verify port forwarding
ss -tlnp | grep :443

# Test from external network
curl -I https://netbird.iyeska.net

# Check pfSense port forwarding rules
# System → Routing → Port Forwards
```

#### Issue: SSL Certificate Errors
**Symptoms:** Browser shows "Your connection is not private"

**Solutions:**
```bash
# Check which certificate is being served
echo | openssl s_client -connect netbird.iyeska.net:443 2>/dev/null | openssl x509 -noout -issuer

# Check Caddy certificate storage
docker exec netbird-caddy-1 ls -la /data/caddy/certificates/

# Force certificate renewal
docker exec netbird-caddy-1 caddy reload --config /etc/caddy/Caddyfile
```

#### Issue: Authentication Failures
**Symptoms:** Can't login to dashboard, or "Invalid credentials" error

**Solutions:**
```bash
# Verify Zitadel is running
docker ps | grep zitadel

# Check Zitadel logs
docker logs netbird-zitadel-1 --tail 50

# Verify OIDC configuration
curl -s https://netbird.iyeska.net/.well-known/openid-configuration | jq .

# Reset admin password (if needed)
# Access Zitadel directly: https://netbird.iyeska.net/ui/console
```

---

## Security Considerations

### Important Security Notes

1. **Change Default Password Immediately**
   - Default admin password is in plaintext in installation logs
   - Change it on first login
   - Use a strong, unique password

2. **Secure Credentials File**
   ```bash
   # Set restrictive permissions
   chmod 600 ~/netbird/NETBIRD_CREDENTIALS.txt

   # Consider encrypting it
   gpg -c ~/netbird/NETBIRD_CREDENTIALS.txt
   ```

3. **Regular Updates**
   - Keep NetBird containers updated
   - Monitor NetBird GitHub for security advisories
   - Update pfSense regularly

4. **Firewall Rules**
   - Only open required ports
   - Use pfSense rule logging to monitor traffic
   - Consider geo-blocking if appropriate

5. **SSL/TLS Best Practices**
   - Let's Encrypt certificates auto-renew
   - Monitor expiry dates
   - Ensure HSTS is enabled (Caddy does this by default)

6. **Database Security**
   - PostgreSQL is not exposed externally (good!)
   - Regular backups essential
   - Consider encryption at rest

---

## Conclusion

### Final State

**Successfully Installed:**
- NetBird self-hosted VPN platform
- All 8 services running
- Valid SSL certificate from Let's Encrypt
- Accessible at: https://netbird.iyeska.net

**Time Invested:**
- Initial attempts: ~2 hours (failed due to rate limiting)
- Research & troubleshooting: ~1 hour
- Final successful installation: ~15 minutes

**Key Success Factors:**
1. Using a fresh subdomain (`netbird.iyeska.net`) to bypass rate limits
2. Understanding Docker container networking
3. Proper use of temporary hosts entry during installation
4. Complete cleanup between attempts

### What Made This Challenging

1. **Let's Encrypt Rate Limiting** - Main blocker that wasn't immediately obvious
2. **Multiple Interacting Systems** - pfSense, Docker networking, SSL/TLS, DNS
3. **Limited Error Messages** - Generic SSL errors didn't point to root cause
4. **Documentation Gaps** - Rate limit scenario not well documented in NetBird guides

### Resources Used

**Documentation:**
- NetBird Official Docs: https://docs.netbird.io/selfhosted/selfhosted-guide
- Let's Encrypt Rate Limits: https://letsencrypt.org/docs/rate-limits/
- Caddy Documentation: https://caddyserver.com/docs/

**Community Resources:**
- NetBird GitHub Issues
- Caddy Community Forums
- Stack Overflow

**Tools:**
- Docker & Docker Compose
- curl (for API testing)
- openssl (for certificate debugging)
- jq (for JSON parsing)

---

## Next Steps

### Recommended Actions

1. **Initial Configuration**
   - [ ] Login to dashboard
   - [ ] Change admin password
   - [ ] Review network settings
   - [ ] Configure authentication methods

2. **Add Devices**
   - [ ] Install NetBird client on workstation
   - [ ] Install NetBird client on mobile devices
   - [ ] Configure access rules

3. **Monitoring Setup**
   - [ ] Set up log rotation
   - [ ] Configure monitoring/alerting
   - [ ] Set up backup automation

4. **Documentation**
   - [ ] Document custom configurations
   - [ ] Create runbook for common tasks
   - [ ] Share knowledge with team

### Future Enhancements

- Consider setting up high availability
- Implement automated backups
- Add monitoring with Prometheus/Grafana
- Configure custom branding
- Set up SSO integration

---

**Document Created:** November 5, 2025
**Last Updated:** November 5, 2025
**Status:** Installation Complete and Documented
**Maintained by:** System Administrator

---
