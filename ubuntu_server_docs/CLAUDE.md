# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a home directory server (`/home/guthdx`) running multiple self-hosted services on Ubuntu Linux. The server hosts various applications tunneled through Cloudflare Tunnel to public domains under `iyeska.net`.

## Infrastructure Architecture

### Cloudflare Tunnel Configuration

The server uses Cloudflare Tunnel (`cloudflared`) to expose local services to the internet without opening ports. Configuration is located at:
- **Config file**: `~/.cloudflared/config.yml`
- **Service file**: `/etc/systemd/system/cloudflared.service`
- **Tunnel ID**: `1e02b2ec-7f02-4cf5-962f-0db3558e270c`

**Active tunnel mappings:**
- `n8n.iyeska.net` → `http://localhost:5678` (n8n automation)
- `recap.iyeska.net` → `http://localhost:8088` (RECAP search webapp)
- `stoic.iyeska.net` → `http://localhost:3333`
- `wowasi.iyeska.net` → `http://localhost:8001`
- `code.iyeska.net` → `http://192.168.11.17:11434` (Ollama on Mac Mini)

**YAML format requirements:** Each ingress rule MUST have both `hostname` and `service` on the same entry with proper indentation. The catch-all rule must be last.

### Managing Cloudflared Tunnel

```bash
# Check tunnel status
sudo systemctl status cloudflared

# View tunnel logs
sudo journalctl -u cloudflared -n 50 --no-pager

# Restart tunnel (after config changes)
sudo systemctl restart cloudflared

# Edit tunnel configuration
nano ~/.cloudflared/config.yml
```

### Docker Services

Multiple services run via Docker Compose:
- **NetBird VPN** (`docker-compose.yml` in root) - Self-hosted VPN mesh network with Zitadel identity provider
- **n8n** (`n8n/docker-compose.yml`) - Workflow automation platform
- **FastAPI-React-Postgres Template** (`/opt/apps/test-deployment/`) - Full-stack application template with FastAPI backend, React frontend, and PostgreSQL database

```bash
# Check running containers
docker ps

# View service logs
docker compose logs -f [service-name]

# Restart services
docker compose restart [service-name]
```

### Process Management with PM2

Some Node.js services are managed via PM2:
```bash
# List all PM2 processes
pm2 list

# View logs for a specific process
pm2 logs [process-name]

# Restart a process
pm2 restart [process-name]

# Save PM2 process list
pm2 save
```

## Major Projects

### 1. CourtListener/RECAP Client (`courtlistener/`)

Python client for accessing bankruptcy case data from the CourtListener/RECAP archive. Provides free alternative to PACER for bankruptcy records.

**Key files:**
- `courtlistener/client.py` - Core API client
- `courtlistener/bankruptcy.py` - Bankruptcy-specific searches
- `webapp/` - Flask web interface (runs on port 8088)

**Setup:**
```bash
cd ~/courtlistener
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Running the webapp:**
```bash
# Service runs automatically via systemd
sudo systemctl status recap-search.service

# Manual run for testing
cd ~/courtlistener/webapp
source ../venv/bin/activate
python app.py
```

### 2. n8n Workflow Automation

Self-hosted n8n instance for workflow automation.

**Access:**
- Local: `http://localhost:5678`
- Public: `https://n8n.iyeska.net`

**Data location:**
- Configuration: `~/.n8n/`
- Docker setup: `~/n8n/docker-compose.yml`

**Management:**
```bash
cd ~/n8n
docker compose up -d
docker compose logs -f
```

### 3. Obsidian Vault Sync (`obsidian-vault/`)

Personal knowledge base synced automatically.

**Sync script:** `~/obsidian-sync.sh`
```bash
# View sync logs
tail -f ~/.obsidian-sync.log
```

### 4. Iyeska Scorecard Projects

Two related projects for scorecard functionality:
- `~/iyeska-scorecard/` - Frontend
- `~/iyeska-scorecard-api/` - Backend API

### 5. FastAPI-React-Postgres Template (`/opt/apps/test-deployment/`)

Production-ready full-stack application template serving as a reference implementation and testing ground.

**GitHub**: https://github.com/guthdx/fastapi-react-postgres-template

