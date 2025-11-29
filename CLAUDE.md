# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🚨 SECURITY ALERT

**READ `SECURITY_WARNING.md` IMMEDIATELY**

There is a critical security issue with the GitHub token being exposed in the git remote URL. This must be fixed before continuing work.

**Quick Fix:**
```bash
git remote set-url origin git@github.com:guthdx/claude_code.git
```

See [SECURITY_WARNING.md](SECURITY_WARNING.md) for complete details and verification.

---

## First-Time Setup on New Machine

**Tested and verified on M1 MacBook Pro (2025-11-27)**

### Prerequisites

```bash
# Required installations
✓ Claude Code (from https://claude.ai/code)
✓ Node.js 25.1.0+ (for MCP servers via npx)
✓ Git 2.50+
✓ NetBird VPN (for Memory MCP Server access)
○ Docker Desktop (optional, for Docker MCP)
```

### Step-by-Step Setup

**1. Clone Repository (use SSH to avoid token exposure):**
```bash
git clone git@github.com:guthdx/claude_code.git ~/terminal_projects/claude_code
cd ~/terminal_projects/claude_code
```

**⚠️ DO NOT USE:** `git clone https://TOKEN@github.com/...` - This exposes your token in git config!

**2. Set Up Memory MCP Server (Shared Memory Across Machines):**

**NEW!** This repository now includes Memory MCP Server setup for cross-machine memory sync:

```bash
cd ~/terminal_projects/claude_code
./setup-memory-mcp-client.sh
```

See `SETUP_ON_CLIENT.md` for quick instructions or `PHASE3_CLIENT_SETUP.md` for detailed docs.

**What this gives you:**
- Shared memory across all your development machines
- Works from anywhere (home, travel, coffee shops) via NetBird VPN
- Semantic search with BERT embeddings
- Real-time synchronization via PostgreSQL

**3. Set Environment Variables:**
```bash
# Create or edit ~/.zshrc
nano ~/.zshrc

# Add these lines:
export PERPLEXITY_API_KEY="your-key-here"
export GITHUB_TOKEN="your-token-here"

# Save (Ctrl+O, Enter, Ctrl+X) and reload
source ~/.zshrc
```

**3. Open Claude Code and Auto-Configure MCP:**
```bash
cd ~/terminal_projects/claude_code
claude
```

Then in Claude Code, say:
> "I just cloned this repository. Please read CLAUDE.md and SESSION_STATE.md, then set up all 5 MCP servers. The environment variables are already set."

**4. Verify Setup:**
```bash
claude mcp list
# Should show 5 servers: perplexity, memory, filesystem, docker, github
```

**Setup Time:** ~15 minutes (tested and verified)

**What Gets Auto-Configured:**
- ✅ MCP servers from `.mcp.json`
- ✅ Environment variable substitution
- ✅ npm package installation via npx
- ❌ Setting environment variables (manual)
- ❌ Installing Docker Desktop (manual)

---

## Repository Overview

This is a multi-project workspace containing development tools, infrastructure projects, and cultural/language applications. All projects are self-hosted on Iyeska infrastructure with a focus on data sovereignty and tribal contexts.

**Organization**: Iyeska LLC (tribal-focused technology services)

## Development Environment

**Workspace**: `/Users/guthdx/terminal_projects/claude_code` (main branch)

**Platform**: macOS (Darwin 24.6.0)

**Core Tools**:
- Node.js: v25.1.0
- npm: 11.6.2
- Git: 2.50.1
- Docker: 28.4.0
- Docker Compose: v2.39.2

**Python**:
- System Python: 3.10.0 (incompatible with most projects)
- MacPorts Python 3.13: 3.13.5 at `/opt/local/bin/python3.13` (use this for all Python projects)

**Remote Services**:
- code.iyeska.net - Remote Ollama API (Mac Mini) - operational

**MCP Servers** (Model Context Protocol):
All configured and operational. Verify status: `claude mcp list`

1. **Perplexity AI** - Web search and research
   - Package: `@perplexity-ai/mcp-server`
   - Tools: `mcp__perplexity_search`, `mcp__perplexity_ask`, `mcp__perplexity_research`, `mcp__perplexity_reason`
   - API key: `PERPLEXITY_API_KEY` in `~/.zshrc`

2. **Memory** - Knowledge graph for persistent context across sessions
   - Package: `@modelcontextprotocol/server-memory`
   - Maintains context and remembers project details between sessions

