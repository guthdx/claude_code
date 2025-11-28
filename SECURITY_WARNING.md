# 🚨 CRITICAL SECURITY ISSUE - READ IMMEDIATELY

**Date**: 2025-11-27
**Severity**: HIGH
**Status**: REQUIRES IMMEDIATE ACTION

---

## ⚠️ GitHub Token Exposed in Git Remote URL

### The Problem

The GitHub personal access token is **embedded in plaintext** in the git remote URL:

```bash
git remote -v
# Shows: https://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@github.com/guthdx/claude_code.git
```

**This is a security vulnerability because:**
1. The token is visible in git configuration files
2. It may be logged in shell history
3. It could be exposed in error messages or logs
4. Anyone with access to the repository can see the token

### The Solution

**IMMEDIATE ACTION REQUIRED:** Switch to SSH authentication or use Git credential helper.

#### Option 1: SSH (Recommended)

```bash
# 1. Ensure SSH key is set up with GitHub
ssh -T git@github.com

# 2. Update remote URL to use SSH
git remote set-url origin git@github.com:guthdx/claude_code.git

# 3. Verify change
git remote -v
# Should show: git@github.com:guthdx/claude_code.git
```

#### Option 2: Git Credential Helper (Alternative)

```bash
# 1. Remove token from URL
git remote set-url origin https://github.com/guthdx/claude_code.git

# 2. Configure credential helper (macOS Keychain)
git config --global credential.helper osxkeychain

# 3. Next git push will prompt for credentials and store them securely
```

---

## 🔐 Additional Security Recommendations

### 1. Rotate the Exposed Token

The current token `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` should be considered **compromised**.

**⚠️ RECOMMENDATION: YES - Rotate the token immediately**

**Rationale:**
- Token was embedded in git remote URL on M1 machine
- May be visible in shell history, git logs, or error messages
- Could be exposed in any backups or snapshots of the git config
- Best practice: assume exposed and rotate as precaution

**Action Steps:**
1. Go to https://github.com/settings/tokens
2. Delete token `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`
3. Generate new token with same scopes:
   - `repo` (full control of private repositories)
   - `workflow` (if using GitHub Actions)
   - `read:org` (if needed for MCP server)
4. Update `~/.zshrc` on all machines with new token:
   ```bash
   export GITHUB_TOKEN="ghp_NEW_TOKEN_HERE"
   ```
5. Reload shell: `source ~/.zshrc`
6. **DO NOT** use token in git remote URLs (use SSH instead)

### 2. Check for Token Exposure

```bash
# Check git configuration
git config --list | grep url

# Check shell history for token
history | grep ghp_

# Clear sensitive history if needed
history -c
```

### 3. Environment Variable Security

The token is also stored in `~/.zshrc`:
```bash
export GITHUB_TOKEN="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"
```

**This is acceptable for:**
- Single-user machines
- MCP server authentication (doesn't expose it in git)

**But NOT for:**
- Shared machines
- Dotfiles committed to public repositories
- Git remote URLs (current issue)

---

## ✅ Verification Checklist

After fixing, verify:

### Main Mac (guthdx) - COMPLETED:
- [✅] Git remote uses SSH: `git remote -v` shows `git@github.com:guthdx/claude_code.git`
- [✅] No token in git config: Verified clean
- [✅] SSH authentication works: `ssh -T git@github.com` successful
- [✅] Can pull/push without token: Tested successfully
- [⚠️] Old token rotation: PENDING - User action required

### M1 MacBook Pro - PENDING:
- [ ] Git remote uses SSH: `git remote -v` shows `git@github.com:...`
- [ ] No token in git config: `git config --list | grep -i github`
- [ ] SSH authentication works: `ssh -T git@github.com`
- [ ] Can push without token in URL: `git push origin main`
- [ ] Updated status table in this file

---

## 📋 Status on Each Machine

| Machine | Issue Fixed? | Method Used | Verified |
|---------|-------------|-------------|----------|
| M1 MacBook Pro | ⚠️ REQUIRES FIX | See M1 Instructions Below | ❌ |
| Main Mac (guthdx) | ✅ YES | SSH | ✅ |

**UPDATE THIS TABLE AFTER FIXING ON EACH MACHINE**

---

## 🎯 Action Required

**Before continuing work on this repository:**
1. Read this entire document
2. Choose SSH or credential helper method
3. Update git remote URL
4. Verify with checklist above
5. Update status table
6. Commit this file with your verification

**Do not ignore this warning.** Token exposure can lead to:
- Unauthorized repository access
- Malicious code commits
- Account compromise
- Data breaches

---

## 🔧 M1 MacBook Pro - Specific Fix Instructions

**CRITICAL**: The M1 MacBook Pro has the token embedded in the git remote URL.

### Immediate Steps to Run on M1:

```bash
# 1. Navigate to repository
cd /Users/guthdx/terminal_projects/claude_code

# 2. Check current remote (should show token in URL)
git remote -v

# 3. Test if SSH is configured
ssh -T git@github.com

# 4. If SSH works, switch to SSH
git remote set-url origin git@github.com:guthdx/claude_code.git

# 5. Verify change
git remote -v
# Should now show: git@github.com:guthdx/claude_code.git

# 6. Test git operations
git fetch --dry-run

# 7. Update status in SECURITY_WARNING.md
# Change M1 MacBook Pro row to: ✅ YES | SSH | ✅

# 8. Commit and push
git add SECURITY_WARNING.md
git commit -m "Security: Fixed token exposure on M1"
git push
```

### If SSH Doesn't Work on M1:

```bash
# Alternative: Use credential helper instead
git remote set-url origin https://github.com/guthdx/claude_code.git
git config --global credential.helper osxkeychain

# Next push will prompt for credentials
# Username: guthdx
# Password: (use a new token, NOT the exposed one)
```

### Verification Checklist for M1:

- [ ] `git remote -v` shows NO token in URL
- [ ] `git config --list | grep url` shows NO token
- [ ] `cat .git/config` shows NO token
- [ ] Test `git fetch` works successfully
- [ ] Test `git push` works successfully
- [ ] Update status table in this file
- [ ] Commit changes to this file

---

**Last Updated**: 2025-11-27 by Claude Code (Main Mac - guthdx)
**Next Review**: Immediately upon opening this repository on M1 MacBook Pro
