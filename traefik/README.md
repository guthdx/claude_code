# Traefik Development Proxy

Local reverse proxy for routing `*.localhost` domains to Docker containers.

## Quick Start

```bash
# Start Traefik (run once, leave running)
cd ~/terminal_projects/claude_code/traefik
docker compose up -d

# Verify it's running
docker ps | grep traefik
curl -s http://localhost:8080/api/overview | jq .

# View dashboard
open http://localhost:8080
```

## How It Works

Instead of remembering port numbers:
```
http://localhost:8000  →  http://cyoa-api.localhost
http://localhost:5173  →  http://cyoa.localhost
```

Traefik watches Docker for containers with specific labels and routes traffic automatically.

## Adding a Project

### 1. Add network and labels to your `docker-compose.yml`:

```yaml
services:
  frontend:
    # ... existing config ...
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myproject.rule=Host(`myproject.localhost`)"
      - "traefik.http.services.myproject.loadbalancer.server.port=80"
    networks:
      - traefik-dev
      - default

  backend:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myproject-api.rule=Host(`myproject-api.localhost`)"
      - "traefik.http.services.myproject-api.loadbalancer.server.port=8000"
    networks:
      - traefik-dev
      - default

  db:
    # NO labels - database stays internal only
    networks:
      - default

networks:
  traefik-dev:
    external: true
```

### 2. Restart your project:

```bash
docker compose down && docker compose up -d
```

### 3. Access via browser:

- Frontend: `http://myproject.localhost`
- Backend: `http://myproject-api.localhost`

## Project URL Reference

| Project | Frontend | Backend/API |
|---------|----------|-------------|
| cyoa-honky-tonk | http://cyoa.localhost | http://cyoa-api.localhost |
| csep_barter_bank | http://csep.localhost | http://csep-api.localhost |
| dx_clan | http://dxclan.localhost | http://dxclan-api.localhost |
| dna_spectrum | http://dna.localhost | - |
| aurelius_echo | http://stoic.localhost | - |
| wowasi_ya | http://wowasi.localhost | - |

## Dashboard

Access Traefik dashboard at:
- http://localhost:8080
- http://traefik.localhost

Shows all registered routers, services, and health status.

## Troubleshooting

### "localhost refused to connect"

```bash
# Check Traefik is running
docker ps | grep traefik

# Check logs
docker logs traefik-dev

# Restart Traefik
docker compose restart
```

### Container not showing in dashboard

1. Ensure `traefik.enable=true` label is set
2. Ensure container is on `traefik-dev` network
3. Check container is running: `docker compose ps`

### Port 80 already in use

```bash
# Find what's using port 80
lsof -i :80

# If it's another service, either stop it or change Traefik's port:
# Edit docker-compose.yml: "8081:80" instead of "80:80"
# Then access via http://cyoa.localhost:8081
```

## Stopping Traefik

```bash
# Stop (keeps data)
docker compose stop

# Remove completely
docker compose down
```

## Relationship to Production

This is **development only**. Production uses:
- Cloudflare Tunnel for secure ingress
- Caddy/nginx for SSL termination
- Same routing concept, different implementation

Traefik teaches the same patterns used in production without touching your security setup.
