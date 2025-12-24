# NetBird Clean Slate Installation Plan

## Executive Summary

**Problem**: Manual Zitadel configuration led to OAuth routing issues. Dashboard expects `/nb-auth` callback but NextJS routing returns 404.

**Solution**: Use official NetBird installation script which automatically configures everything correctly.

**Time Estimate**: 10-15 minutes

**SSL Certificates**: Will be preserved (stored in `netbird_netbird_caddy_data` volume)

---

## Current State Analysis

### What's Working
- ✅ SSL certificates obtained from Let's Encrypt for `netbird.iyeska.net`
- ✅ All containers running (caddy, dashboard, signal, relay, management, coturn, zitadel, zdb)
- ✅ Zitadel authentication successful (user can log in)
- ✅ OAuth authorization code flow works
- ✅ Domain DNS properly configured

### What's Broken
- ❌ Dashboard OAuth callback returns 404 on `/nb-auth`
- ❌ Dashboard hangs on loading screen after OAuth redirect
- ❌ Manual Zitadel configuration doesn't match dashboard expectations

### Root Cause
The official NetBird installation script creates Zitadel OAuth applications with specific configurations that the dashboard expects. Manual configuration created mismatches between:
- OAuth client IDs in dashboard.env vs what dashboard actually uses
- Redirect URI paths (/nb-auth vs /auth)
- OAuth application types and settings in Zitadel

---

## Clean Slate Plan

### Phase 1: Backup Current State (5 minutes)

**What to backup:**
1. SSL certificates (automatically preserved in Docker volume)
2. Current config files (for reference)
3. Domain name: `netbird.iyeska.net`

**Backup commands:**
```bash
cd /home/guthdx/netbird
mkdir -p backup-$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=backup-$(date +%Y%m%d-%H%M%S)

# Copy all config files
cp docker-compose.yml Caddyfile zitadel.env dashboard.env \
   management.json turnserver.conf relay.env zdb.env $BACKUP_DIR/

# Note: SSL certs are in Docker volume - will be preserved
echo "netbird.iyeska.net" > $BACKUP_DIR/domain.txt
```

### Phase 2: Complete System Removal (2 minutes)

**Remove everything except SSL certificates:**
```bash
cd /home/guthdx/netbird

# Stop and remove all containers
docker compose down

# Remove ALL volumes including databases (but keep Caddy data with SSL certs)
docker volume rm netbird_netbird_zdb_data
docker volume rm netbird_netbird_management
docker volume rm netbird_netbird_zitadel_certs
# KEEP: netbird_netbird_caddy_data (contains SSL certificates)

# Remove configuration files
rm -f docker-compose.yml Caddyfile zitadel.env dashboard.env \
      management.json turnserver.conf relay.env zdb.env

# Remove generated machine keys
rm -rf machinekey/

# Remove installation script (will download fresh)
rm -f netbird-install.sh
```

**Verification:**
```bash
# Should show only Caddy volume remaining
docker volume ls | grep netbird
# Expected output: netbird_netbird_caddy_data

# Should show no NetBird containers
docker ps -a | grep netbird
# Expected output: (empty)

# Should show no config files
ls -la /home/guthdx/netbird/*.{yml,env,json,conf}
# Expected output: No such file or directory
```

### Phase 3: Fresh Installation (5 minutes)

**Download and run official installation script:**
```bash
cd /home/guthdx/netbird

# Download latest official setup script
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started-with-zitadel.sh -o getting-started-with-zitadel.sh

# Make executable
chmod +x getting-started-with-zitadel.sh

# Run installation
export NETBIRD_DOMAIN=netbird.iyeska.net
bash getting-started-with-zitadel.sh
```

**What the script does automatically:**
1. Creates `docker-compose.yml` with all services properly configured
2. Creates `Caddyfile` with correct reverse proxy rules
3. Generates `management.json` with proper OAuth settings
4. Creates `zitadel.env`, `dashboard.env`, `relay.env`, `zdb.env`
5. Initializes Zitadel database
6. Creates Zitadel OAuth applications with correct IDs
7. Creates Zitadel user account
8. Starts all containers
9. Obtains SSL certificate (or reuses existing from volume)
10. Displays admin credentials

**Expected output at end:**
```
NetBird setup completed!

Access the dashboard at: https://netbird.iyeska.net

Login credentials:
Username: admin@netbird.iyeska.net
Password: <randomly-generated-password>

Save these credentials in a secure location!
```

### Phase 4: Verification (3 minutes)

**Test 1: Check all containers running**
```bash
docker ps --filter 'name=netbird' --format 'table {{.Names}}\t{{.Status}}'
```
Expected: 8 containers all "Up" (healthy)

**Test 2: Check SSL certificate**
```bash
curl -I https://netbird.iyeska.net
```
Expected: `200 OK` with valid SSL

**Test 3: Check OIDC configuration**
```bash
curl -s https://netbird.iyeska.net/.well-known/openid-configuration | jq .
```
Expected: Valid JSON with issuer, authorization_endpoint, token_endpoint

