# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**The Stoic Indian** is a Progressive Web App (PWA) that delivers context-aware Stoic wisdom from Marcus Aurelius. It triggers quotes based on:
- **Location**: When you arrive at saved landmarks (geofencing with 1-hour cooldown)
- **Time**: At scheduled times of day (once per day)
- **Manual**: On-demand refresh

## Development Commands

**Local Development:**
```bash
npm install          # Install dependencies
npm run dev          # Start Vite dev server (hot reload)
```

**Production Build:**
```bash
npm run build        # TypeScript compile + Vite build to dist/
npm start            # Start Express server on port 3333
```

**Deployment (Production Server):**
```bash
bash deploy.sh          # Deploy from ~/aurelius-echo to /var/www/aurelius
pm2 logs aurelius       # View server logs
pm2 restart aurelius    # Restart server
pm2 status              # Check process status
```

**Quick Redeploy After Changes:**
```bash
cd ~/aurelius-echo
# Make your changes to source files
bash deploy.sh          # Copies files, builds, and restarts PM2
```

## Architecture

### Backend-for-Frontend (BFF) Pattern
- **Why**: The Express server (`server.js`) acts as a secure proxy to keep the Google Gemini API key server-side
- **Flow**: React app → `/api/quote` or `/api/place` → Express → Google Gemini → React app
- **Environment**: API key must be in `.env` as `API_KEY` (note: NOT `GEMINI_API_KEY` in production, though `.env.local` uses that name for local dev)

### Key Server Endpoints
- `POST /api/quote` - Generates contextual Marcus Aurelius quotes with thoughtful modern interpretations
  - **Request body**: `{ context?: string, previousQuotes?: string[] }`
  - **Variety mechanisms**:
    - Randomized book selection (1-12) from Meditations
    - Randomized theme selection (15 themes: mortality, adversity, duty, virtue, anger, relationships, nature, focus, control, gratitude, discipline, work, difficult people, fear, simplicity)
    - Style variation ("deep cut" vs "essential")
    - Quote history avoidance (last 10 quotes passed to AI)
    - Temperature 0.9 for creative variety
  - **Response normalization**: Handles Gemini returning array or object format
  - **Interpretation tone**: Honest and straightforward, conversational and relatable (not overly harsh or snarky)
  - Includes fallback quote if Gemini API fails
- `POST /api/place` - Converts place descriptions to coordinates using Gemini
- `GET *` - Serves React SPA from `dist/index.html`

### Frontend State Management
- **Persistent State**: Landmarks, schedules, and quote history stored in `localStorage` with keys:
  - `aurelius_landmarks` - Array of geofence triggers
  - `aurelius_schedules` - Array of time-based triggers
  - `aurelius_quote_history` - Array of last 30 quote texts (for variety)
- **Quote Generation**: Main `App.tsx` manages quote fetching with varied context strings
  - Sends quote history to API to avoid repetition
  - Randomizes context strings (e.g., "seeking fresh wisdom", "starting the day", "looking for new perspective")
  - Context adapts to triggers: "arriving at {landmark}" or "it is {schedule label}"
- **Trigger Cooldowns**:
  - Landmarks: 1 hour cooldown per location
  - Schedules: Once per day (date string comparison)

### Component Structure
- `App.tsx` - Main orchestrator with geolocation watcher and schedule interval
- `QuoteCard.tsx` - Displays quote with share functionality (native share API or clipboard fallback)
- `LandmarkManager.tsx` - GPS + Gemini-powered place search for adding geofences
- `ScheduleManager.tsx` - Time picker for recurring daily notifications
- `Navigation.tsx` - Bottom navigation (Time/Home/Place)

### Browser APIs Used
- **Geolocation API**: `navigator.geolocation.watchPosition()` monitors location continuously
- **Notification API**: Triggers browser/system notifications when quotes are auto-generated
- **Web Share API**: Shares quotes via native share sheet (iOS) or falls back to clipboard

## Environment Configuration