**Stack:**
- Backend: FastAPI with async SQLAlchemy
- Frontend: React + Vite + Nginx
- Database: PostgreSQL 16
- Deployment: Docker Compose

**Access:**
- Frontend: `http://192.168.11.20:5174`
- Backend API: `http://192.168.11.20:8001`
- API Docs: `http://192.168.11.20:8001/api/v1/docs`

**Key Features:**
- Health check endpoints on all services
- CORS configuration via environment variables
- Docker health checks with auto-restart
- Production-optimized Nginx configuration
- Environment-based configuration

**Management:**
```bash
cd /opt/apps/test-deployment

# Start all services
docker compose -f docker-compose.production.yml up -d

# View logs
docker compose -f docker-compose.production.yml logs -f

# Check status
docker compose -f docker-compose.production.yml ps

# Restart services
docker compose -f docker-compose.production.yml restart

# Stop all services
docker compose -f docker-compose.production.yml down

# Health checks
curl http://localhost:8001/api/v1/health  # Backend + DB status
curl http://localhost:5174/health          # Frontend status
```

**Environment Configuration:**
Located at `/opt/apps/test-deployment/.env`:
- `COMPOSE_PROJECT_NAME=test-deployment`
- `POSTGRES_DB=test_deployment_db`
- `POSTGRES_PASSWORD=TestPass123!Change`
- `BACKEND_PORT=8001`
- `FRONTEND_PORT=5174`
- `VITE_API_BASE_URL=http://192.168.11.20:8001`
- `BACKEND_CORS_ORIGINS=http://192.168.11.20:5174`

**Note:** Port 8001 is shared with wowasi_ya. If wowasi_ya needs to run, stop this deployment or reconfigure ports.

## System Services

### Service Management

```bash
# Cloudflared tunnel
sudo systemctl status cloudflared
sudo systemctl restart cloudflared

# RECAP search webapp
sudo systemctl status recap-search.service
sudo systemctl restart recap-search.service

# View service logs
sudo journalctl -u [service-name] -f
```

### Network Services

- **Ollama** - Runs locally on this machine (`localhost:11434`) and on Mac Mini (`192.168.11.17:11434`)
- **NetBird VPN** - Mesh VPN network for secure remote access

## Environment Files

Multiple `.env` files for different services:
- `~/.env` - Main environment variables
- `~/dashboard.env` - NetBird dashboard config
- `~/relay.env` - NetBird relay config
- `~/zitadel.env` - Zitadel identity provider config
- `~/zdb.env` - Postgres database for Zitadel

**Important:** Never commit `.env` files or expose API tokens.

## Common Commands

### Check What's Running
```bash
# System services
sudo systemctl list-units --type=service --state=running

# Docker containers
docker ps

# PM2 processes
pm2 list

# Network ports in use
sudo ss -tlnp
```

### Troubleshooting Cloudflared

The tunnel service restarts automatically on failure. Common issues:

1. **Invalid service address** - Check `~/.cloudflared/config.yml` for proper YAML format
2. **Backend service down** - Ensure target service (e.g., `localhost:5678`) is running
3. **Port conflicts** - Check if port is already in use: `sudo lsof -i :PORT`

### Checking Logs
```bash
# Cloudflared tunnel
sudo journalctl -u cloudflared -n 100 --no-pager

# RECAP webapp
sudo journalctl -u recap-search.service -n 100 --no-pager

# Docker services
docker compose logs -f --tail=100 [service-name]

# System logs
sudo journalctl -xe
```

## Key Directories

- `~/courtlistener/` - RECAP bankruptcy search client
- `~/webapp/` - Web applications
- `~/n8n/` - n8n workflow automation
- `~/obsidian-vault/` - Personal knowledge base
- `~/iyeska-scorecard/` - Scorecard frontend
- `~/iyeska-scorecard-api/` - Scorecard backend
- `~/projects/` - Various development projects
- `/opt/apps/test-deployment/` - FastAPI-React-Postgres template (production deployment)
- `~/.cloudflared/` - Cloudflare tunnel configuration
- `~/.n8n/` - n8n data and workflows

## Network Architecture

