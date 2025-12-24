# Deployment Guide - The Stoic Indian

This document details the production deployment of **The Stoic Indian** to `stoic.iyeska.net`.

## Deployment History

**Deployed:** November 20, 2025
**Server:** Ubuntu server at `/var/www/aurelius`
**URL:** https://stoic.iyeska.net
**Status:** ✅ Live and functional

## Pre-Deployment Fixes

### 1. Fixed Google Generative AI Package
The original code from Google AI Studio used an incorrect package name.

**Problem:**
- Package: `@google/genai@^0.1.1` (doesn't exist)
- Import: `import { GoogleGenAI } from "@google/genai"`

**Solution:**
- Changed to: `@google/generative-ai@^0.24.1`
- Updated import: `import { GoogleGenerativeAI } from "@google/generative-ai"`
- Updated API calls in `server.js`:

```javascript
// Old (broken)
const ai = new GoogleGenAI({ apiKey: API_KEY });
const response = await ai.models.generateContent({ model: '...', ... });

// New (working)
const ai = new GoogleGenerativeAI(API_KEY);
const model = ai.getGenerativeModel({
  model: 'gemini-2.0-flash-exp',
  generationConfig: { responseMimeType: "application/json", temperature: 0.9 },
  systemInstruction: "..."
});
const result = await model.generateContent(prompt);
const text = result.response.text();
```

### 2. Created Empty index.css
Vite build failed without `index.css` (imported by `index.tsx`). Created empty file to resolve.

## Deployment Process

### Step 1: Environment Setup
```bash
# API key already configured in ~/aurelius-echo/.env.local:
GEMINI_API_KEY=AIzaSyBYsBDx2mWxNEsDVutXjKe4WemLQTTsUlc
```

### Step 2: Create Deployment Directory
```bash
sudo mkdir -p /var/www/aurelius
sudo chown -R $USER:$USER /var/www/aurelius
```

### Step 3: Deploy Files
```bash
cd ~/aurelius-echo

# Copy all files except node_modules, dist, .git
rsync -av \
  --exclude 'node_modules' \
  --exclude 'dist' \
  --exclude '.git' \
  --exclude '*.sh' \
  --exclude 'ai_studio_code*.sh' \
  ./ /var/www/aurelius/

# Convert environment variable for production
cd /var/www/aurelius
sed 's/GEMINI_API_KEY=/API_KEY=/' .env.local > .env
```

### Step 4: Install and Build
```bash
cd /var/www/aurelius
npm install
touch index.css  # Required for build
npm run build
```

### Step 5: Start with PM2
```bash
pm2 start npm --name "aurelius" -- start
pm2 save
```

**Result:** Server running on port 3333

### Step 6: Configure Cloudflare Tunnel
Edited `~/.cloudflared/config.yml`:

```yaml
tunnel: 1e02b2ec-7f02-4cf5-962f-0db3558e270c

ingress:
  - hostname: n8n.iyeska.net
    service: http://localhost:5678
  - hostname: recap.iyeska.net
    service: http://localhost:8088
  - hostname: stoic.iyeska.net    # Added this
    service: http://localhost:3333 # Added this
  - service: http_status:404
```

```bash
sudo systemctl restart cloudflared
```

### Step 7: Optional Nginx Configuration
Created `/etc/nginx/sites-available/stoic.conf` (currently not in use as Cloudflare Tunnel bypasses it):

```nginx
server {
    listen 127.0.0.1:8080;
    server_name stoic.iyeska.net;

    location / {
        proxy_pass http://127.0.0.1:3333;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header Referrer-Policy strict-origin-when-cross-origin;
}
```

## Custom Icon and Branding Setup

### Step 8: Deploy Custom Icon and App Name
```bash
cd ~/aurelius-echo

# Icon file: new_icon.svg (gold gradient Stoic design)
cp new_icon.svg icon.svg
```

Updated `manifest.json`:
```json
{
  "name": "The Stoic Indian",
  "short_name": "Stoic Indian",
  "icons": [
    {
      "src": "/icon.svg",
      "sizes": "192x192",
      "type": "image/svg+xml"
    },
    {
      "src": "/icon.svg",
      "sizes": "512x512",
      "type": "image/svg+xml"
    }
  ]
}
```

Updated `index.html`:
```html
<title>The Stoic Indian</title>
<link rel="apple-touch-icon" href="/icon.svg">
<meta name="apple-mobile-web-app-title" content="The Stoic Indian">
```

Deployed:
```bash
cp icon.svg manifest.json index.html /var/www/aurelius/
cd /var/www/aurelius
npm run build
cp icon.svg dist/
pm2 restart aurelius
```

## Automated Deployment Script

Created `~/aurelius-echo/deploy.sh` for future updates:

```bash
#!/bin/bash
set -e

echo "=== The Stoic Indian Deployment ==="

DEPLOY_DIR="/var/www/aurelius"
SOURCE_DIR="$HOME/aurelius-echo"

# Copy files
rsync -av \
    --exclude 'node_modules' \
    --exclude 'dist' \
    --exclude '.git' \
    --exclude '*.sh' \
    --exclude 'ai_studio_code*.sh' \
    ./ "$DEPLOY_DIR/"

# Convert env var
sed 's/GEMINI_API_KEY=/API_KEY=/' "$SOURCE_DIR/.env.local" > "$DEPLOY_DIR/.env"

# Build
cd "$DEPLOY_DIR"
npm install
npm run build

# Restart PM2
if pm2 list | grep -q "aurelius"; then
    pm2 stop aurelius
    pm2 delete aurelius
fi

pm2 start npm --name "aurelius" -- start
pm2 save

echo "Deployment complete!"
```

## Verification

### Test API Endpoint
```bash
curl -X POST https://stoic.iyeska.net/api/quote \
  -H "Content-Type: application/json" \
  -d '{"context":"testing"}' | jq .
```

**Expected Response:**
```json
{
  "quote": "Marcus Aurelius quote...",
  "interpretation": "Blunt modern interpretation..."
}
```

### Test Icon
```bash
curl -I https://stoic.iyeska.net/icon.svg
# Should return 200 OK

curl -s https://stoic.iyeska.net | grep apple-touch-icon
# Should show: <link rel="apple-touch-icon" href="/assets/icon-[hash].svg">
```

## Production Monitoring

```bash
# View logs
pm2 logs aurelius

# Check status
pm2 status

# Restart server
pm2 restart aurelius

# Check Cloudflare tunnel status
sudo systemctl status cloudflared
```

## Adding App to iPhone

1. Open Safari on iPhone
2. Navigate to https://stoic.iyeska.net
3. Tap Share button (square with up arrow)
4. Scroll down and tap "Add to Home Screen"
5. Custom gold icon will appear on home screen
6. App opens in standalone mode (no browser chrome)

## Future Updates

To redeploy after making changes:

```bash
cd ~/aurelius-echo
# Make your code changes
bash deploy.sh
```

The script will:
1. Copy updated files to `/var/www/aurelius`
2. Convert environment variables
3. Install dependencies
4. Build frontend
5. Restart PM2 process

## Troubleshooting

### Server won't start
```bash
pm2 logs aurelius --lines 50
# Check for API key issues or missing dependencies
```

### Icon not showing
```bash
# Force rebuild and copy icon
cd /var/www/aurelius
npm run build
cp icon.svg dist/
pm2 restart aurelius
```

### Cloudflare Tunnel issues
```bash
# Check tunnel status
cloudflared tunnel list
cloudflared tunnel info iyeska.net

# Restart tunnel
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

### API quota exceeded
- Check Google AI Studio dashboard
- Gemini API has generous free tier (1500 requests/day)
- Consider implementing rate limiting if needed

## Success Metrics

✅ Server running on PM2: `pm2 status`
✅ API responding: `curl https://stoic.iyeska.net/api/quote`
✅ Icon deployed: `curl -I https://stoic.iyeska.net/icon.svg`
✅ Cloudflare Tunnel active: `cloudflared tunnel list`
✅ PWA installable on iOS
✅ Gemini API generating quotes
✅ Geolocation features enabled
✅ Notification permissions working

---

**Deployed by:** Claude Code
**Date:** November 20, 2025
**Status:** Production Ready 🚀