3. **Filesystem** - Secure file operations with access controls
   - Package: `@modelcontextprotocol/server-filesystem`
   - Scope: `/Users/guthdx/terminal_projects/claude_code`

4. **Docker** - Container and compose stack management
   - Package: `docker-mcp`
   - Manages all Docker containers (NetBird, n8n, etc.)

5. **GitHub** - Repository management, PRs, issues
   - Package: `@modelcontextprotocol/server-github`
   - API key: `GITHUB_TOKEN` in `~/.zshrc`

**Additional MCP Servers Available (Not Installed)**:
- SQLite - For status-dashboard D1 database work
- PostgreSQL - For NetBird database management
- Slack - Direct Slack integration for alerts
- Sequential Thinking - Complex problem solving
- Fetch - Web content extraction

**Important**: Always use Python 3.13 for Python projects. System Python 3.10 will fail with version errors.

## Repository Structure

This workspace contains 6 independent projects:

### 1. code_iyeska_net/
Remote AI coding assistance setup for VS Code Continue extension.

**Purpose**: Automates Continue extension installation to use remote Ollama models (Qwen2.5-Coder, DeepSeek-R1, Llama 3.3, Phi4) running on Mac Mini at `https://code.iyeska.net`.

**Key Files**:
- `setup-continue.sh` - Automated installer (checks VS Code, tests connection, installs extension, creates config with context settings)
- `continue-config.yaml` - Model configuration (8 models with contextLength and completionOptions)
- `README.md` - Setup documentation
- `TRANSFER-TO-M1.md` - Transfer instructions for other Macs

**Transfer to New Mac**:
```bash
# Quick setup on any Mac (includes context/memory config)
./setup-continue.sh
```

**Updated Configuration** (Nov 2025): Added context window settings to enable conversation memory:
- Each model configured with `contextLength` and `num_ctx` for proper context retention
- Temperature optimized per use-case (0.2 for code, 0.3 for reasoning)
- Response length tuned per model (2K-4K tokens)

### 2. lakota_app/
Lakota language learning and translation system.

**Purpose**: Three-layer architecture integrating English-Lakota dictionary (1,019 lines), Lakota pronunciation glossary (3,444 lines), and 12 essential sentences for grammar patterns.

**Data Sources**:
- `docs/309415410-english-lakota-dictionary.txt` - English→Lakota with pronunciation
- `docs/Lakota Pronunciation Glossary.txt` - Bidirectional glossary with phonetics
- `docs/12_essential_sentences.rtf` - Grammar/context training data

**Key Concepts**:
- Verb conjugation patterns (1st/2nd/3rd class)
- Special characters: á, č, ġ, ḣ, ǩ, ṗ, š, ṫ, ž, ŋ
- `/` in verbs indicates conjugation point (e.g., `má/ni` → `mawani`)

See `lakota_app/CLAUDE.md` for architecture details.

### 3. mbiri_poster/
Brand assets for Missouri Breaks Industries Research, Inc. (MBIRI).

**Contents**: Logo variations (star, name, tagline, mission), brand guidelines PDF, sample images.

**Assets**:
- `MBIRI Star.png` - Logo only
- `MBIRI Star with Name.png` - Logo + name
- `MBIRI Star with Name and Tagline Horizontal.png` - Full branding
- `MBIRI Brand Guidelines.pdf` - Official brand standards

### 4. project_starter_template/
Template files for bootstrapping new projects with Claude Code.

**Files**:
- `project_starter_kit_prompt.md.rtf` - Initial project setup prompt
- `claude_code_agent_strategy.md` - Agent architecture strategy
- `user_context_g3dx.md.rtf` - User context template

### 5. status-dashboard/
Serverless infrastructure monitoring dashboard on Cloudflare (100% free tier).

**Purpose**: Monitors 20+ services across 4 locations (NativeBio, TDR, Missouri Breaks, Iyeska HQ) with automated alerts to Slack via n8n.

**Architecture**:
- Frontend: Cloudflare Pages (static HTML/CSS/JS)
- Status checks: Cloudflare Workers (cron every 10 min)
- Database: Cloudflare D1 (SQLite)
- Alerts: Webhook to n8n → Slack

**Deployment**:
```bash
# Deploy frontend
wrangler pages deploy public --project-name iyeska-status-dashboard

# Deploy workers
wrangler deploy --config workers/wrangler-checker.toml
wrangler deploy --config workers/wrangler-api.toml
```

