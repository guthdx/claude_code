# CLAUDE.md - CSEP Development Guide

## Project Overview

**CSEP (Community Skill Exchange Protocol)** is a skill-hour exchange platform where community members:
- **Earn** skill-hours by providing services to others
- **Spend** skill-hours to receive services from others
- No money changes hands - it's a time-based community economy

## Quick Start

```bash
# 1. Start Traefik (if not already running)
cd ~/terminal_projects/claude_code/traefik && docker compose up -d

# 2. Copy environment file
cd ~/terminal_projects/claude_code/csep_barter_bank
cp .env.example .env

# 3. Start development environment
docker compose up -d

# 4. Run database migrations
docker compose exec backend alembic upgrade head

# 5. Access the application via Traefik (recommended)
# Frontend: http://csep.localhost
# Backend API: http://csep-api.localhost/api/v1/docs
# Traefik Dashboard: http://traefik.localhost

# Alternative direct port access (fallback)
# Frontend: http://localhost:5174
# Backend API: http://localhost:8002/api/v1/docs
```

## Traefik Development Proxy

This project uses Traefik for local development routing. Benefits:
- No port conflicts with other projects
- Clean URLs (`csep.localhost` instead of `localhost:5174`)
- Same pattern as production (domain-based routing)

**Prerequisites**: Traefik must be running before starting this project.

```bash
# Start Traefik (once, leave running)
cd ~/terminal_projects/claude_code/traefik && docker compose up -d

# Verify Traefik is running
curl -s http://localhost:8080/api/overview | jq .
```

**Port Allocation** (per PORT_REGISTRY.md):
- PostgreSQL: 5433
- Backend: 8002
- Frontend: 5174

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | FastAPI 0.115+ (Python) |
| Database | PostgreSQL 16 |
| ORM | SQLAlchemy 2.0 (async) |
| Migrations | Alembic |
| Frontend | React 18 + Vite 5 |
| Auth | Auth0 (OIDC) |
| Infrastructure | Docker Compose |

## Project Structure

```
csep_barter_bank/
├── backend/
│   ├── app/
│   │   ├── api/v1/          # API routes
│   │   │   ├── auth.py      # OIDC authentication
│   │   │   ├── users.py     # User management
│   │   │   ├── listings.py  # Service listings
│   │   │   ├── contracts.py # Service contracts
│   │   │   ├── ratings.py   # Rating system
│   │   │   ├── disputes.py  # Dispute resolution
│   │   │   ├── donations.py # Donate to causes
│   │   │   ├── admin.py     # Admin dashboard
│   │   │   └── health.py    # Health check
│   │   ├── core/
│   │   │   ├── config.py    # Settings (Pydantic)
│   │   │   ├── security.py  # JWT/Auth utilities
│   │   │   └── oidc.py      # Auth0 integration
│   │   ├── db/
│   │   │   └── session.py   # Database session
│   │   ├── models/          # SQLAlchemy models
│   │   │   ├── user.py
│   │   │   ├── listing.py
│   │   │   ├── contract.py
│   │   │   ├── transaction.py
│   │   │   ├── rating.py
│   │   │   ├── dispute.py
│   │   │   ├── audit.py
│   │   │   └── cause.py
│   │   ├── schemas/         # Pydantic schemas
│   │   ├── services/        # Business logic
│   │   └── main.py
│   ├── alembic/             # Database migrations
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/
│   ├── src/
│   ├── Dockerfile
│   └── package.json
│
├── docs/                    # Planning documents
├── docker-compose.yml       # Development
├── docker-compose.production.yml
├── .env.example
└── CLAUDE.md
```

## Database Models

### Core Entities
- **User**: Community members with skill-hour balances
- **ServiceListing**: Skills/services offered by users
- **ServiceContract**: Service exchange agreements
- **SkillHourTransaction**: Immutable ledger of balance changes
- **Rating**: Bidirectional ratings for completed contracts
- **Dispute**: Dispute resolution workflow
- **AuditLog**: Append-only audit trail

### Key Constraints
- `users.balance_hours >= 0` (no negative balances)
- `ratings.score` between 1-5
- Transactions are immutable (no updates/deletes)

## Contract Workflow

```
REQUESTED → NEGOTIATING → AGREED → IN_PROGRESS → COMPLETED
                                        ↓
                                    DISPUTED
                                        ↓
                                    RESOLVED
```

## Development Commands

```bash
# Ensure Traefik is running first
cd ~/terminal_projects/claude_code/traefik && docker compose up -d

# Start development environment
cd ~/terminal_projects/claude_code/csep_barter_bank
docker compose up -d

# View logs
docker compose logs -f backend

# Run migrations
docker compose exec backend alembic upgrade head

# Create new migration
docker compose exec backend alembic revision --autogenerate -m "description"

# Access database
docker compose exec db psql -U postgres -d csep_db

# Run tests
docker compose exec backend pytest

# Rebuild containers
docker compose up -d --build

# Check Traefik routing
curl -s http://localhost:8080/api/http/routers | jq -r '.[].name'
```

**Access URLs:**
- Frontend: http://csep.localhost
- Backend API Docs: http://csep-api.localhost/api/v1/docs
- Traefik Dashboard: http://traefik.localhost

## Auth0 Setup

1. Create Auth0 account at https://auth0.com
2. Create a new Application (Regular Web Application)
3. Configure Allowed Callback URLs: `http://localhost:8000/api/v1/auth/callback`
4. Configure Allowed Logout URLs: `http://localhost:5173`
5. Create API in Auth0 Dashboard with identifier: `https://api.csep.local`
6. Copy credentials to `.env`:
   - `AUTH0_DOMAIN`
   - `AUTH0_CLIENT_ID`
   - `AUTH0_CLIENT_SECRET`
   - `AUTH0_AUDIENCE`

## Key Design Decisions

### 1. No Local Passwords
All authentication via OIDC (Auth0). We only store `external_id` from the provider.

### 2. Signup Bonus
New users receive 3 skill-hours upon account creation to bootstrap the economy.

### 3. Immutable Transactions
The `skill_hour_transactions` table is append-only. All balance changes create a new transaction record.

### 4. Full Audit Trail
The `audit_log` table captures all significant actions for compliance and dispute resolution.

### 5. Time-Banking Model
Default exchange rate is 1:1 - one hour of service equals one skill-hour, regardless of service type.

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `POSTGRES_PASSWORD` | Database password | Yes |
| `SECRET_KEY` | JWT signing key | Yes |
| `AUTH0_DOMAIN` | Auth0 tenant domain | Yes |
| `AUTH0_CLIENT_ID` | Auth0 application ID | Yes |
| `AUTH0_CLIENT_SECRET` | Auth0 application secret | Yes |
| `AUTH0_AUDIENCE` | Auth0 API identifier | Yes |
| `SIGNUP_BONUS_HOURS` | Hours given to new users | No (default: 3.0) |

## Production Deployment

```bash
# 1. Copy and configure production environment
cp .env.production.example .env
# Edit .env with production values

# 2. Build and start
docker compose -f docker-compose.production.yml up -d --build

# 3. Run migrations
docker compose -f docker-compose.production.yml exec backend alembic upgrade head
```

## Planning Documents

Full project documentation is in the `docs/` directory:
- `00-Overview/` - Project brief and glossary
- `20-Planning/` - Goals, scope, timeline, budget, risks
- `30-Execution/` - Workflows, backlog, SOPs

## Data Sovereignty

This platform is designed for tribal/community contexts with strong data sovereignty requirements:
- Self-hosted on iyeska.net infrastructure
- No external data sharing
- Full audit logging for compliance
- OIDC for authentication without storing passwords
