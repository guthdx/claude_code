#!/bin/bash

echo "=== GIT SECURITY CHECK ==="
echo "Machine: $(hostname)"
echo "Date: $(date)"
echo ""

echo "=== 1. CHECKING GIT REMOTE URL ==="
cd ~/terminal_projects/claude_code 2>/dev/null || cd ~/Documents/claude_code 2>/dev/null || cd ~/claude_code 2>/dev/null || {
    echo "ERROR: Repository not found in common locations"
    echo "Please cd to the repository and run: git remote -v"
    exit 1
}

echo "Current directory: $(pwd)"
echo ""
echo "Remote URLs:"
git remote -v
echo ""

# Check if URL contains a token
if git remote -v | grep -E "https://.*@github.com"; then
    echo "⚠️  WARNING: Token found in remote URL!"
    echo "❌ SECURITY ISSUE: Token is embedded in git remote"
else
    echo "✅ No token in remote URL"
fi
echo ""

echo "=== 2. CHECKING GIT CONFIG FOR TOKENS ==="
if git config --list | grep -iE "(url.*github|remote.*url)" | grep -E "ghp_|github_pat_"; then
    echo "⚠️  WARNING: Token found in git config!"
else
    echo "✅ No tokens found in git config"
fi
echo ""

echo "=== 3. TESTING SSH AUTHENTICATION ==="
ssh -T git@github.com 2>&1 | head -1
echo ""

echo "=== 4. SUMMARY ==="
REMOTE_URL=$(git config --get remote.origin.url)
echo "Remote URL: $REMOTE_URL"

if [[ $REMOTE_URL == git@github.com:* ]]; then
    echo "✅ STATUS: SECURE (using SSH)"
elif [[ $REMOTE_URL == https://github.com/* ]] && [[ $REMOTE_URL != *@* ]]; then
    echo "⚠️  STATUS: HTTPS without embedded token (acceptable if using credential helper)"
elif [[ $REMOTE_URL == *@github.com* ]]; then
    echo "❌ STATUS: INSECURE - Token embedded in URL"
else
    echo "❓ STATUS: Unknown URL format"
fi
