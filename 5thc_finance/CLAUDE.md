# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**5th C Finance Landing Page** - Professional coming-soon page deployed on Cloudflare Pages (100% free tier).

- **Live URLs:** https://5thc.finance, https://www.5thc.finance
- **Production:** https://5thc-finance.pages.dev
- **Tech:** Pure HTML/CSS/JavaScript (no framework, no build step)
- **Repository:** https://github.com/guthdx/5thc_finance

## Development Commands

### Local Testing
```bash
# Quick local server (Python)
python3 -m http.server 8000 --directory public

# Or with Node.js
npx http-server public -p 8000
```
Visit: http://localhost:8000

### Deployment
```bash
# Deploy to Cloudflare Pages production
wrangler pages deploy public --project-name 5thc-finance

# Preview deployment (test before production)
wrangler pages deploy public --project-name 5thc-finance --branch preview

# Check Wrangler authentication
wrangler whoami

# List Cloudflare Pages projects
wrangler pages project list
```

## Architecture & Design System

### Color Palette (Extracted from Background Image)

All colors are derived from the custom mountain landscape background for visual harmony:

```css
--sunset-amber: #C68A4A     /* Primary - headlines, borders */
--sunset-orange: #E6A665    /* Secondary - gradients */
--warm-salmon: #DFA28C      /* Accent - CTA buttons */
--muted-gray: #D6D6D6       /* Subtext - taglines */
--deep-black: #0B0B0B       /* Backgrounds */
--white: #FFFFFF            /* Headlines */
```

**Important:** When modifying colors, maintain this sunset/prairie aesthetic. The palette is intentionally warm and earthy to match the agricultural finance theme.

### Visual Effects Architecture

**Glassmorphism Pattern:**
- Applied to: header, signup form container, footer
- Technique: `backdrop-filter: blur(20px)` + semi-transparent backgrounds
- Browser support: Includes `-webkit-` prefixes for Safari

**Animation System:**
1. **Page Load Sequence (staggered):**
   - Header slides down (0.8s, immediate)
   - Logo fades in (1s, 0.2s delay)
   - Tagline fades in (1s, 0.4s delay)
   - Hero content rises up (1s, 0.6s delay)
   - Form fades up (1s, 0.8s delay)
   - Footer fades in (1s, 1s delay)

2. **Continuous Animations:**
   - Background: subtle zoom (20s infinite alternate)
   - Main headline gradient: color shift (8s infinite)

3. **Interactive Animations:**
   - Button hover: lift + scale + glow + shine sweep
   - Input focus: border color + glow ring + lift
   - Form messages: slide-in with bounce

**Accessibility:** All animations respect `prefers-reduced-motion` and are disabled automatically for users who request reduced motion.

### File Structure

```
public/
├── index.html                      # Single-page application
└── assets/
    ├── css/
    │   └── style.css              # All styles, ~500 lines, CSS-only animations
    ├── js/
    │   └── main.js                # Email form handler, localStorage-based
    └── images/
        └── mountain-bg-dark.jpg   # Custom background (388KB)
```

**Key Principle:** Zero build step. All files are production-ready as-is. No compilation, transpilation, or bundling required.

## Email Signup Integration

**Current State:** Emails stored in browser localStorage (client-side only).

**To Integrate Production Email Service:**

Edit `public/assets/js/main.js` around line 18. Replace `storeEmailLocally(email)` with one of:

**Option A: n8n Webhook (Recommended for Iyeska infrastructure)**
```javascript
async function submitToN8n(email) {
    await fetch('https://n8n.iyeska.net/webhook/5thc-signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email: email,
            timestamp: new Date().toISOString(),
            source: '5thc-finance-landing'
        })
    });
}
```

**Option B: Cloudflare Workers + KV**
```javascript
async function submitToWorker(email) {
    await fetch('/api/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
    });
}
```

Then create `workers/signup.js`:
```javascript
export default {
    async fetch(request, env) {
        const { email } = await request.json();
        await env.SIGNUPS.put(email, new Date().toISOString());
        return new Response(JSON.stringify({ success: true }));
    }
}
```

## Custom Domain Configuration

Domains are already configured in Cloudflare:
- Primary: `5thc.finance`
- Alternate: `www.5thc.finance`

**To Add Additional Domains:**
1. Cloudflare Dashboard → Workers & Pages → 5thc-finance
2. Custom domains tab → Set up a custom domain
3. Enter domain name
4. Cloudflare auto-creates CNAME record to `5thc-finance.pages.dev`
5. Wait 2-5 minutes for SSL certificate provisioning

## Content and Messaging

**Fixed Content (Do Not Change Without Approval):**
- Headline: "On the horizon.... 5th C coming soon"
- Tagline: "Courage where credit is due"
- Header tagline: "Where innovation meets ag finance!"

**Typography:**
- Font: Inter (Google Fonts, loaded from CDN)
- Headline sizes use `clamp()` for fluid responsive scaling
- Line heights optimized for readability: 1.1-1.6 depending on element

## Troubleshooting

**CSS Not Loading:**
- Verify path: `/assets/css/style.css` (absolute path)
- Check file exists in `public/assets/css/`
- Clear browser cache (Cmd+Shift+R on Mac)

**Animations Not Working:**
- Check browser DevTools console for errors
- Verify browser supports `backdrop-filter` (Safari needs `-webkit-`)
- Check if user has `prefers-reduced-motion` enabled

**Deployment Issues:**
```bash
# Re-authenticate with Cloudflare
wrangler login

# Verify project exists
wrangler pages project list

# Check for errors in Cloudflare dashboard
# Workers & Pages → 5thc-finance → Deployments
```

**Email Form Not Submitting:**
1. Open browser console (F12)
2. Check for JavaScript errors
3. Verify localStorage is enabled (not in incognito mode)
4. Test email format validation (regex: `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`)

## Performance Characteristics

- **Total Page Weight:** ~405 KB (HTML + CSS + JS + image)
- **First Paint:** <500ms (static HTML, inline critical path)
- **Time to Interactive:** ~1s (single JS file, no framework overhead)
- **Expected Lighthouse Score:** 100/100 across all metrics

**CDN Distribution:** 275+ Cloudflare locations worldwide, automatic HTTP/3, Brotli compression.

## Git Workflow

This repository is **standalone** - not part of the main workspace.

**Making Changes:**
```bash
# Edit files in public/
git add .
git commit -m "Descriptive commit message"
git push origin main

# Deploy to Cloudflare
wrangler pages deploy public --project-name 5thc-finance
```

**Deployment is manual** - pushes to GitHub do not automatically deploy. Always run `wrangler pages deploy` after pushing code.

## Design Constraints

**Do Not:**
- Add JavaScript frameworks (React, Vue, etc.) - keep it static
- Change color palette without extracting from background image
- Remove glassmorphism effects (core to design identity)
- Add complex build steps (Webpack, Vite, etc.)
- Use external CSS frameworks (Bootstrap, Tailwind)

**Do:**
- Maintain mobile-first responsive design
- Keep all animations smooth (60fps target)
- Test on Safari (webkit prefixes required for some effects)
- Preserve accessibility features (keyboard nav, screen readers)
- Keep total page weight under 500 KB
