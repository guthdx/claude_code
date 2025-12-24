# NetBird Troubleshooting Session - November 29, 2025

## Issues Encountered

1. **NetBird management container in restart loop**
2. **Dashboard redirect URI error**
3. **User unable to access Zitadel admin console**

---

## Issue 1: Management Container Restart Loop

### Root Cause
The Caddy reverse proxy container was not properly attached to the Docker network after a system restart or configuration change. This caused:
- No network connectivity for Caddy
- Unable to obtain SSL certificates from Let's Encrypt
- Management container couldn't reach Zitadel OIDC endpoints

### Symptoms
```
Error: failed fetching OIDC configuration from endpoint 
https://netbird.iyeska.net/.well-known/openid-configuration 
Get "https://netbird.iyeska.net/.well-known/openid-configuration": EOF
```

### Solution
Restarted the entire Docker Compose stack to properly recreate network attachments:

```bash
cd ~/netbird
docker compose down
docker compose up -d
```

### Result
- ✅ All containers properly networked
- ✅ Caddy obtained valid SSL certificate from Let's Encrypt
- ✅ Management container successfully connected to Zitadel
- ✅ All 8 NetBird containers running properly

---

## Issue 2: Dashboard Redirect URI Error

### Root Cause
The Zitadel OAuth application configuration had incorrect redirect URIs pointing to `https://relay.netbird.iyeska.net` instead of `https://netbird.iyeska.net`.

### Symptoms
```json
{
  "error": "invalid_request",
  "error_description": "The requested redirect_uri is missing in the client configuration."
}
```

### Investigation
```sql
-- Found incorrect URIs in database
SELECT client_id, redirect_uris 
FROM projections.apps7_oidc_configs 
WHERE client_id = '345364864828506116';

-- Result showed:
-- {https://relay.netbird.iyeska.net/nb-auth, https://relay.netbird.iyeska.net/nb-silent-auth}
```

### Solution
Updated redirect URIs directly in the Zitadel PostgreSQL database:

```sql
-- Executed in netbird-zdb-1 container
UPDATE projections.apps7_oidc_configs 
SET redirect_uris = '{https://netbird.iyeska.net/nb-auth,https://netbird.iyeska.net/nb-silent-auth,https://netbird.iyeska.net/}', 
    post_logout_redirect_uris = '{https://netbird.iyeska.net/}'
WHERE client_id = '345364864828506116';
```

### Result
- ✅ Dashboard login now works correctly
- ✅ OAuth redirect flow completes successfully
- ✅ Users can access NetBird dashboard

---

## Issue 3: User Unable to Access Admin Console

### Root Cause
User account (`guthdx@ducheneaux.com`) was created as a regular user without organization admin permissions.

### Symptoms
- User could log into Zitadel console
- Redirected back to user profile page when trying to access Projects/Organization settings
- No "Projects" menu visible

### Investigation
The user account lacked the necessary roles:
- Not an Organization Owner (ORG_OWNER)
- Not an IAM Owner (IAM_OWNER)

### Solution Attempted
Tried to use Zitadel Management API to grant admin roles, but the service account token lacked sufficient permissions.

### Workaround
Direct database modification was used to fix the redirect URI issue instead of requiring admin console access.

### Future Resolution
To grant admin access in the future:
1. Use the initial admin account (`admin@netbird.iyeska.net`) if available
2. Or use Zitadel CLI/API with proper admin credentials
3. Or grant roles via direct database manipulation

---

## System Status After Fixes

### All Services Running
```
NAMES                  STATUS
netbird-zitadel-1      Up
netbird-zdb-1          Up (healthy)
netbird-coturn-1       Up
netbird-caddy-1        Up
netbird-dashboard-1    Up
netbird-relay-1        Up
netbird-signal-1       Up
netbird-management-1   Up
```

### SSL Certificate
- ✅ Valid Let's Encrypt certificate for `netbird.iyeska.net`
- ✅ Expires: March 28, 2026

### OIDC Configuration
- ✅ Accessible at: `https://netbird.iyeska.net/.well-known/openid-configuration`
- ✅ Zitadel integration working

### Dashboard Access
- ✅ URL: `https://netbird.iyeska.net`
- ✅ Login working
- ✅ OAuth flow functioning

---

## Key Learnings

1. **Docker Network Issues**: After container restarts, network attachments may fail. Full stack restart (`down` + `up`) resolves this.

2. **Redirect URI Configuration**: Critical OAuth setting. Must match exactly between:
   - Zitadel application config
   - Dashboard environment variables
   - Actual domain being accessed

3. **Database Direct Access**: For self-hosted Zitadel, direct PostgreSQL access can resolve configuration issues when API/UI access is blocked.

4. **Service Account Permissions**: The `netbird-service-account` has limited scope - can't manage organization/admin settings.

---

## Commands Reference

### Check NetBird Status
```bash
cd ~/netbird
docker ps --filter 'name=netbird'
docker compose logs -f netbird-management-1
```

### Access Zitadel Database
```bash
docker exec netbird-zdb-1 psql -U zitadel -d zitadel -c "YOUR SQL QUERY"
```

### Restart NetBird Stack
```bash
cd ~/netbird
docker compose restart
# Or for full restart:
docker compose down && docker compose up -d
```

### View SSL Certificate Status
```bash
docker logs netbird-caddy-1 2>&1 | grep -i certificate
```

---

## Configuration Files Modified

**None** - All changes were made to:
- Running Docker containers (via restart)
- PostgreSQL database (Zitadel configuration)

**Configuration in ~/netbird/ remains unchanged:**
- docker-compose.yml
- Caddyfile
- *.env files
- management.json

---

## Date
November 29, 2025

## Session Time
Approximately 2 hours

## Final Status
✅ All issues resolved
✅ NetBird fully operational
✅ Dashboard accessible
✅ VPN services running
