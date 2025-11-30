# NetBird Troubleshooting Summary - November 29, 2025

## Quick Summary

Fixed three critical NetBird VPN issues on Ubuntu server (192.168.11.20):

1. ✅ **Management container restart loop** - Docker network issue
2. ✅ **Dashboard redirect URI error** - Zitadel OAuth misconfiguration
3. ✅ **Dashboard now accessible** at https://netbird.iyeska.net

---

## What Was Fixed

### 1. Docker Network Failure → Container Restart Loop

**Problem:** `netbird-management-1` container continuously restarting, unable to reach Zitadel OIDC endpoints.

**Root Cause:** Caddy container lost network connectivity, preventing:
- SSL certificate acquisition from Let's Encrypt
- Reverse proxy functionality
- OIDC authentication flow

**Solution:**
```bash
cd ~/netbird
docker compose down
docker compose up -d
```

**Result:** All 8 containers now running with proper network connectivity.

---

### 2. OAuth Redirect URI Misconfiguration

**Problem:** Dashboard showed error:
```json
{
  "error": "invalid_request",
  "error_description": "The requested redirect_uri is missing in the client configuration."
}
```

**Root Cause:** Zitadel application configured with wrong redirect URIs:
- **INCORRECT:** `https://relay.netbird.iyeska.net/nb-auth`
- **CORRECT:** `https://netbird.iyeska.net/nb-auth`

**Solution:** Updated PostgreSQL database directly:
```sql
UPDATE projections.apps7_oidc_configs
SET redirect_uris = '{https://netbird.iyeska.net/nb-auth,https://netbird.iyeska.net/nb-silent-auth,https://netbird.iyeska.net/}',
    post_logout_redirect_uris = '{https://netbird.iyeska.net/}'
WHERE client_id = '345364864828506116';
```

**Result:** Dashboard OAuth flow now works correctly.

---

## Files Modified

### In ~/netbird/ (Not in Git)
- **Database only:** Zitadel PostgreSQL `apps7_oidc_configs` table
- **Docker containers:** Restarted via `docker compose down/up`

### Documentation Created
1. `/home/guthdx/netbird/TROUBLESHOOTING_2025-11-29.md` - Full technical writeup
2. `/home/guthdx/CLAUDE.md` - Updated with NetBird troubleshooting section
3. This file - Summary for claude_code repository

---

## Current Status

✅ **All NetBird services operational:**
```
netbird-zitadel-1      Up
netbird-zdb-1          Up (healthy)
netbird-coturn-1       Up
netbird-caddy-1        Up (valid SSL cert)
netbird-dashboard-1    Up
netbird-relay-1        Up
netbird-signal-1       Up
netbird-management-1   Up
```

✅ **Dashboard accessible:** https://netbird.iyeska.net

✅ **SSL Certificate:** Valid until March 28, 2026

---

## Next Steps for User

### Connect Client Devices to Self-Hosted NetBird

The NetBird client on user's M4 Mac is connected to **NetBird cloud** (public), not the **self-hosted instance** (netbird.iyeska.net).

**To connect M4 Mac to self-hosted instance:**

1. Get setup key from dashboard: https://netbird.iyeska.net → Setup Keys

2. On M4 Mac, run:
```bash
sudo netbird down
sudo rm -rf /etc/netbird
sudo netbird up --management-url https://netbird.iyeska.net:443 --setup-key YOUR_SETUP_KEY
```

---

## Key Learnings

1. **Docker networking can fail silently** after restarts → Full stack restart fixes it
2. **OAuth redirect URIs must match exactly** → Check both Zitadel config AND dashboard.env
3. **Direct database access** is sometimes necessary for Zitadel self-hosted instances
4. **Service account tokens** have limited permissions → Can't manage admin/org settings via API

---

## Reference Links

- **Dashboard:** https://netbird.iyeska.net
- **NetBird Docs:** https://docs.netbird.io
- **Full Troubleshooting:** ~/netbird/TROUBLESHOOTING_2025-11-29.md
- **Home CLAUDE.md:** /home/guthdx/CLAUDE.md (updated with troubleshooting section)

---

**Session Date:** November 29, 2025
**Duration:** ~2 hours
**Server:** 192.168.11.20 (Ubuntu 24.04.3 LTS)
**Status:** ✅ All issues resolved
