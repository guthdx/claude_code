# The Stoic Indian - Project Context

## Project Overview
**The Stoic Indian** (originally "Aurelius Echo") is a Stoic wisdom application designed as a Progressive Web App (PWA) for iOS. It uses Geolocation, Scheduling, and Notifications to deliver context-aware quotes from Marcus Aurelius.

## Tech Stack
- **Frontend**: React 18, TypeScript, Vite, Tailwind CSS (via CDN in index.html).
- **Backend**: Node.js (Express).
- **AI**: Google Gemini API (via `@google/genai`).
- **Process Manager**: PM2.
- **Features**: Geolocation API, Notification API, Web Share API.

## Architecture
- **BFF Pattern**: The frontend (`App.tsx`) calls the local Express server (`server.js`), which safely holds the Google API Key and proxies requests to Gemini.
- **PWA**: Configured via `manifest.json` for standalone iOS installation.
- **Port**: The application runs internally on port **3333**.
- **Quote Variety**: Multi-layered system prevents repetition via quote history tracking (30 quotes in localStorage), thematic randomization (15 themes), book/style variation, and context diversity.

## Deployment Instructions (For AI Agents)
1.  **Environment**: This project is designed for a Linux (Ubuntu) server.
2.  **Execution**: Run the `bash setup_aurelius.sh` script.
    - This script will:
        - Create the directory `/var/www/aurelius`.
        - Write ALL source code files.
        - Install dependencies (`npm install`).
        - Build the frontend (`npm run build`).
        - Start the server using `pm2` named "aurelius".
3.  **Nginx Proxy Goal**:
    - The goal is to proxy `http://localhost:3333` to a public domain (e.g., `stoic.iyeska.net`).
    - WebSocket upgrades should be allowed (though not strictly used, good practice for Vite apps).

## Quote Interpretation Style
- **Tone**: Honest, straightforward, conversational, and relatable
- **System Role**: "Thoughtful guide helping people understand Marcus Aurelius's wisdom in practical, modern terms"
- **Approach**: Focus on practical wisdom, authenticity, and self-awareness (not overly harsh or snarky)

## Troubleshooting
- If `npm run build` fails, ensure `tsconfig.json` is present.
- If the server fails to start, check `pm2 logs aurelius`.
- If the API returns 404, ensure the `.env` file exists and contains `API_KEY`.