```
Internet
    ↓
Cloudflare Tunnel (cloudflared)
    ↓
Public Services:
    ├── n8n (localhost:5678) → n8n.iyeska.net
    ├── RECAP (localhost:8088) → recap.iyeska.net
    ├── Stoic (localhost:3333) → stoic.iyeska.net
    ├── Wowasi (localhost:8001) → wowasi.iyeska.net
    └── Ollama on Mac Mini (192.168.11.17:11434) → code.iyeska.net

Local Network Services (192.168.11.20):
    └── FastAPI-React-Postgres Template
        ├── Frontend (port 5174)
        ├── Backend API (port 8001)
        └── PostgreSQL (Docker internal)
```

## Deployment Notes

### For Public Services (Cloudflare Tunnel)

When deploying new public services:

1. Ensure service binds to `localhost` or specific port
2. Add ingress rule to `~/.cloudflared/config.yml`
3. Restart cloudflared: `sudo systemctl restart cloudflared`
4. Test locally first: `curl http://localhost:PORT/health`
5. Verify tunnel logs: `sudo journalctl -u cloudflared -f`

### For Docker-Based Services

Docker applications should be deployed to `/opt/apps/` for production deployments:

```bash
# Create deployment directory
sudo mkdir -p /opt/apps/app-name
sudo chown $USER:$USER /opt/apps/app-name

# Clone or copy application
cd /opt/apps/app-name

# Configure .env file
cp .env.example .env
nano .env

# Deploy with Docker Compose
docker compose -f docker-compose.production.yml up -d --build
```

**Port Management:**
- Check for port conflicts before deploying: `sudo lsof -i :PORT`
- Port 8001 is currently shared between wowasi_ya (PM2) and test-deployment (Docker)
- Stop conflicting services before starting new ones

## Python Virtual Environments

Multiple Python projects use virtual environments:
```bash
# CourtListener/RECAP
source ~/courtlistener/venv/bin/activate

# Other projects
source ~/projects/[project-name]/.venv/bin/activate
```

Always activate the appropriate venv before working with Python projects.

## NetBird VPN Troubleshooting

### Common Issues

**Issue 1: Management Container Restart Loop**
If `netbird-management-1` is restarting continuously:

```bash
# Check logs
docker logs --tail 50 netbird-management-1

# If you see network/OIDC errors, restart the stack:
cd ~/netbird
docker compose down
docker compose up -d
```

**Root cause:** Docker network attachment failure preventing Caddy from obtaining SSL certificates.

**Issue 2: Dashboard Redirect URI Error**
If you see `"error": "invalid_request"` when accessing `https://netbird.iyeska.net`:

```bash
# Check current redirect URIs
docker exec netbird-zdb-1 psql -U zitadel -d zitadel -c \
  "SELECT client_id, redirect_uris FROM projections.apps7_oidc_configs WHERE client_id = '345364864828506116';"

# Fix if incorrect (should be https://netbird.iyeska.net not relay.netbird.iyeska.net):
docker exec netbird-zdb-1 psql -U zitadel -d zitadel -c \
  "UPDATE projections.apps7_oidc_configs 
   SET redirect_uris = '{https://netbird.iyeska.net/nb-auth,https://netbird.iyeska.net/nb-silent-auth,https://netbird.iyeska.net/}', 
       post_logout_redirect_uris = '{https://netbird.iyeska.net/}'
   WHERE client_id = '345364864828506116';"
```

**Issue 3: Connecting Clients to Self-Hosted Instance**
The NetBird system tray app defaults to NetBird cloud. To connect to your self-hosted instance:

```bash
# On client machine (Mac/Linux):
sudo netbird down
sudo rm -rf /etc/netbird
sudo netbird up --management-url https://netbird.iyeska.net:443 --setup-key YOUR_SETUP_KEY
```

Get setup key from dashboard: `https://netbird.iyeska.net` → Setup Keys

### Quick Status Check

```bash
# All containers should be running
docker ps --filter 'name=netbird' --format 'table {{.Names}}\t{{.Status}}'

# Check SSL certificate
curl -I https://netbird.iyeska.net

# Check OIDC endpoint
curl -s https://netbird.iyeska.net/.well-known/openid-configuration | jq .
```

### Documentation
Full troubleshooting session: `~/netbird/TROUBLESHOOTING_2025-11-29.md`

