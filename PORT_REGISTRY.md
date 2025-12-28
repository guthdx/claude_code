# Port Registry

**Last Updated**: 2025-12-28
**Purpose**: Centralized port allocation to prevent conflicts across all Iyeska projects

---

## Traefik Development Proxy (Recommended)

Instead of remembering port numbers, use Traefik for `*.localhost` routing:

```bash
# Start Traefik (once, leave running)
cd ~/terminal_projects/claude_code/traefik && docker compose up -d
```

| Project | Frontend URL | Backend URL |
|---------|-------------|-------------|
| csep_barter_bank | http://csep.localhost | http://csep-api.localhost |
| cyoa-honky-tonk | http://cyoa.localhost | http://cyoa-api.localhost |
| dx_clan | http://dxclan.localhost | http://dxclan-api.localhost |
| dna_spectrum | http://dna.localhost | - |
| aurelius_echo | http://stoic.localhost | - |
| wowasi_ya | http://wowasi.localhost | - |

**Dashboard**: http://localhost:8080 or http://traefik.localhost

See `traefik/README.md` for setup instructions per project.

---

## Quick Reference - Reserved Port Ranges

| Range | Purpose | Notes |
|-------|---------|-------|
| 3000-3099 | Frontend Dev Servers (Next.js, etc.) | 3000 reserved for open-webui |
| 5173-5179 | Vite Dev Servers | Standard Vite default range |
| 5432-5439 | PostgreSQL Databases | 5432 default, 5433+ for parallel projects |
| 8000-8099 | Backend APIs (FastAPI, Express) | Production & dev |
| 8080-8089 | Web Services (Nextcloud, proxies) | |
| 11434 | Ollama AI Server | Local LLM inference |
| 27124 | Obsidian Local REST API | |

---

## Currently Allocated Ports

### Databases (PostgreSQL)

| Port | Project | Environment | Status |
|------|---------|-------------|--------|
| 5432 | cyoa-honky-tonk | Development | Active |
| 5432 | csep_barter_bank | Development | **CONFLICT - use 5434** |
| 5432 | dx_clan | Development | **CONFLICT - use 5435** |
| 5432 | dna_spectrum | Development | **CONFLICT - use 5436** |
| 5433 | csep_barter_bank | Running Docker | Active (mapped 5433->5432) |

**Recommended Allocation**:
- 5432: cyoa-honky-tonk (primary project)
- 5433: csep_barter_bank
- 5434: dx_clan
- 5435: dna_spectrum
- 5436-5439: Future projects

### Backend APIs

| Port | Project | Service | Environment | Status |
|------|---------|---------|-------------|--------|
| 8000 | cyoa-honky-tonk | FastAPI | Development | Available |
| 8000 | csep_barter_bank | FastAPI | Development | **CONFLICT** |
| 8000 | dx_clan | FastAPI | Development | **CONFLICT** |
| 8001 | wowasi_ya | FastAPI | Production | Allocated |
| 8001 | csep_barter_bank | FastAPI | Running Docker | Active (mapped 8001->8000) |
| 8002 | wowasi_ya | FastAPI | Alt/Dev | Available |

**Recommended Allocation**:
- 8000: cyoa-honky-tonk
- 8001: wowasi_ya (production)
- 8002: csep_barter_bank
- 8003: dx_clan
- 8004-8009: Future projects

### Frontend Dev Servers

| Port | Project | Framework | Environment | Status |
|------|---------|-----------|-------------|--------|
| 3000 | open-webui | Docker | Running | Active |
| 3001 | dna_spectrum | Next.js | Development | Allocated |
| 3333 | aurelius_echo | Express | Production | Active |
| 5173 | cyoa-honky-tonk | Vite | Development | Available |
| 5173 | csep_barter_bank | Vite | Development | **CONFLICT** |
| 5173 | dx_clan | Vite | Development | **CONFLICT** |
| 5174 | (free) | Vite | - | Currently in use by node |

**Recommended Allocation**:
- 3000: open-webui (Docker)
- 3001: dna_spectrum (Next.js)
- 3333: aurelius_echo (Express/PM2)
- 5173: cyoa-honky-tonk
- 5174: csep_barter_bank
- 5175: dx_clan
- 5176-5179: Future projects

### Infrastructure Services

| Port | Service | Purpose | Status |
|------|---------|---------|--------|
| 80 | NetBird Caddy | HTTP | Production |
| 443 | NetBird Caddy | HTTPS | Production |
| 3478/UDP | NetBird STUN | VPN | Production |
| 5050 | dna_spectrum PgAdmin | DB Admin | Optional |
| 8080 | video_server Nextcloud | Media | Available |
| 10000 | NetBird Signal | gRPC | Production |
| 11434 | Ollama | Local LLM | Active |
| 27124 | Obsidian REST API | Notes | Active |
| 33073/UDP | NetBird WebRTC | VPN | Production |
| 49152-65535/UDP | NetBird TURN | VPN Relay | Production |

### Production Server (68.168.225.52:2022)

**PM2 Managed Services**

| Port | Service | Process | URL | Status |
|------|---------|---------|-----|--------|
| 3333 | aurelius_echo | node | thestoicindian.com | Active |
| 4000 | dna-spectrum | node | dna.iyeska.net | Active |
| 5678 | n8n | node | n8n.iyeska.net | Active |
| 5679 | n8n (internal) | node | localhost only | Active |
| 8002 | wowasi_ya | python | wowasi.iyeska.net | Active |
| 20241 | cloudflared | tunnel | Cloudflare Tunnel | Active |

