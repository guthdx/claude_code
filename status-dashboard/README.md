# Iyeska Infrastructure Status Dashboard

A serverless monitoring dashboard for all Iyeska infrastructure, hosted on Cloudflare.

## Architecture

- **Frontend:** Cloudflare Pages (static HTML/CSS/JS)
- **Status Checks:** Cloudflare Workers (scheduled)
- **Database:** Cloudflare D1 (SQLite)
- **Alerts:** Webhook to n8n

## Infrastructure Monitored

### NativeBio
- Proxmox 8 VE (Web UI)
- Multiple VMs (SSH)
- REDCap Server
- pfSense

### TDR
- Proxmox 9 VE (Web UI)
- Data/Backup/Portal/Website VMs
- Command Line & Desktop VMs

### Missouri Breaks
- mbiri.net servers (internal/external)
- pfSense routers

### Iyeska.net HQ
- Main server (n8n, wowasi, netbird)
- DellBuntu Laptop
- Raspberry Pi NAS
- Mac Mini

## Deployment

```bash
# Deploy to Cloudflare Pages
wrangler pages deploy public

# Deploy status check worker
wrangler deploy workers/status-checker.js
```

## Cost

$0/month - 100% free on Cloudflare free tier
