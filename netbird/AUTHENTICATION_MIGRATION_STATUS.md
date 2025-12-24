# NetBird Authentication Migration Status

**Migration Started**: December 3, 2025 at 13:29 UTC
**Current Status**: Phase 1 Complete, Phase 2 Pending User Action
**Last Updated**: December 3, 2025 at 13:30 UTC

---

## Migration Goal

Migrate from Microsoft Authenticator (TOTP) to dual authentication:
- **Primary**: WebAuthn/FIDO2 passkeys (Touch ID on Mac, Face ID on iPhone/iPad)
- **Backup**: TOTP codes stored in 1Password

---

## What Has Been Completed

### ✅ Phase 1: Pre-Implementation Safety (COMPLETED)

All backups have been created successfully:

1. **System Backup**:
   - File: `~/netbird-backup-20251203-132956.tar.gz`
   - Size: 82KB
   - Contains: Entire NetBird directory with all configuration files

2. **Database Backup**:
   - File: `~/zitadel-backup-20251203-133007.sql`
   - Size: 828KB
   - Contains: Complete Zitadel PostgreSQL database dump

3. **Authentication State Documentation**:
   - File: `~/auth-methods-before.txt`
   - Contains: Current user authentication methods
   - Current state: One TOTP method active (Microsoft Authenticator)

4. **Login Policy Documentation**:
   - File: `~/login-policy-before.txt`
   - Contains: Current Zitadel login policy configuration
   - Key settings:
     - Username/password: Enabled
     - MFA: Not forced, but available
     - Second factors: {1,2} (TOTP and U2F)
     - Multi factors: {1}
     - Passwordless type: 1 (enabled)
     - Default policy: true

---

## Current Authentication Configuration

**From database query:**
- **User ID**: 349059759258730500
- **Current Method**: TOTP (Microsoft Authenticator)
- **Method Type**: 1
- **State**: 2 (active)
- **Created**: 2025-12-01 01:18:49 UTC

**Login Policy:**
- WebAuthn/Passkeys: Available and enabled
- TOTP: Supported
- MFA: Optional (not forced)
- Passwordless authentication: Enabled

---

## What Needs To Be Done Next

### ⏸️ Phase 2: Migrate TOTP to 1Password (PENDING - User Action Required)

**IMPORTANT**: You are currently using **Microsoft Authenticator**, not Google Authenticator.

#### Step 1: Backup Microsoft Authenticator (5 minutes)

**On iPhone/iPad:**
1. Open Microsoft Authenticator app
2. Tap Settings (three dots or hamburger menu)
3. Enable "iCloud Backup" if not already enabled
4. Take screenshot of NetBird entry
5. Save screenshot to 1Password as document

**On Android:**
1. Open Microsoft Authenticator
2. Settings → Backup
3. Sign in with Microsoft account
4. Enable backup
5. Take screenshot of NetBird entry

#### Step 2: Add TOTP to Zitadel and 1Password (15 minutes)

**In web browser:**
1. Navigate to: `https://netbird.iyeska.net/ui/console/users/me`
2. Log in with:
   - Username: `admin@netbird.iyeska.net`
   - Password: [from .env file or your memory]
   - TOTP code: [from Microsoft Authenticator - 6 digits]
3. Find authentication settings (look for "Password and Security" in sidebar)
4. Locate TOTP section
5. Click "Add" or "Register" to generate NEW TOTP secret
6. Zitadel will display QR code and text secret
7. **KEEP BROWSER TAB OPEN**

**In 1Password:**
1. Create/find login item: "NetBird - Zitadel"
2. Edit item
3. Add "One-Time Password" field
4. Scan QR code from browser OR paste secret key
5. Save - 1Password starts generating codes

**Back in browser:**
1. Copy code from 1Password
2. Enter in Zitadel verification field
3. Click "Verify"
4. Wait for success confirmation

**CRITICAL TEST:**
1. Open NEW incognito window
2. Go to: `https://netbird.iyeska.net/ui/console`
3. Login with username + password + 1Password TOTP code
4. Verify successful login
5. **If this fails, stay in original session and troubleshoot**

---

### ⏸️ Phase 3: Register Passkeys (PENDING - User Action Required)

**After Phase 2 succeeds:**