**URL**: https://status.iyeska.net

See `status-dashboard/CLAUDE.md` for detailed architecture, branding, and database schema.

### 6. wowasi_ya/
AI-powered project documentation generator (Lakota: "Assistant").

**Purpose**: Generates 15 standardized project documents from a simple description using Claude API with web search.

**Tech Stack**: Python 3.11+, FastAPI, Typer CLI, Pydantic, Presidio (PII detection)

**Core Workflow**:
```
User Input → Agent Discovery (local) → Privacy Check (local)
  → User Approval → Research (Claude API) → Generation (Claude API)
  → Quality Check (local) → Output (filesystem/Obsidian/Git)
```

**Setup** (Python 3.11+ required):
```bash
# System Python is 3.10 (won't work) - use 3.13
/opt/local/bin/python3.13 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env
# Edit .env and add ANTHROPIC_API_KEY
```

**Commands**:
```bash
wowasi generate "Project Name" "Description..."
wowasi discover "Project Name" "Description"
wowasi privacy-check "Text to scan"
pytest
```

**Deployment**: Port 8001 at https://wowasi.iyeska.net

See `wowasi_ya/CLAUDE.md` for detailed setup, API endpoints, and troubleshooting.

## Infrastructure Context

### Network Architecture

**Primary Domain**: iyeska.net (Cloudflare DNS)

**Key Services**:
- `code.iyeska.net` - Remote Ollama API (Mac Mini)
- `status.iyeska.net` - Infrastructure monitoring dashboard
- `wowasi.iyeska.net` - Project documentation generator API
- `n8n.iyeska.net` - Workflow automation platform
- `netbird.iyeska.net` - Self-hosted VPN (WireGuard)

**Locations Monitored**:
1. **NativeBio** - Proxmox 8 VE, REDCap, pfSense
2. **TDR** - Proxmox 9 VE, multiple VMs
3. **Missouri Breaks** - mbiri.net servers, pfSense
4. **Iyeska HQ** - Main server, Mac Mini, Raspberry Pi NAS

### Remote AI Models (code.iyeska.net)

Available via Continue extension:
- Qwen2.5-Coder 32B (32.8B params, Q4_K_M) - Best for coding
- Qwen2.5-Coder 14B (14.8B params) - Fast coding + autocomplete
- DeepSeek-R1 32B (32.8B params) - Reasoning with thinking process
- DeepSeek-R1 14B (14.8B params) - Fast reasoning
- DeepSeek-R1 7B (7.6B params) - Quick tasks
- Llama 3.3 (70.6B params) - General purpose
- Phi4 (14.7B params) - Lightweight chat

**Connection Test**:
```bash
curl https://code.iyeska.net/api/tags
```

### NetBird VPN Setup

Self-hosted WireGuard VPN with Zitadel authentication.

**Configuration** (see `netbird-installation-guide.md`):
- Domain: netbird.iyeska.net
- Server: Ubuntu 24.04.3 LTS at 192.168.11.20
- Public IP: 68.168.225.52
- Docker Compose with 9 containers (Caddy, Zitadel, PostgreSQL, Signal, Relay, TURN, Dashboard, Management)

**Port Forwarding** (pfSense):
- 80/TCP, 443/TCP - HTTP/HTTPS
- 10000/TCP - Signal server
- 3478/UDP - STUN/TURN
- 33073/UDP - TURN relay
- 33080/TCP - Relay service
- 49152-65535/UDP - Dynamic relay range

**Management**:
```bash
cd ~/netbird
docker compose ps
docker compose logs -f
```

## Common Development Patterns

### VS Code with Remote AI

All development machines should use Continue extension with remote Ollama:

1. Run `code_iyeska_net/setup-continue.sh`
2. Reload VS Code
3. Select model in Continue panel
4. Use `Cmd+L` (chat), `Cmd+I` (inline edit)

**Context/Memory Configuration**: The setup script includes proper context window settings:
- Qwen models: 32K context (remembers ~24K words per session)
- Llama 3.3: 131K context (massive conversation memory)
- DeepSeek-R1: 32K context with longer responses (4K tokens)
- Temperature: 0.2 for code (precise), 0.3 for reasoning (creative)

**Note**: Context persists within a chat session but resets when starting a new chat or restarting VS Code.

### Python Projects

Python projects require 3.11+ (system has 3.10 which is incompatible):

