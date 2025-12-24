<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# The Stoic Indian

A Progressive Web App that delivers context-aware Stoic wisdom from Marcus Aurelius based on your location, schedule, and requests.

**Live URL:** https://stoic.iyeska.net

## Run Locally

**Prerequisites:**  Node.js


1. Install dependencies:
   ```bash
   npm install
   ```
2. Set the `GEMINI_API_KEY` in [.env.local](.env.local) to your Gemini API key
3. Run the app:
   ```bash
   npm run dev
   ```

## Deploy to Production

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment guide.

Quick deploy:
```bash
bash deploy.sh
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Architecture and development guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment instructions
- **[project_context.md](project_context.md)** - Project overview and context
