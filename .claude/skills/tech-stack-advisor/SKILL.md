---
name: tech-stack-advisor
description: Advise on technology choices for new full-stack projects using the user's preferred stack (FastAPI + React + PostgreSQL). Use when starting a new project, discussing architecture decisions, choosing frameworks, scaffolding an application, or when the user asks what stack to use.
allowed-tools: Read, Grep, Glob, mcp__memory__search_nodes, mcp__memory__open_nodes, mcp__github__get_file_contents
---

# Tech Stack Advisor

This user has a well-established preferred technology stack for full-stack applications. Always recommend this stack unless there's a specific reason not to.

## Authoritative Source

**GitHub Template**: https://github.com/guthdx/fastapi-react-postgres-template

This is the canonical, production-ready template. Clone from here when starting new projects.

## Preferred Stack Summary

| Layer | Technology |
|-------|------------|
| Backend | FastAPI 0.115+ + SQLAlchemy 2.0 (async) + Alembic |
| Frontend | React 18 + Vite 5 + Axios |
| Database | PostgreSQL 16 Alpine |
| Infrastructure | Docker Compose + Nginx (production) |

## When to Use This Skill

- User is starting a new full-stack project
- User asks "what stack should I use?"
- User is choosing between frameworks
- User wants to scaffold a new application
- User mentions building an API with a frontend
- User discusses architecture decisions

## Instructions

1. **Check memory first** for the "Preferred Tech Stack" entity
2. **Recommend the FastAPI + React + PostgreSQL stack**
3. **Reference the GitHub template** as the source to clone
4. **Offer to scaffold** by cloning the template
5. **Remind about key patterns**:
   - Python 3.13 via `/opt/local/bin/python3.13` (not system Python 3.10)
   - Async SQLAlchemy with `asyncpg` driver
   - Pydantic Settings for configuration
   - Three-tier Docker architecture with health checks

## Quick Start Command

```bash
git clone https://github.com/guthdx/fastapi-react-postgres-template.git PROJECT_NAME
cd PROJECT_NAME
cp .env.production.example .env
# Edit .env
docker compose -f docker-compose.production.yml up -d --build
```

## Key Architecture Decisions

1. **Async by default**: FastAPI + async SQLAlchemy
2. **Environment-based config**: Pydantic BaseSettings
3. **Health checks everywhere**: db, backend, frontend all have health endpoints
4. **Docker-first**: Production uses docker-compose.production.yml
5. **Nginx for frontend**: Multi-stage build, serves static React build

## Local Working Example

`~/terminal_projects/claude_code/cyoa-honky-tonk` demonstrates this stack in action.
