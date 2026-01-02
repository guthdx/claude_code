# ARCHIVED PROJECT

**Status**: Inactive as of 2026-01-01

## What This Was

Serverless infrastructure monitoring dashboard on Cloudflare (100% free tier). Monitored 20+ services across 4 locations with automated alerts to Slack via n8n.

## Why Archived

Project no longer in active use/development.

## What Was Disabled

- **Cron trigger disabled**: `iyeska-status-checker` worker no longer runs scheduled health checks
- **Pages still accessible**: https://status.iyeska.net (static, no longer updating)

## What Remains on Cloudflare

- Cloudflare Pages: `iyeska-status-dashboard`
- Cloudflare Worker: `iyeska-status-checker` (disabled cron)
- Cloudflare D1: Status history database
- DNS: `status.iyeska.net`

## To Fully Decommission

1. Delete Cloudflare Pages project: `wrangler pages project delete iyeska-status-dashboard`
2. Delete Cloudflare Worker: `wrangler delete iyeska-status-checker`
3. Delete D1 database (if exists)
4. Remove DNS record for `status.iyeska.net`
5. Delete this directory

---
*Archived by Claude Code*
