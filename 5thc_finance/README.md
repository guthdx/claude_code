# 5th C Finance Landing Page

**Where innovation meets ag finance!**

This is the static landing page for 5th C Finance, deployed on Cloudflare Pages (100% free tier).

## Overview

A coming-soon landing page featuring:
- Clean, modern design with dark theme
- Mountain landscape background
- Email signup form for launch notifications
- Mobile-responsive layout
- Fast global CDN delivery via Cloudflare

## Design

**Color Palette:**
- Primary Blue: `rgb(66, 99, 190)`
- Accent Orange: `rgb(234, 147, 116)`
- Dark Background: `rgb(18, 19, 21)`
- White Text: `rgb(255, 255, 255)`

**Typography:** Inter font family (Google Fonts)

**Background:** Fixed mountain landscape with gradient overlay

## Project Structure

```
5thc_finance/
├── public/                 # Static site files
│   ├── index.html         # Main landing page
│   └── assets/
│       ├── css/
│       │   └── style.css  # Styling
│       └── js/
│           └── main.js    # Form handling & interactivity
├── wrangler.toml          # Cloudflare Pages config
└── README.md              # This file
```

## Local Development

Simply open `public/index.html` in a browser, or use a local server:

```bash
# Python
python3 -m http.server 8000 --directory public

# Node.js (http-server)
npx http-server public -p 8000

# PHP
php -S localhost:8000 -t public
```

Then visit: http://localhost:8000

## Deployment to Cloudflare Pages

### Prerequisites

1. Cloudflare account (free tier)
2. Wrangler CLI installed:
   ```bash
   npm install -g wrangler
   ```
3. Wrangler authenticated:
   ```bash
   wrangler login
   ```

### Deploy

**Option 1: Wrangler CLI (Recommended)**

```bash
# Deploy to production
wrangler pages deploy public --project-name 5thc-finance

# Deploy to preview
wrangler pages deploy public --project-name 5thc-finance --branch preview
```

**Option 2: Git-based Deployment**

1. Push code to GitHub
2. Connect repository in Cloudflare dashboard:
   - Go to Workers & Pages → Create application → Pages → Connect to Git
   - Select repository
   - Build settings:
     - Build output directory: `public`
     - No build command needed (static site)
3. Deploy automatically on git push

### Custom Domain Setup

After deployment, add custom domain in Cloudflare dashboard:

1. Workers & Pages → 5thc-finance → Custom domains
2. Add domain: `5thc.finance`
3. Cloudflare will automatically configure DNS

**Expected URL:** https://5thc.finance

## Email Signup Integration

Currently, email signups are stored in browser localStorage. To integrate with a real email service:

### Option 1: Mailchimp

Replace the `storeEmailLocally()` function in `public/assets/js/main.js`:

```javascript
async function submitToMailchimp(email) {
    const response = await fetch('YOUR_MAILCHIMP_API_ENDPOINT', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
    });
    return response.json();
}
```

### Option 2: Cloudflare Workers (Serverless)

Create a Worker function to handle signups:

```javascript
// workers/signup.js
export default {
    async fetch(request) {
        const { email } = await request.json();
        // Store in D1, KV, or forward to email service
        return new Response(JSON.stringify({ success: true }));
    }
}
```

### Option 3: n8n Workflow

Send to existing n8n instance at n8n.iyeska.net:

```javascript
async function submitToN8n(email) {
    await fetch('https://n8n.iyeska.net/webhook/5thc-signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, timestamp: new Date().toISOString() })
    });
}
```

## Performance

- **100/100 Lighthouse score** (expected on Cloudflare Pages)
- Global CDN with 275+ locations
- Automatic HTTPS
- DDoS protection
- Unlimited bandwidth (free tier)

## Future Enhancements

- [ ] Google Analytics integration
- [ ] Email service integration (Mailchimp/ConvertKit)
- [ ] Social media links
- [ ] About section with company info
- [ ] Blog/news section
- [ ] Contact form

## Migration from WordPress

This static site replaces the WordPress installation with:
- Zero hosting costs (Cloudflare Pages free tier)
- Faster load times (static files, global CDN)
- Better security (no server, no PHP, no database)
- Easy maintenance (pure HTML/CSS/JS)
- Version control (Git-based deployment)

## Support

For issues or questions, contact: admin@5thc.finance

## License

© 2025 5th C Finance. All rights reserved.