- **Local Dev**: Set `GEMINI_API_KEY` in `.env.local`
- **Production**: Set `API_KEY` in `.env` (server.js reads this)
  - The `deploy.sh` script automatically converts `GEMINI_API_KEY` → `API_KEY` during deployment
- **Port**: Defaults to 3333 (configurable via `PORT` env var)

## Deployment Architecture

### Production Server Setup
- **Source**: `~/aurelius-echo` (development files)
- **Deployment**: `/var/www/aurelius` (production files)
- **Process Manager**: PM2 with process name "aurelius"
- **Port**: Express server runs on port 3333

### Cloudflare Tunnel
- **Tunnel**: `iyeska.net` (ID: 1e02b2ec-7f02-4cf5-962f-0db3558e270c)
- **Hostname**: `stoic.iyeska.net` → `http://localhost:3333`
- **Config**: `~/.cloudflared/config.yml`
- **Restart tunnel**: `sudo systemctl restart cloudflared`

### Nginx Configuration
- **Config**: `/etc/nginx/sites-available/stoic.conf`
- **Listen**: `127.0.0.1:8080`
- **Purpose**: Optional reverse proxy layer (currently bypassed by Cloudflare Tunnel)
- **Test config**: `sudo nginx -t`
- **Reload**: `sudo systemctl reload nginx`

## Notable Implementation Details

- **Google Generative AI Package**: Uses `@google/generative-ai` (NOT `@google/genai`)
  - Import: `import { GoogleGenerativeAI } from "@google/generative-ai"`
  - Initialize: `const ai = new GoogleGenerativeAI(API_KEY)`
  - Model: `gemini-2.0-flash-exp` with JSON output mode
  - System Instruction: "You are a thoughtful guide helping people understand Marcus Aurelius's wisdom in practical, modern terms."
  - Interpretation Style: Honest, straightforward, conversational, and relatable (not overly harsh)
  - API docs: https://ai.google.dev/tutorials/node_quickstart

- **PWA Configuration**:
  - App Name: "The Stoic Indian" (full), "Stoic Indian" (short)
  - Icon Source: `icon.svg` (custom gold gradient Stoic design)
  - Manifest: References `/icon.svg` for all icon sizes
  - Apple Touch Icon: `<link rel="apple-touch-icon" href="/icon.svg">` in `index.html`
  - Apple App Title: `<meta name="apple-mobile-web-app-title" content="The Stoic Indian">`
  - Vite builds icon to `/assets/icon-[hash].svg` automatically

- **Haversine Distance**: `utils/geo.ts` implements great-circle distance calculation for geofencing accuracy

- **Time Format**: Schedules use 24-hour format (`HH:MM`) from `<input type="time">`

- **Tailwind via CDN**: Tailwind loaded from CDN in `index.html` (not via PostCSS build process)

- **ES Modules**: Project uses `"type": "module"` - all imports must use `.js` extensions in Node.js files

- **Missing index.css**: An empty `index.css` file is required for the build to succeed (imported by `index.tsx`)

## Quote Variety System

To prevent repetitive quotes, the app implements multiple variety mechanisms:

1. **Quote History Tracking** (`App.tsx:29-33`)
   - Maintains last 30 quotes in localStorage
   - Automatically passes history to API with each request
   - Frontend extracts first 50 characters of each quote for comparison

2. **Server-Side Avoidance** (`server.js:67-72`)
   - Receives previous quotes from frontend
   - Passes last 10 to Gemini with explicit instruction to avoid them
   - Ensures new quotes are "completely different passages"

3. **Thematic Randomization** (`server.js:47-65`)
   - 15 distinct themes randomly selected per request
   - Themes cover: mortality, adversity, duty, virtue, anger, relationships, nature, focus, control, gratitude, discipline, work, difficult people, fear, simplicity

4. **Structural Variation** (`server.js:44-45`)
   - Random book selection (1-12) from Meditations
   - Random style selection ("deep cut" vs "essential")
   - High temperature (0.9) for creative diversity

5. **Context Diversity** (`App.tsx:89-96`, `App.tsx:202-211`)
   - Initial load: 5 different context variations
   - Manual refresh: 5 different context variations
   - Location/schedule triggers: contextual strings
