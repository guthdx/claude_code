# CLAUDE.md - 5th C Finance

Project-specific guidance for Claude Code when working with the 5th C Finance landing page.

## Project Overview

**Purpose:** Static coming-soon landing page for 5th C Finance deployed on Cloudflare Pages free tier.

**URL:** https://5thc.finance (after custom domain setup)

**Tech Stack:**
- Pure HTML/CSS/JavaScript (no framework)
- Cloudflare Pages (free tier, unlimited bandwidth)
- Wrangler CLI for deployments
- Mobile-first responsive design

## Design Specifications

**Brand Colors:**
```css
--primary-blue: rgb(66, 99, 190)    /* Main brand color */
--accent-orange: rgb(234, 147, 116) /* Tagline, CTAs */
--dark-bg: rgb(18, 19, 21)          /* Background */
--white: rgb(255, 255, 255)         /* Text */
```

**Typography:** Inter (Google Fonts)

**Background:** Fixed mountain landscape (Unsplash) with gradient overlay

**Messaging:**
- Headline: "On the horizon.... 5th C coming soon"
- Tagline: "Courage where credit is due"
- Header: "Where innovation meets ag finance!"

## Development Workflow

### Local Testing

```bash
# Quick preview
python3 -m http.server 8000 --directory public

# Or with Node.js
npx http-server public -p 8000
```

Visit: http://localhost:8000

### Deployment

**Deploy to Cloudflare Pages:**
```bash
wrangler pages deploy public --project-name 5thc-finance
```

**Preview deployment:**
```bash
wrangler pages deploy public --project-name 5thc-finance --branch preview
```

### File Structure

```
public/
├── index.html              # Main landing page
└── assets/
    ├── css/
    │   └── style.css      # All styles (no preprocessor)
    └── js/
        └── main.js        # Form handling, analytics
```

## Email Signup Implementation

**Current:** localStorage (client-side only, for testing)

**Production Options:**

1. **n8n Webhook (Recommended for Iyeska infrastructure)**
   - Endpoint: `https://n8n.iyeska.net/webhook/5thc-signup`
   - Workflow: n8n → Slack notification → Google Sheets/Airtable
   - No third-party dependencies

2. **Cloudflare Workers + KV**
   - Store emails in Workers KV
   - Weekly export via cron trigger
   - 100% free tier (1000 writes/day limit)

3. **Mailchimp/ConvertKit**
   - Direct API integration
   - Requires paid plan ($10-20/month)

**To switch from localStorage to n8n:**

Edit `public/assets/js/main.js`:

```javascript
async function submitToN8n(email) {
    const response = await fetch('https://n8n.iyeska.net/webhook/5thc-signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email: email,
            timestamp: new Date().toISOString(),
            source: '5thc-finance-landing'
        })
    });

    if (!response.ok) {
        throw new Error('Signup failed');
    }

    return response.json();
}
```

Replace the `try` block in the form handler.

## Custom Domain Setup

1. Deploy to Cloudflare Pages first
2. In Cloudflare dashboard:
   - Workers & Pages → 5thc-finance → Custom domains
   - Add domain: `5thc.finance`
3. DNS will auto-configure (already on Cloudflare)

## Performance Optimization

**Current (static files):**
- No build step required
- No JavaScript framework overhead
- Single HTTP request for HTML
- Lazy-loaded fonts (Google Fonts)

**Future optimizations:**
- Inline critical CSS (first paint)
- Self-host Google Fonts (avoid external request)
- Add service worker for offline support
- Compress background image (currently Unsplash)

## Analytics

**Google Analytics (optional):**

Add to `<head>` in `public/index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

**Cloudflare Web Analytics (privacy-first, recommended):**

Add to `<head>`:

```html
<!-- Cloudflare Web Analytics -->
<script defer src='https://static.cloudflareinsights.com/beacon.min.js'
        data-cf-beacon='{"token": "YOUR_TOKEN"}'></script>
```

Get token from: Cloudflare Dashboard → Web Analytics

## Content Updates

To update messaging or design:

1. Edit files in `public/`
2. Test locally: `python3 -m http.server 8000 --directory public`
3. Deploy: `wrangler pages deploy public --project-name 5thc-finance`
4. Changes are live in ~30 seconds

## Migration Checklist

- [x] Recreate WordPress design in pure HTML/CSS/JS
- [x] Email signup form (localStorage for now)
- [x] Mobile-responsive layout
- [x] Wrangler configuration
- [ ] Deploy to Cloudflare Pages
- [ ] Configure custom domain (5thc.finance)
- [ ] Test email signup flow
- [ ] Integrate with n8n or Mailchimp
- [ ] Add Google/Cloudflare Analytics (optional)
- [ ] Update DNS to point to Cloudflare Pages
- [ ] Decommission WordPress site

## Troubleshooting

**Deployment fails:**
```bash
# Check Wrangler auth
wrangler whoami

# Re-authenticate
wrangler login

# Check project name
wrangler pages project list
```

**Custom domain not working:**
1. Verify domain in Cloudflare dashboard
2. Check DNS records (should auto-configure)
3. Wait 5-10 minutes for propagation
4. Clear browser cache

**Email signup not working:**
1. Check browser console for errors
2. Verify localStorage is enabled
3. Test with different email format
4. Check network tab for API calls (if using external service)

## Future Enhancements

**Phase 2: Content expansion**
- About section (company mission, values)
- Team bios
- Services overview
- Contact form

**Phase 3: Blog/News**
- Static site generator (11ty, Hugo)
- Markdown-based content
- RSS feed
- Search functionality

**Phase 4: Full site**
- Loan application portal
- Customer dashboard
- API integrations

## Data Sovereignty Principles

Following Iyeska standards:

- ✅ Self-hosted on Cloudflare (US-based, privacy-focused)
- ✅ No third-party trackers (no Facebook Pixel, no Google Ads)
- ✅ Email data under full control (localStorage → n8n → self-hosted)
- ✅ Open source (pure HTML/CSS/JS, no proprietary code)
- ✅ Audit logging (Cloudflare analytics, optional)

## Support

Contact: admin@5thc.finance or admin@iyeska.net