**Docker Containers**

| External Port | Container | Internal Port | Purpose |
|---------------|-----------|---------------|---------|
| 80 | netbird-caddy | 80 | HTTP |
| 443 | netbird-caddy | 443 | HTTPS/QUIC |
| 3100 | mcp-proxy-obsidian | 3100 | MCP Obsidian Proxy |
| 5174 | test-deployment-frontend | 80 | Test CSEP Frontend |
| 5432 | dna-spectrum-db | 5432 | DNA Spectrum DB |
| 5433 | mcp-memory-db | 5432 | MCP Memory PostgreSQL |
| 8001 | test-deployment-backend | 8000 | Test CSEP Backend |
| 18000 (localhost) | honkytonk-backend | 8000 | Honky Tonk API |
| 18080 (localhost) | honkytonk-frontend | 80 | Honky Tonk UI |
| 19000 (localhost) | dxclan-backend | 8000 | DX Clan API |
| 19080 (localhost) | dxclan-frontend | 80 | DX Clan UI |

**Internal-Only Docker (no external port)**

| Container | Internal Port | Purpose |
|-----------|---------------|---------|
| dxclan-db | 5432 | DX Clan PostgreSQL |
| honkytonk-db | 5432 | Honky Tonk PostgreSQL |
| test-deployment-db | 5432 | Test CSEP PostgreSQL |
| netbird-zdb | 5432 | NetBird Zitadel DB |
| netbird-signal | - | WireGuard signaling |
| netbird-relay | - | Traffic relay |
| netbird-management | - | VPN management |
| netbird-dashboard | 80 | Admin UI (via Caddy) |
| netbird-zitadel | - | Identity provider |
| netbird-coturn | UDP range | TURN server |

### Other Remote Services

| Port | Service | Location | Status |
|------|---------|----------|--------|
| 8088 | REDCap | NativeBio | Active |

---

## System Services (macOS - Local Dev Machine)

| Port | Process | Purpose |
|------|---------|---------|
| 1234 | LM Studio | Local LLM UI |
| 5000 | ControlCenter | AirPlay Receiver |
| 6463 | Discord | Rich Presence |
| 7000 | ControlCenter | AirPlay (alt) |
| 7679 | Google Chrome | DevTools |
| 41343 | LM Studio | API |
| 42050 | OneDrive | Sync |
| 49386 | VS Code | Remote Dev |
| 49576 | Comodo | Security |
| 49997 | Ollama | Alt endpoint |
| 63677 | rapportd | Device discovery |
| 65433 | Comodo | Security |

---

## Project-Specific Configurations

### cyoa-honky-tonk (Show Management)
```yaml
# docker-compose.yml
postgres: 5432:5432
backend: 8000:8000
# Production
backend: 127.0.0.1:18000:8000
frontend: 127.0.0.1:18080:80
```

### csep_barter_bank (Skill Exchange)
```yaml
# docker-compose.yml (CHANGE TO AVOID CONFLICTS)
postgres: ${POSTGRES_PORT:-5433}:5432  # Was 5432
backend: ${BACKEND_PORT:-8002}:8000    # Was 8000
frontend: ${FRONTEND_PORT:-5174}:5173  # Was 5173
```

### dx_clan (Genealogy)
```yaml
# docker-compose.yml (CHANGE TO AVOID CONFLICTS)
postgres: 5434:5432  # Was 5432
backend: 8003:8000   # Was 8000
frontend: 5175:5173  # Was 5173
```

### dna_spectrum (Personality Assessment)
```yaml
postgres: 5435:5432  # Was 5432
pgadmin: 5050:80
nextjs: 3001 (configured in package.json)
```

### wowasi_ya (Documentation Generator)
```yaml
backend: 8001:8001  # Unique, no conflicts
```

### aurelius_echo (Stoic Indian)
```yaml
express: 3333  # Unique, no conflicts
```

---

## Conflict Resolution Actions Required

### Immediate Fixes

1. **csep_barter_bank** - Update docker-compose.yml:
   - Postgres: 5432 -> 5433
   - Backend: 8000 -> 8002
   - Frontend: 5173 -> 5174

2. **dx_clan** - Update docker-compose.yml:
   - Postgres: 5432 -> 5434
   - Backend: 8000 -> 8003
   - Frontend: 5173 -> 5175

3. **dna_spectrum** - Update docker-compose.yml:
   - Postgres: 5432 -> 5435

---

## Port Allocation Protocol (New Projects)

When creating a new project:

1. **Check this registry** for available ports in each category
2. **Allocate from next available** in the reserved range
3. **Update this file** with the new allocation
4. **Use environment variables** for port configuration when possible:
   ```yaml
   ports:
     - "${POSTGRES_PORT:-5436}:5432"
     - "${BACKEND_PORT:-8004}:8000"
     - "${FRONTEND_PORT:-5176}:5173"
   ```
5. **Add .env.example** with default ports documented

### Next Available Ports

| Category | Next Available |
|----------|----------------|
| PostgreSQL | 5436 |
| Backend API | 8004 |
| Vite Frontend | 5176 |
| Next.js Frontend | 3002 |
| Express/Node | 3334 |

---

## Maintenance

- Update this file whenever ports are added or changed
- Run `lsof -iTCP -sTCP:LISTEN -P | grep LISTEN` to see active ports
- Run `docker ps --format "{{.Names}}\t{{.Ports}}"` for Docker mappings
- Commit changes to git to sync across machines