#### Mac Touch ID Passkey:
1. In Safari, go to: `https://netbird.iyeska.net/ui/console/users/me`
2. Login with username + password + 1Password TOTP
3. Navigate to authentication settings
4. Look for "Passwordless authentication devices" or "Passkeys"
5. Click "Add Passkey"
6. Name it: "MacBook Touch ID"
7. Touch ID prompt will appear
8. Touch sensor
9. Verify registration successful

**Test immediately in new incognito window**

#### iPhone/iPad Face ID Passkey:
1. In Safari on iPhone, go to: `https://netbird.iyeska.net/ui/console/users/me`
2. Login with username + password + 1Password TOTP
3. Navigate to same authentication settings section
4. Tap "Add Passkey"
5. Name it: "iPhone Face ID"
6. Face ID prompt will appear
7. Look at device
8. Verify registration successful

**Test immediately in new private tab**

---

### ⏸️ Phase 4: Verification (PENDING)

After all passkeys are registered:
1. Test each authentication method works
2. Run database verification queries
3. Document final state

### ⏸️ Phase 5: Final Documentation (PENDING)

Update all documentation with final authentication methods.

---

## Important Files and Locations

### Backup Files (Created Today)
```
~/netbird-backup-20251203-132956.tar.gz      # System backup
~/zitadel-backup-20251203-133007.sql         # Database backup
~/auth-methods-before.txt                    # Authentication state
~/login-policy-before.txt                    # Login policy
```

### Configuration Files (No Changes Made)
```
~/netbird/docker-compose.yml                 # Service definitions
~/netbird/zitadel.env                        # Zitadel configuration
~/netbird/management.json                    # NetBird OIDC config
~/netbird/.env                               # Admin credentials
```

### Zitadel Console URLs
```
User Profile:     https://netbird.iyeska.net/ui/console/users/me
Admin Settings:   https://netbird.iyeska.net/ui/console/settings
Main Console:     https://netbird.iyeska.net/ui/console
```

### Database Access
```bash
# Connect to database
docker exec -it netbird-zdb-1 psql -U zitadel -d zitadel

# View authentication methods
docker exec netbird-zdb-1 psql -U zitadel -d zitadel -c \
  "SELECT user_id, method_type, state, name, creation_date \
   FROM projections.user_auth_methods5 \
   WHERE user_id = '349059759258730500' \
   ORDER BY creation_date;"
```

---

## Rollback Instructions

If anything goes wrong during Phase 2 or later:

### Rollback Option 1: Stay Logged In
- Keep your original browser session open
- Use it to troubleshoot or revert changes
- Don't log out until you've tested new method works

### Rollback Option 2: Microsoft Authenticator Still Works
- Microsoft Authenticator remains active until you verify 1Password works
- Can use it to log in if 1Password TOTP fails

### Rollback Option 3: Restore Database
```bash
# Stop containers
cd ~/netbird
docker compose down

# Restore database from backup
cat ~/zitadel-backup-20251203-133007.sql | \
  docker exec -i netbird-zdb-1 psql -U zitadel zitadel

# Start containers
docker compose up -d
```

### Rollback Option 4: Restore Entire System
```bash
# Stop containers
cd ~/netbird
docker compose down

# Remove current directory
cd ~
mv netbird netbird-broken

# Restore from backup
tar xzf netbird-backup-20251203-132956.tar.gz

# Start containers
cd ~/netbird
docker compose up -d
```

---

## When You Resume

1. Review this document
2. Check backups are still present
3. Verify NetBird services are running:
   ```bash
   cd ~/netbird
   docker compose ps
   ```
4. Continue with Phase 2 (TOTP migration to 1Password)
5. Use the step-by-step instructions above

---

## Support Resources

- **Full migration plan**: `~/.claude/plans/joyful-snacking-bubble.md`
- **Zitadel passkey docs**: https://zitadel.com/docs/guides/integrate/login-ui/passkey
- **1Password TOTP setup**: https://support.1password.com/one-time-passwords/

---

## Notes

- **No configuration files were modified** - all changes are database/UI based
- **All backups were successful** - you can safely proceed when ready
- **Current authentication still works** - Microsoft Authenticator is still active
- **Zero downtime approach** - old auth methods remain active until new ones are verified
- **30-day grace period recommended** - keep Microsoft Authenticator for 30 days after migration

---

## Contact/Resume Instructions

When you're ready to continue:
1. SSH back into the server
2. Tell Claude: "Resume the authentication migration from Phase 2"
3. Claude will guide you through the remaining browser/app actions

**Current status**: Safe to disconnect. All backups complete. No changes made to running system.
