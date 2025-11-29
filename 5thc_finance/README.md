# 5th C Finance Landing Page

**Where innovation meets ag finance!**

This is the static landing page for 5th C Finance, deployed on Cloudflare Pages (100% free tier).

## Overview

A professional coming-soon landing page featuring:
- Modern glassmorphism design with animated gradients
- Custom mountain landscape background
- Email signup form for launch notifications
- Warm sunset/prairie color palette
- Mobile-responsive layout with smooth animations
- Fast global CDN delivery via Cloudflare

## Design

**Color Palette (Extracted from Background Image):**
- Sunset Amber: `#C68A4A` (Primary)
- Sunset Orange: `#E6A665` (Secondary)
- Warm Salmon: `#DFA28C` (Accent/CTA)
- Muted Gray: `#D6D6D6` (Subtext)
- Deep Black: `#0B0B0B` (Backgrounds)
- White: `#FFFFFF` (Headlines)

**Visual Effects:**
- Glassmorphism (frosted glass blur effects)
- Animated gradient text (8s color shift loop)
- Smooth fade-in animations on page load
- Hover effects with transforms and glows
- Subtle background zoom (20s cycle)

**Typography:** Inter font family (Google Fonts)

**Background:** Custom mountain landscape with multi-layer gradient overlay

## Project Structure

```
5thc_finance/
├── public/                      # Static site files
│   ├── index.html              # Main landing page
│   └── assets/
│       ├── css/
│       │   └── style.css       # Styling with animations
│       ├── js/
│       │   └── main.js         # Form handling & interactivity
│       └── images/
│           └── mountain-bg-dark.jpg  # Background image
├── wrangler.toml               # Cloudflare Pages config
├── README.md                   # This file
├── DEPLOYMENT.md               # Deployment guide
├── DESIGN_IMPROVEMENTS.md      # Design documentation
└── CLAUDE.md                   # Development guide
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

**Current Status:**
- **Production:** https://5thc-finance.pages.dev
- **Latest:** https://9831b765.5thc-finance.pages.dev
- **Custom Domain:** https://5thc.finance (setup required)

**To Add Custom Domain:**

1. **Cloudflare Dashboard**
   - Visit: https://dash.cloudflare.com
   - Navigate to: Workers & Pages → 5thc-finance

2. **Add Domain**
   - Click **Custom domains** tab
   - Click **Set up a custom domain**
   - Enter: `5thc.finance`
   - Click **Activate domain**

3. **Verify**
   - Cloudflare auto-creates DNS records
   - Wait 2-5 minutes for SSL certificate
   - Visit https://5thc.finance

See `DEPLOYMENT.md` for detailed instructions.

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
- **Zero hosting costs** - Cloudflare Pages free tier (was $10-30/month)
- **Faster load times** - Static files, global CDN (275+ locations)
- **Better security** - No server, no PHP, no database vulnerabilities
- **Easy maintenance** - Pure HTML/CSS/JS, no WordPress updates
- **Version control** - Git-based deployment with rollback capability
- **Professional design** - Modern glassmorphism and animations
- **Custom colors** - Palette extracted from background image

**Annual Savings:** $120-360/year in hosting costs

## Support

For issues or questions, contact: admin@5thc.finance

## License

© 2025 5th C Finance. All rights reserved.
