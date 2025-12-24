---
description: Display the user's preferred tech stack for full-stack applications
---

# Preferred Tech Stack Reference

When I invoke `/tech-stack`, recall and display my preferred technology stack from memory, then offer to help apply it.

## What to Do

1. Read the "Preferred Tech Stack" entity from memory
2. Display a formatted summary of the stack
3. If I'm starting a new project, offer to clone the template
4. Reference the GitHub template as the authoritative source

## Authoritative Source

**GitHub Template**: https://github.com/guthdx/fastapi-react-postgres-template

This is the canonical, production-ready template. Always clone from here when starting new projects.

## Quick Reference (Backup if Memory Unavailable)

### Core Stack
- **Backend**: FastAPI 0.115+ + SQLAlchemy 2.0 (async) + Alembic + PostgreSQL 16
- **Frontend**: React 18 + Vite 5 + Axios
- **Database**: PostgreSQL 16 Alpine
- **Infrastructure**: Docker Compose + Nginx (production)

### Three-Tier Docker Architecture
```
Database Layer (db)     → PostgreSQL 16 Alpine, health: pg_isready
Backend Layer (backend) → FastAPI + async SQLAlchemy, health: /api/v1/health
Frontend Layer (frontend) → React/Vite dev, Nginx prod, health: /health
```

### Backend Dependencies
```
fastapi>=0.115.0
uvicorn[standard]
sqlalchemy[asyncio]>=2.0
asyncpg
alembic
pydantic>=2.0
pydantic-settings
```

### Frontend Dependencies
```json
{
  "react": "^18",
  "react-dom": "^18",
  "axios": "^1",
  "vite": "^5"
}
```

### Project Structure
```
project/
├── backend/
│   ├── app/
│   │   ├── api/v1/          # API routes (health.py, etc.)
│   │   ├── core/            # config.py (Pydantic Settings)
│   │   ├── db/              # session.py (async sessionmaker)
│   │   ├── models/          # SQLAlchemy models
│   │   └── main.py          # FastAPI app
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/
│   ├── src/
│   │   ├── App.jsx
│   │   ├── main.jsx
│   │   └── *.css
│   ├── Dockerfile           # Multi-stage: node build + nginx serve
│   ├── nginx.conf
│   └── package.json
│
├── docker-compose.production.yml
├── .env.production.example
└── README.md
```

### Key Patterns
- **Config**: Pydantic `BaseSettings` in `app/core/config.py`
- **Database**: `postgresql+asyncpg://` DSN, `async_sessionmaker`
- **CORS**: Custom validator accepts comma-separated string OR list
- **Health checks**: All services have Docker health checks
- **Dependencies**: Backend waits for `db` service_healthy

### Quick Start (New Project)
```bash
git clone https://github.com/guthdx/fastapi-react-postgres-template.git my-project
cd my-project
cp .env.production.example .env
# Edit .env with your settings
docker compose -f docker-compose.production.yml up -d --build
```

### Environment Variables
| Variable | Description |
|----------|-------------|
| `COMPOSE_PROJECT_NAME` | Docker project name |
| `POSTGRES_PASSWORD` | Database password (required) |
| `BACKEND_PORT` | Backend port (default: 8000) |
| `FRONTEND_PORT` | Frontend port (default: 5173) |
| `VITE_API_BASE_URL` | Frontend's API base URL |
| `BACKEND_CORS_ORIGINS` | Allowed CORS origins |

### Working Example
Local: `~/terminal_projects/claude_code/cyoa-honky-tonk`