**Test 4: Dashboard login**
1. Open https://netbird.iyeska.net in browser
2. Should redirect to Zitadel login
3. Enter credentials from installation output
4. Should successfully land on dashboard /peers page (not hang)

**Test 5: Create setup key**
```bash
# Access dashboard → Setup Keys → Create Setup Key
# Name: "mac-clients"
# Type: Reusable
# Expiration: 30 days
# Auto-assign group: (create "macs" group)
```

### Phase 5: Connect Mac Clients (5-10 minutes)

**On each Mac (M4 and M1):**
```bash
# Remove old NetBird installation if exists
sudo netbird down
sudo rm -rf /etc/netbird

# Install NetBird (if not already installed)
brew install netbirdio/tap/netbird

# Connect to self-hosted instance
sudo netbird up \
  --management-url https://netbird.iyeska.net:443 \
  --setup-key <SETUP_KEY_FROM_DASHBOARD>

# Verify connection
sudo netbird status
```

**Expected output:**
```
NetBird version: X.XX.X
Management: Connected
Signal: Connected
Relays: 1/1 Available
NetBird IP: 100.X.X.X
```

**Test connectivity between Macs:**
```bash
# On M4 Mac - ping M1's NetBird IP
ping 100.X.X.X

# On M1 Mac - ping M4's NetBird IP
ping 100.X.X.X
```

---

## Why This Will Work

### The Official Script Handles:

1. **Correct OAuth Client IDs**: Creates Zitadel apps with IDs that match what dashboard expects
2. **Proper Redirect URIs**: Configures `/nb-auth` and `/nb-silent-auth` correctly
3. **Service Account Setup**: Creates management API service account with proper permissions
4. **Database Initialization**: Properly initializes Zitadel with all required schemas
5. **Version Compatibility**: Uses tested, compatible versions of all components
6. **Configuration Consistency**: All config files generated from same source of truth

### What We're Preserving:

1. **SSL Certificates**: Stored in `netbird_netbird_caddy_data` volume
   - Location: `/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/netbird.iyeska.net/`
   - Files: `netbird.iyeska.net.crt`, `netbird.iyeska.net.key`, `netbird.iyeska.net.json`
   - Caddy will detect and reuse existing certificates

2. **Domain Configuration**: Same domain (`netbird.iyeska.net`)
   - DNS already pointing to 68.168.225.52
   - Port forwarding already configured on pfSense

### What We're Fixing:

1. **OAuth Configuration Mismatch**: Script creates apps with correct settings
2. **Dashboard Routing**: Fresh dashboard with correct Next.js routing
3. **Zitadel State**: Clean database with proper initialization
4. **Management Database**: Fresh SQLite with no corrupted state

---

## Rollback Plan (If Needed)

If installation fails:

```bash
# Restore from backup
cd /home/guthdx/netbird
BACKUP_DIR=backup-YYYYMMDD-HHMMSS  # Use actual backup directory

# Restore config files
cp $BACKUP_DIR/* .

# Recreate volumes (except Caddy)
docker volume create netbird_netbird_zdb_data
docker volume create netbird_netbird_management
docker volume create netbird_netbird_zitadel_certs

# Start containers
docker compose up -d
```

---

## Risk Assessment

**Low Risk:**
- ✅ SSL certificates preserved in Docker volume
- ✅ Domain DNS unchanged
- ✅ Official installation script (tested by NetBird team)
- ✅ Can rollback to backup if needed
- ✅ No changes to pfSense or network infrastructure

**Medium Risk:**
- ⚠️ Will need to reconnect Mac clients (minor inconvenience)
- ⚠️ New admin password (save it!)
- ⚠️ 10-15 minutes of downtime

**Zero Risk:**
- ✅ No impact on other services (n8n, Cloudflare tunnel, etc.)
- ✅ No impact on domain or DNS

---

## Success Criteria

Installation is successful when:

1. ✅ All 8 NetBird containers running and healthy
2. ✅ Dashboard accessible at https://netbird.iyeska.net
3. ✅ Can log in to dashboard without hanging
4. ✅ Can navigate to /peers page and see UI
5. ✅ Can create setup keys
6. ✅ Mac clients can connect
7. ✅ Macs can ping each other via NetBird IPs

---

## Next Steps After Successful Installation

1. **Save admin credentials** in password manager
2. **Create additional users** if needed (via Zitadel console at /ui/console)
3. **Configure network policies** in dashboard
4. **Set up access control lists** for peer-to-peer connectivity
5. **Document setup keys** for future devices

---

## Estimated Timeline

| Phase | Task | Time |
|-------|------|------|
| 1 | Backup current state | 5 min |
| 2 | Complete system removal | 2 min |
| 3 | Fresh installation | 5 min |
| 4 | Verification | 3 min |
| 5 | Connect Mac clients | 10 min |
| **Total** | | **25 min** |

---

## Questions Before Proceeding?

1. Do you want to review the backup directory before deletion?
2. Do you want to test the rollback procedure first?
3. Do you want to proceed with the clean installation now?
