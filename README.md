# Claude Code Workspace

Multi-project development workspace for Iyeska LLC infrastructure, applications, and cultural projects.

---

## 🚨 SECURITY ALERT - READ FIRST

**If you just cloned or pulled this repository, READ `SECURITY_WARNING.md` IMMEDIATELY.**

There is a known security issue with GitHub token exposure in git remote URLs that must be fixed before proceeding.

**Quick fix:**
```bash
git remote set-url origin git@github.com:guthdx/claude_code.git
```

See [SECURITY_WARNING.md](SECURITY_WARNING.md) for complete details.

---

## Overview

This workspace contains 6 independent projects:

1. **code_iyeska_net/** - Remote AI coding setup (VS Code Continue extension)
2. **lakota_app/** - Lakota language learning and translation system
3. **mbiri_poster/** - MBIRI brand assets and guidelines
4. **project_starter_template/** - Bootstrap templates for new projects
5. **status-dashboard/** - Infrastructure monitoring (Cloudflare Pages/Workers)
6. **wowasi_ya/** - AI-powered project documentation generator

## Quick Start

### 🚀 Automated Setup (Recommended)

**One command to set up everything:**

```bash
curl -fsSL https://raw.githubusercontent.com/guthdx/claude_code/main/setup-machine.sh | bash
```

This automated script will:
- ✅ Check prerequisites (Node.js, Git, Claude Code)
- ✅ Set up SSH authentication with GitHub
- ✅ Clone the repository
- ✅ Configure environment variables (prompts for API keys)
- ✅ Verify MCP server configuration
- ⏱️ **Time: ~5 minutes**

See [QUICK_SETUP.md](QUICK_SETUP.md) for detailed instructions.

---

### 📋 Manual Setup

If you prefer to set up manually:

#### Prerequisites
- Node.js 25.1.0+ and npm 11.6.2+
- Python 3.13+ (at `/opt/local/bin/python3.13`)
- Docker Desktop (optional, for container management)
- Git 2.50+

#### Setup Steps

1. **Clone repository:**
   ```bash
   git clone git@github.com:guthdx/claude_code.git
   cd claude_code
   ```

2. **Set environment variables** in `~/.zshrc`:
   ```bash
   export PERPLEXITY_API_KEY="your-key-here"
   export GITHUB_TOKEN="your-token-here"
   source ~/.zshrc
   ```

3. **Open in Claude Code:**
   ```bash
   claude
   ```

   MCP servers will auto-configure from `.mcp.json`

See [CLAUDE.md](CLAUDE.md) for complete manual setup instructions.

## MCP Servers

This workspace uses 5 Model Context Protocol servers:

- **Perplexity AI** - Web search and research
- **Memory** - Knowledge graph for persistent context
- **Filesystem** - Secure file operations
- **Docker** - Container management
- **GitHub** - Repository operations

Verify: `claude mcp list`

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete workspace documentation (read this!)
- **[SESSION_STATE.md](SESSION_STATE.md)** - Current work state and pending tasks
- **[SECURITY_WARNING.md](SECURITY_WARNING.md)** - Security issues and fixes
- **[MEMORY_BACKEND_IMPLEMENTATION.md](MEMORY_BACKEND_IMPLEMENTATION.md)** - PostgreSQL setup guide

Each project has its own `CLAUDE.md` with specific details.

## Infrastructure

**Remote Services:**
- code.iyeska.net - Ollama API (Mac Mini)
- status.iyeska.net - Infrastructure monitoring
- wowasi.iyeska.net - Documentation generator
- n8n.iyeska.net - Workflow automation
- netbird.iyeska.net - Self-hosted VPN

**Locations Monitored:**
- NativeBio - Proxmox 8 VE, REDCap, pfSense
- TDR - Proxmox 9 VE
- Missouri Breaks - mbiri.net servers
- Iyeska HQ - Main infrastructure

## Organization

**Iyeska LLC** - Tribal-focused technology services emphasizing data sovereignty and self-hosted solutions.

## License

Proprietary - All rights reserved by Iyeska LLC.

---

**Important:** Always read `SECURITY_WARNING.md` when setting up on a new machine.
