# Command Cheat Sheet

Quick reference for commonly used commands across the Iyeska development environment.

---

## Claude Code Instances

```bash
# Lightweight dev instance (~35K tokens) - daily coding
claude-dev

# Infrastructure instance (~60K tokens) - Cloudflare, Docker, n8n
claude-infra

# Full instance (~95K tokens) - everything
claude

# Diagnostics
/doctor

# Resume previous session
claude --continue
claude --resume

# MCP server management
claude mcp list
claude mcp disable cloudflare
claude mcp enable cloudflare
```

---

## Git

```bash
# Clone (always use SSH, never HTTPS with token)
git clone git@github.com:guthdx/REPO_NAME.git

# Fix exposed token in remote URL
git remote set-url origin git@github.com:guthdx/REPO_NAME.git

# Standard workflow
git status
git add .
git commit -m "Message"
git push

# Stash and pull
git stash
git pull
git stash pop
```

---

## Python Projects

```bash
# ALWAYS use Python 3.13 (system 3.10 is incompatible)
/opt/local/bin/python3.13 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Run tests
pytest
pytest tests/test_specific.py
pytest --cov=src/module --cov-report=term-missing

# Lint and format
ruff check src/ tests/
ruff format src/ tests/
mypy src/

# Deactivate venv
deactivate
```

---

## Cloudflare (Wrangler)

```bash
# Deploy Pages site
wrangler pages deploy public --project-name PROJECT_NAME
wrangler pages deploy public --project-name PROJECT_NAME --commit-dirty

# Deploy Worker
wrangler deploy
wrangler deploy --config wrangler.toml
wrangler deploy --config workers/wrangler-checker.toml

# D1 Database
wrangler d1 list
wrangler d1 execute DB_NAME --file schema.sql
wrangler d1 execute DB_NAME --command "SELECT * FROM table"

# KV Store
wrangler kv namespace list
wrangler kv key list --namespace-id NAMESPACE_ID
wrangler kv key get KEY --namespace-id NAMESPACE_ID
wrangler kv key get "user@example.com" --namespace-id 36551939f95f437b8ba66dc221227abb

# Secrets
wrangler secret put SECRET_NAME --config wrangler.toml

# Check login
wrangler whoami

# Local dev
wrangler dev
```

---

## Docker

```bash
# Start services
docker compose up -d
docker compose -f docker-compose.production.yml up -d

# View logs
docker compose logs -f
docker compose logs -f SERVICE_NAME
docker logs -f CONTAINER_NAME

# Restart service
docker compose restart SERVICE_NAME
docker restart CONTAINER_NAME

# Check status
docker compose ps
docker ps
docker ps -a | grep NAME

# Stop all
docker compose down

# Stats and cleanup
docker stats CONTAINER_NAME
docker system df
docker system prune -a
```

---

## SSH & Remote Servers

```bash
# Ubuntu server (Iyeska HQ)
ssh -p 2022 guthdx@68.168.225.52

# n8n management (on Ubuntu server)
pm2 list
pm2 logs n8n --lines 50
pm2 stop n8n
pm2 start n8n
pm2 restart n8n --update-env
pm2 save
pm2 monit

# n8n upgrade
npm update -g n8n
pm2 restart n8n

# Cloudflare Tunnel (on Ubuntu server)
sudo systemctl status cloudflared
sudo systemctl restart cloudflared
sudo journalctl -u cloudflared -f
nano ~/.cloudflared/config.yml
```

---

## NetBird VPN (on Ubuntu server)

```bash
cd ~/netbird
docker compose ps
docker compose logs -f
docker compose restart

# Individual containers
docker logs netbird-management-1 -f
docker logs netbird-caddy-1 -f
docker logs netbird-zitadel-1 -f

# SSL certificate check
echo | openssl s_client -connect netbird.iyeska.net:443 2>/dev/null | openssl x509 -noout -dates

# Container health
docker ps --filter "name=netbird" --format "table {{.Names}}\t{{.Status}}"

# Port 443 check
ss -tlnp | grep :443

# Backup
tar czf ~/netbird-backup-$(date +%Y%m%d).tar.gz ~/netbird/
```

---

## Remote AI (code.iyeska.net)

```bash
# Test Ollama connection
curl https://code.iyeska.net/api/tags

# VS Code Continue setup
./code_iyeska_net/setup-continue.sh

# Continue shortcuts in VS Code
Cmd+L    # Chat
Cmd+I    # Inline edit
```

---

## Environment Variables

```bash
# Edit shell config
nano ~/.zshrc

# Reload after changes
source ~/.zshrc

# Required variables
export GITHUB_TOKEN="..."
export CLOUDFLARE_API_TOKEN="..."
export CLOUDFLARE_ACCOUNT_ID="..."
export N8N_API_KEY="..."
export ANTHROPIC_API_KEY="..."
```

---

## Project-Specific Commands

### Status Dashboard (status.iyeska.net)

```bash
cd ~/terminal_projects/claude_code/status-dashboard

# Deploy frontend
wrangler pages deploy public --project-name iyeska-status-dashboard

# Deploy workers
wrangler deploy --config workers/wrangler-checker.toml
wrangler deploy --config workers/wrangler-api.toml

# Set webhook secret
wrangler secret put N8N_WEBHOOK_URL --config workers/wrangler-checker.toml
```

### Wowasi Ya (wowasi.iyeska.net)