```bash
# Always use MacPorts Python 3.13
/opt/local/bin/python3.13 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

### Cloudflare Deployments

All Cloudflare projects use Wrangler:

```bash
# Pages
wrangler pages deploy public --project-name PROJECT_NAME

# Workers
wrangler deploy --config wrangler.toml

# D1 Database
wrangler d1 execute DB_NAME --file schema.sql
```

### Docker Services

Most services run in Docker:

```bash
docker compose up -d
docker compose logs -f SERVICE_NAME
docker compose restart SERVICE_NAME
```

## Project-Specific Documentation

Each project has its own `CLAUDE.md` with detailed architecture:

- `lakota_app/CLAUDE.md` - Language system architecture
- `status-dashboard/CLAUDE.md` - Monitoring system, branding, database schema
- `wowasi_ya/CLAUDE.md` - API endpoints, setup, troubleshooting

## Cross-Machine Synchronization

This workspace is configured for seamless sync across multiple development machines.

### Tier 1: Project-Level Configs (Git-Based) ✅

**Status**: Fully operational and ready to use

**What syncs automatically:**
- `.mcp.json` - MCP server configurations (with env var placeholders)
- `CLAUDE.md` files - Project documentation
- All project code and configs

**Setup on new machine:**
```bash
# 1. Clone repository
git clone <repo-url> ~/terminal_projects/claude_code
cd ~/terminal_projects/claude_code

# 2. Set environment variables in ~/.zshrc
export PERPLEXITY_API_KEY="your-key-here"
export GITHUB_TOKEN="your-token-here"

# 3. Reload shell
source ~/.zshrc

# 4. Open in Claude Code - MCP servers auto-configure
```

**Security**: API keys use environment variable placeholders (`${PERPLEXITY_API_KEY}`) - safe to commit

### Tier 2: Personal Configs (Dotfiles Repository)

**Not yet implemented** - Manual setup required

**Purpose**: Sync personal configs (`~/.zshrc`, `~/.claude.json`) across machines

**Recommended approach:**
```bash
# Create dotfiles repository
cd ~
git init dotfiles
cd dotfiles

# Symlink configs
ln -s ~/.zshrc zshrc
ln -s ~/.claude.json claude.json

# Commit and push to private repo
git add .
git commit -m "Initial dotfiles"
git push origin main
```

### Tier 3: Shared Memory Backend (PostgreSQL)

**Status**: Comprehensive implementation guide available

**Purpose**: True persistent memory across all machines using self-hosted PostgreSQL

**Recommended solution**: PostgreSQL + pgvector on existing NetBird infrastructure (192.168.11.20)

**Benefits:**
- Semantic search with BERT embeddings
- Knowledge graph shared across all machines
- Leverages existing PostgreSQL database
- 4-6 hour implementation effort

**See**: Agent-generated implementation guide for complete setup instructions

## Data Sovereignty Principles

All projects follow these principles:

1. **Self-Hosted First** - No reliance on external cloud services where possible
2. **Privacy-First** - PII/PHI detection before API calls (wowasi_ya)
3. **User Approval Gates** - Explicit consent before external API usage
4. **Audit Logging** - Track all API interactions for compliance
5. **Tribal Context** - Designed for tribal, rural, and sovereignty-focused organizations

## Troubleshooting

### Continue Extension Not Remembering Conversation

**Symptoms**: Model forgets previous messages in the same chat session

**Solution**: Check that `~/.continue/config.yaml` includes context settings:
```yaml
models:
  - name: Qwen2.5-Coder 32B
    provider: ollama
    model: qwen2.5-coder:32b
    apiBase: https://code.iyeska.net
    contextLength: 32768        # This is required
    completionOptions:
      num_ctx: 32768            # This is required for Ollama
      temperature: 0.2
      num_predict: 2048
```

If missing, run the updated setup script: `code_iyeska_net/setup-continue.sh`

### code.iyeska.net Not Responding

**Test connection**:
```bash
curl https://code.iyeska.net/api/tags
```

**Common causes**:
1. Mac Mini went to sleep
2. Ollama service not running: SSH to Mac Mini and run `ollama list`
3. Cloudflare tunnel or NetBird VPN down

### Python Projects Failing with Version Error

**Error**: `Package requires a different Python: 3.10.0 not in '>=3.11'`

**Solution**: Use MacPorts Python 3.13:
```bash
/opt/local/bin/python3.13 -m venv .venv
source .venv/bin/activate
```

System Python is 3.10 which is incompatible with modern projects.
