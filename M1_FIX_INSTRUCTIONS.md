# M1 MacBook Pro - Quick Fix Instructions

**CRITICAL SECURITY FIX - Run these commands immediately**

## Quick Fix (Copy and paste all commands)

```bash
# 1. Navigate to repository
cd /Users/guthdx/terminal_projects/claude_code

# 2. Verify the problem exists (should show token in URL)
echo "Current remote URL:"
git remote -v

# 3. Test SSH (should say "Hi guthdx!")
echo "Testing SSH..."
ssh -T git@github.com

# 4. Fix: Switch to SSH
echo "Switching to SSH..."
git remote set-url origin git@github.com:guthdx/claude_code.git

# 5. Verify fix
echo "New remote URL (should NOT contain token):"
git remote -v

# 6. Verify git config is clean
echo "Checking git config (should NOT contain token):"
cat .git/config

# 7. Test git operations
echo "Testing git fetch..."
git fetch --dry-run

echo "✅ Fix complete! Now update SECURITY_WARNING.md"
```

## After Running Commands:

1. Open `SECURITY_WARNING.md`
2. Update the status table:
   - Change M1 row to: `✅ YES | SSH | ✅`
3. Mark M1 verification checklist items as complete
4. Commit and push:
   ```bash
   git add SECURITY_WARNING.md M1_FIX_INSTRUCTIONS.md
   git commit -m "Security: Fixed token exposure on M1"
   git push
   ```

## If SSH Doesn't Work:

If `ssh -T git@github.com` fails:

```bash
# Use credential helper instead
git remote set-url origin https://github.com/guthdx/claude_code.git
git config --global credential.helper osxkeychain

# Next push will prompt for credentials
# Username: guthdx
# Password: [Generate NEW token at https://github.com/settings/tokens]
```

## What Was Fixed:

- **Main Mac (guthdx)**: Already clean, switched to SSH for consistency
- **M1 MacBook Pro**: Contains token in git remote URL - NEEDS FIX

## Why This Matters:

The token `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` was embedded in the git configuration on M1. This means:
- It's visible in plaintext in `.git/config`
- It may be in shell history
- It could be in git logs or error messages
- Anyone with access to the repository could see it

## Next Steps After Fix:

1. Rotate the exposed token at https://github.com/settings/tokens
2. Generate new token with same scopes
3. Update `~/.zshrc` with new token on all machines
4. Never use tokens in git remote URLs again (use SSH)

---

**See SECURITY_WARNING.md for full details**
