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

**Action:**
1. Go to https://github.com/settings/tokens
2. Delete the current token
3. Generate a new token with appropriate scopes
4. Update `~/.zshrc` with the new token
5. Use SSH going forward (no token in git config)

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

- [ ] Git remote uses SSH: `git remote -v` shows `git@github.com:...`
- [ ] No token in git config: `git config --list | grep -i github`
- [ ] SSH authentication works: `ssh -T git@github.com`
- [ ] Can push without token in URL: `git push origin main`
- [ ] Old token rotated at https://github.com/settings/tokens

---

## 📋 Status on Each Machine

| Machine | Issue Fixed? | Method Used | Verified |
|---------|-------------|-------------|----------|
| M1 MacBook Pro (current) | ❌ NO | N/A | N/A |
| M4 MacBook Pro | ⚠️ PENDING | TBD | TBD |

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

**Last Updated**: 2025-11-27 by Claude Code (M1 MacBook Pro)
**Next Review**: Immediately upon opening this repository on any machine
