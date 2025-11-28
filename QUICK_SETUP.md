# Quick Setup Guide

Automated setup script for Mac Mini, Ubuntu Server, and any new machine.

## 🚀 One-Line Setup (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/guthdx/claude_code/main/setup-machine.sh | bash
```

**What it does:**
1. ✅ Checks prerequisites (Node.js, Git, Claude Code)
2. ✅ Sets up SSH key for GitHub (if needed)
3. ✅ Clones repository to `~/terminal_projects/claude_code`
4. ✅ Configures environment variables (prompts for API keys)
5. ✅ Checks Docker installation
6. ✅ Verifies MCP configuration
7. ✅ Provides next steps

**Time:** ~5 minutes (mostly prompts)

---

## 📋 Manual Setup (If You Prefer)

### Prerequisites

```bash
# Check what you have
node --version   # Need 25.1.0+
git --version    # Need 2.50+
claude --version # Need Claude Code installed
```

### Install Missing Prerequisites

**macOS:**
```bash
# Node.js - download from https://nodejs.org/
# Claude Code - download from https://claude.ai/code
```

**Ubuntu/Linux:**
```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_25.x | sudo -E bash -
sudo apt-get install -y nodejs

# Claude Code
# Follow instructions at https://claude.ai/code
```

### Run Setup Script

```bash
# Download script
curl -fsSL https://raw.githubusercontent.com/guthdx/claude_code/main/setup-machine.sh -o setup.sh

# Make executable
chmod +x setup.sh

# Run it
./setup.sh
```

---

## 🖥️ Machine-Specific Notes

### Mac Mini

**Pre-setup:**
- ✅ Node.js likely already installed
- ✅ Git likely already installed
- ⚠️ May need to install Claude Code
- ✅ Docker Desktop recommended

**Run:**
```bash
curl -fsSL https://raw.githubusercontent.com/guthdx/claude_code/main/setup-machine.sh | bash
```

### Ubuntu Server

**Pre-setup:**
- ⚠️ May need Node.js 25+
- ✅ Git likely installed
- ⚠️ Need to install Claude Code
- ⚠️ Docker optional (script can install)

**Run:**
```bash
# Update system first
sudo apt update && sudo apt upgrade -y

# Run setup
curl -fsSL https://raw.githubusercontent.com/guthdx/claude_code/main/setup-machine.sh | bash
```

### M1 MacBook Pro

Already set up manually. To verify or update:

```bash
cd ~/terminal_projects/claude_code
git pull origin main
source ~/.zshrc
claude mcp list
```

---

## 🔑 API Keys Needed

Have these ready when running the script:

1. **Perplexity API Key**
   - Get from: https://www.perplexity.ai/settings/api
   - Current: `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`

2. **GitHub Personal Access Token**
   - Get from: https://github.com/settings/tokens
   - Current: `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`
   - ⚠️ **Rotate after setup** (see SECURITY_WARNING.md)

The script will prompt for these during setup.

---

## ✅ After Setup

### 1. Reload Shell

```bash
source ~/.zshrc  # or ~/.bashrc on Linux
```

### 2. Navigate to Workspace

```bash
cd ~/terminal_projects/claude_code
```

### 3. Start Claude Code

```bash
claude
```

### 4. Auto-Configure MCP Servers

In Claude Code, say:

> "I just ran the setup script. Please read CLAUDE.md and SESSION_STATE.md, then verify all 5 MCP servers are configured."

### 5. Verify

```bash
claude mcp list
```

Should show:
- ✅ perplexity (web search)
- ✅ memory (knowledge graph)
- ✅ filesystem (file operations)
- ✅ docker (container management - if Docker installed)
- ✅ github (repo operations)

---

## 🔧 Troubleshooting

### "SSH authentication failed"

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: https://github.com/settings/keys
```

### "Docker not running"

**macOS:**
- Open Docker Desktop application

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker  # Auto-start on boot
```

### "Claude Code not found"

```bash
# Download and install from:
# https://claude.ai/code
```

### "MCP servers not connecting"

```bash
# Check environment variables
echo $PERPLEXITY_API_KEY
echo $GITHUB_TOKEN

# Reload shell
source ~/.zshrc  # or ~/.bashrc

# Restart Claude Code
```

---

## 🛡️ Security Notes

1. **Never commit API keys to git**
   - They're in `~/.zshrc` or `~/.bashrc` (not in git)
   - Project `.mcp.json` uses `${VAR}` placeholders only

2. **Use SSH for git, not HTTPS with tokens**
   - ✅ Good: `git@github.com:guthdx/claude_code.git`
   - ❌ Bad: `https://TOKEN@github.com/guthdx/claude_code.git`

3. **Rotate the exposed GitHub token**
   - See `SECURITY_WARNING.md` for details
   - Do this after setting up all machines

---

## 📊 What Gets Set Up

| Component | Location | Purpose |
|-----------|----------|---------|
| Repository | `~/terminal_projects/claude_code` | Main workspace |
| Env vars | `~/.zshrc` or `~/.bashrc` | API keys |
| MCP config | `.mcp.json` | MCP server definitions |
| SSH key | `~/.ssh/id_ed25519` | GitHub authentication |

---

## ⏱️ Setup Time

| Machine | Estimated Time | Notes |
|---------|---------------|-------|
| Mac Mini | ~5 minutes | If Node.js already installed |
| Ubuntu Server | ~10 minutes | May need to install Node.js |
| Fresh Mac | ~15 minutes | Install Node.js + Claude Code |

---

## 🆘 Need Help?

1. **Read the docs:**
   - `CLAUDE.md` - Complete workspace documentation
   - `SESSION_STATE.md` - Current state and tasks
   - `SECURITY_WARNING.md` - Security issues and fixes

2. **Check logs:**
   - Script shows detailed output
   - Look for ✓ (success) or ✗ (error) symbols

3. **Manual setup:**
   - If script fails, follow manual steps in `CLAUDE.md`
   - Section: "First-Time Setup on New Machine"

---

**Last Updated:** 2025-11-27
**Tested On:** macOS (M1, main Mac), Ubuntu Server (pending)
