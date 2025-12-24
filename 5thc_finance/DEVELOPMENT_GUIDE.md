# Development Guide: Growing the 5th C Finance Website

**For: Non-Technical Stakeholders**

---

## What You Have Now

Your website is currently a **"coming soon" landing page** that lives on Cloudflare Pages. Think of it like a digital billboard - it's a single page with an email signup form.

**Current Setup:**
- 📄 One HTML file (the page structure)
- 🎨 One CSS file (the styling/colors)
- ⚙️ One JavaScript file (the email form)
- 🖼️ One background image

**How It Works:**
1. You edit files on your computer
2. You run a command to upload them to Cloudflare
3. The website updates immediately at https://5thc.finance

---

## When You're Ready to Build the Full Website...

You have **3 main paths** forward. Here's the simple breakdown:

### Option 1: Keep It Simple (Recommended for Small Sites)

**What:** Add more HTML pages to what you have now

**Best For:** 5-10 page websites (About, Services, Contact, etc.)

**How It Works:**
- Create `about.html`, `services.html`, etc. in the same folder
- Copy the header/footer from your current page
- Add a navigation menu with links between pages

**Pros:**
- ✅ Super simple - anyone can edit HTML
- ✅ No new tools to learn
- ✅ Keep your current deployment process
- ✅ Lightning fast website

**Cons:**
- ❌ If you change the header, you update it on every page manually
- ❌ Gets tedious with 10+ pages

**Example Structure:**
```
public/
├── index.html          (home/coming-soon page)
├── about.html          (about 5th C)
├── services.html       (ag finance products)
├── contact.html        (contact form)
└── assets/             (same CSS/JS/images)
```

---

### Option 2: Add a Content Management System (CMS)

**What:** A dashboard where you can edit content without touching code

**Best For:** Teams with content editors who don't code

**How It Works:**
- Install a CMS tool (like Decap CMS or CloudCannon)
- Content editors log into a dashboard
- They write/edit pages like using Google Docs
- The system converts it to HTML automatically

**Pros:**
- ✅ Non-coders can update content
- ✅ Visual editor (what you see is what you get)
- ✅ Still deploys to Cloudflare Pages

**Cons:**
- ❌ Initial setup takes a few hours
- ❌ One more system to maintain

**Recommended Tools:**
- **Decap CMS** (free, open-source, works with your current setup)
- **CloudCannon** (paid, $45/month, very user-friendly)

---

### Option 3: Use a Static Site Generator

**What:** A tool that builds your website from templates + content files

**Best For:** 20+ page sites, or sites that need a blog

**How It Works:**
- You create template files (header, footer, page layouts)
- You write content in simple markdown files
- You run a command that combines them into a full website
- You deploy the generated files to Cloudflare

**Think of it like:** Mail merge in Word - you have one letter template, and it creates 100 personalized letters.

**Pros:**
- ✅ One header file updates all pages
- ✅ Great for blogs and documentation
- ✅ Still deploys to Cloudflare Pages
- ✅ Content is in simple text files (easy to edit)

**Cons:**
- ❌ Requires running build commands
- ❌ Steeper learning curve

**Popular Tools:**
- **Hugo** (super fast, Go-based)
- **11ty** (JavaScript-based, flexible)
- **Astro** (modern, component-based)

---

## What We Recommend

**Start with Option 1** (add more HTML pages) until you hit **5-7 pages**.

**Then:**
- If you need **non-coders to edit content** → Add a CMS (Option 2)
- If you're building a **large site or blog** → Switch to a generator (Option 3)

---

## What Stays the Same No Matter What

✅ **Hosting:** Still Cloudflare Pages (free, fast, global)
✅ **Domain:** Still https://5thc.finance
✅ **Deployment:** Still one command to publish changes
✅ **Your Design:** All your colors, animations, and branding transfer

---

## Technical Requirements (for whoever does the work)

**You Need:**
- A computer with a code editor (VS Code is free)
- Wrangler CLI installed (Cloudflare's tool)
- Access to the GitHub repository
- Cloudflare account access

**You Don't Need:**
- A web server (Cloudflare handles it)
- A database (unless you want dynamic features later)
- Expensive hosting fees (Cloudflare Pages is free)

---

## Next Steps

1. **Decide:** How many pages will the full website have?
2. **Decide:** Who will update content? Coders or non-coders?
3. **Choose:** Pick Option 1, 2, or 3 based on your answers
4. **Budget:** Estimate time (Option 1 = days, Option 2/3 = weeks)

---

## Questions to Ask Your Developer

- "How many pages before we need a better system than plain HTML?"
- "Can we add a CMS to our current setup without rebuilding?"
- "What's the cost difference between these options?" (mostly time, not money)
- "How do I preview changes before publishing?"

---

## Summary (TL;DR)

**Current:** Single-page static site on Cloudflare Pages
**Future Options:**
1. Add more HTML pages (simple, small sites)
2. Add a CMS (non-coders can edit)
3. Use a site generator (large sites, blogs)

**Recommendation:** Start simple, upgrade when needed.

**Cost:** Hosting is free. Development time is the only cost.

---

*Last Updated: 2025-11-29*
