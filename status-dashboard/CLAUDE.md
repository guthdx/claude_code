# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a serverless infrastructure monitoring dashboard for Iyeska network infrastructure, built entirely on Cloudflare's free tier. It monitors 20+ services across 4 locations (NativeBio, TDR, Missouri Breaks, Iyeska HQ) and sends alerts to Slack when services go down.

**Cost:** $0/month - 100% free

## Architecture

This project uses a three-component serverless architecture:

1. **Status Checker Worker** (`workers/status-checker.js`)
   - Runs on cron schedule every 10 minutes (`*/10 * * * *`)
   - Checks all services via HTTP HEAD requests
   - Stores results in D1 database
   - Detects online→offline transitions and triggers webhooks to n8n
   - Can be manually triggered via POST request for testing

2. **API Worker** (`workers/status-api.js`)
   - Serves status data at `status.iyeska.net/api/status`
   - Provides current status and 24-hour uptime percentages
   - Includes `/api/history/{service_id}` endpoint
   - Route configured via `wrangler-api.toml` to custom domain

3. **Frontend** (`public/`)
   - Static dashboard hosted on Cloudflare Pages
   - Fetches from API every 60 seconds
   - Dark theme with Tailwind CSS
   - Real-time status dots and metrics

All three share the same D1 database (`iyeska-status-db`).

## Database Schema

D1 SQLite database with two tables (`schema/init.sql`):

- **services**: Configuration (id, name, type, url, group_name)
- **status_checks**: Historical data (service_id, status, response_time, error_message, checked_at)

Database ID: `a59a40ac-47a9-41cf-9be4-d4e3f383360f`

## Deployment Commands

**Deploy Frontend:**
```bash
wrangler pages deploy public --project-name iyeska-status-dashboard
```

**Deploy Workers:**
```bash
# Status checker (cron worker)
wrangler deploy --config workers/wrangler-checker.toml

# API worker (custom domain route)
wrangler deploy --config workers/wrangler-api.toml
```

**Database Operations:**
```bash
# Run SQL queries
wrangler d1 execute iyeska-status-db --file schema/init.sql

# Insert services (example)
wrangler d1 execute iyeska-status-db --command "INSERT INTO services (id, name, type, url, group_name) VALUES ('iyeska-n8n', 'n8n Automation', 'http', 'https://n8n.iyeska.net', 'iyeska')"
```

**Secrets Management:**
```bash
# Set n8n webhook URL for alerts
wrangler secret put N8N_WEBHOOK_URL --config workers/wrangler-checker.toml
# Value: https://n8n.iyeska.net/webhook/status-alerts
```

## Alert Integration

The status checker sends webhooks to n8n when services transition from online→offline. The n8n workflow (ID: `AchbJtsIXtv4ew2V`) formats alerts and sends to Slack.

**Webhook payload format:**
```json
{
  "service": "Main Server",
  "serviceId": "iyeska-main",
  "status": "offline",
  "timestamp": "2025-11-25T16:50:00Z",
  "message": "Main Server is now offline"
}
```

**n8n API access:**
- URL: `https://n8n.iyeska.net/api/v1/`
- API key may expire; regenerate at `/settings/api` if needed

## Service Status Logic

The checker considers these HTTP status codes as "online":
- 200-399: Normal responses
- 401/403: Server responding but requires auth (expected for secured services)

Anything else (500s, timeouts >10s, connection failures) = offline.

SSH and ping checks are not yet implemented (Workers limitation).

## Branding & Design

The dashboard uses organization-specific branding with logos for each infrastructure location:

**Brand Colors (Iyeska):**
- Terracotta: `#CD6F4D` (offline status, hover effects)
- Slate Blue: `#56738C` (borders, accents)
- Charcoal: `#333333`
- Off-white: `#888888`

**Logo Assets** (`public/images/`):
- `iyeska-logo.png` - Main header and Iyeska HQ section
- `nativebio-logo.png` - NativeBio section (DNA helix with feather)
- `tdr-logo.png` - TDR section (Tribal Data Repository with DNA strand)
- `mbiri-logo.png` - Missouri Breaks section (MBIRI star with landscape)
- `favicon.png` - Browser tab icon

**Frontend Architecture:**
- `index.html` - Main dashboard with Tailwind CSS
- `app.js` - Fetches from `/api/status` every 60 seconds
- Status dots: green (online), terracotta (offline), amber (degraded), pulsing gray (checking)

## Development Workflow

**Testing Changes Locally:**
1. Edit files in `public/` or `workers/`
2. Deploy to Cloudflare to test (no local dev server for Workers)
3. Check live dashboard at `https://status.iyeska.net`

**Adding New Services:**
1. Insert into D1 database via wrangler
2. Add service card HTML to `public/index.html`
3. Redeploy frontend: `wrangler pages deploy public --project-name iyeska-status-dashboard`

**Modifying Status Check Logic:**
1. Edit `workers/status-checker.js`
2. Deploy: `wrangler deploy --config workers/wrangler-checker.toml`
3. Test by checking Slack alerts or dashboard updates

**Updating Branding:**
- Logo files stored in `public/images/`
- CSS variables defined in `index.html` `<style>` section
- Always redeploy frontend after design changes

## Important Notes

- Frontend refreshes every 60 seconds (configured in `app.js`)
- Checks run every 10 minutes (cron: `*/10 * * * *` in `wrangler-checker.toml`)
- Uptime percentages calculated over last 24 hours
- Custom domain `status.iyeska.net` configured in Cloudflare Pages dashboard
- API route `status.iyeska.net/api/*` configured in `wrangler-api.toml`
- All timestamps in database are Unix epoch (seconds)
- The n8n workflow (ID: `AchbJtsIXtv4ew2V`) includes CST timezone formatting for alerts
- Both workers share the same D1 database binding (`DB`)