```bash
cd ~/terminal_projects/claude_code/wowasi_ya

# CLI commands
wowasi generate "Project Name" "Description..."
wowasi discover "Project Name" "Description"
wowasi privacy-check "Text to scan..."
wowasi audit --limit 20

# Server
wowasi serve --reload                                    # Dev (port 8000)
uvicorn wowasi_ya.main:app --host 0.0.0.0 --port 8002   # Prod

# On Ubuntu server
pm2 restart wowasi_ya
pm2 logs wowasi_ya
bash deploy.sh
```

### Aurelius Echo (stoic.iyeska.net)

```bash
cd ~/terminal_projects/claude_code/aurelius_echo

# Local dev
npm install
npm run dev

# Deploy (on Ubuntu server)
bash deploy.sh
pm2 logs aurelius
pm2 restart aurelius
```

### DNA Spectrum (dna.iyeska.net)

```bash
cd ~/terminal_projects/claude_code/dna_spectrum

# Local dev (port 3001)
npm run dev
npm run type-check
npm run build

# On Ubuntu server
./scripts/deploy-nextjs.sh
pm2 logs dna-spectrum
pm2 restart dna-spectrum

# Database
psql postgresql://postgres:dna_spectrum_2024@192.168.11.20:5432/dna_spectrum
docker exec dna-spectrum-db psql -U postgres -d dna_spectrum -c "\dt"
```

### Iyeska Website (iyeska.net)

```bash
cd ~/terminal_projects/claude_code/iyeska_website

# Deploy frontend
wrangler pages deploy . --project-name iyeska-website --branch main

# Deploy workers
cd worker && wrangler deploy
cd sync-worker && wrangler deploy

# Test form submission
curl -X POST https://iyeska-email-signup.guthdx.workers.dev \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","formType":"contact"}'

# Trigger Google Sheets sync
curl -X POST https://iyeska-email-sync.guthdx.workers.dev
```

### Domain Strategy

```bash
cd ~/terminal_projects/claude_code/domain_strategy

# Deploy single site
wrangler pages deploy sites/DOMAIN --project-name PROJECT_NAME --commit-dirty

# Deploy all sites
bash deploy/deploy-all.sh

# Check domain status
curl -s https://DOMAIN | head -20
```

### Claude Code Router

```bash
# Server management
ccr start
ccr stop
ccr restart
ccr status
ccr logs

# Model management
ccr model
ccr code
ccr ui

# Environment setup
eval "$(ccr activate)"

# Test connection
curl -s http://127.0.0.1:3456/health
```

### Video Server (media.nativebio.net)

```bash
# Container management
docker ps -a | grep nextcloud
docker logs -f priceless_goodall
docker restart priceless_goodall
docker stats priceless_goodall

# User management
docker exec priceless_goodall php occ user:list
docker exec -e OC_PASS="pw" priceless_goodall php occ user:add --password-from-env username
docker exec -e OC_PASS="pw" priceless_goodall php occ user:resetpassword --password-from-env username

# Cloudflare tunnel
sudo systemctl status cloudflared
sudo systemctl restart cloudflared
sudo journalctl -u cloudflared -f

# Backup
docker exec priceless_goodall tar czf /tmp/backup.tar.gz /var/www/html
docker cp priceless_goodall:/tmp/backup.tar.gz ~/backups/
```

### Reclaiming the Story

```bash
cd ~/terminal_projects/claude_code/reclaiming_the_story

# Local preview
python3 -m http.server 8000

# Deploy to GitHub Pages
git add .
git commit -m "Update"
git push origin main

# Live URLs
# Main: https://guthdx.github.io/reclaiming_the_story/
# Map:  https://guthdx.github.io/reclaiming_the_story/experiences/map.html
```

### 5th C Finance (5thc.finance)

```bash
cd ~/terminal_projects/claude_code/5thc_finance

# Local testing
python3 -m http.server 8000 --directory public

# Deploy
wrangler pages deploy public --project-name 5thc-finance
```

---

## FastAPI + React Stack (Preferred)

```bash
# Backend setup
cd backend
/opt/local/bin/python3.13 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Database migrations
alembic revision --autogenerate -m "Description"
alembic upgrade head

# Run backend
uvicorn app.main:app --reload --port 8000

# Frontend setup
cd frontend
npm install
npm run dev

# Full stack with Docker
docker compose up -d
docker compose -f docker-compose.production.yml up -d
docker compose logs -f

# Health checks
curl http://localhost:8000/api/v1/health
curl http://localhost:5174/health
```

---

## Connectivity Tests

```bash
# Remote Ollama
curl https://code.iyeska.net/api/tags

# Status dashboard
curl https://status.iyeska.net/api/status

# n8n
curl https://n8n.iyeska.net/healthz

# Wowasi
curl https://wowasi.iyeska.net/api/v1/health

# NetBird
curl -I https://netbird.iyeska.net
curl -s https://netbird.iyeska.net/.well-known/openid-configuration | jq .

# NetBird ports
nc -zv 68.168.225.52 443
nc -zv 68.168.225.52 10000

# DNA Spectrum
curl http://localhost:3001
```

---

## Context7 (Library Docs)

Add `use context7` to any prompt to get up-to-date library documentation:

```
use context7 - How do I set up React Router v7?
use context7 - FastAPI dependency injection examples
```

---

## Memory MCP

```bash
# Search memory
# (use mcp__memory__search_nodes in Claude)

# Key entities to query:
# - MacBook Pro M4 Max
# - Ubuntu NetBird Server
# - Preferred Tech Stack
# - DomainPortfolioStatus
# - Reclaiming the Story
```

---

## Quick Local Servers

```bash
# Python (any directory)
python3 -m http.server 8000

# Node.js
npx http-server . -p 8000

# PHP
php -S localhost:8000
```

---

*Last updated: December 2025*
*Source: 16 CLAUDE.md files across all projects*
