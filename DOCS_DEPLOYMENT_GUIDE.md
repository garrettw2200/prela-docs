# Prela Documentation Deployment Guide
## Deploy Docs to GitHub Pages with Custom Subdomain

**Goal:** Make Prela documentation publicly accessible at `https://docs.prela.dev` for Stripe verification and customer use.

**Deployment Method:** GitHub Pages with custom subdomain (zero cost, automated via existing workflow)

---

## Prerequisites

- ✅ GitHub repository with docs already configured
- ✅ GitHub Actions workflow already deploying to GitHub Pages
- ✅ Domain name (`prela.dev`) with DNS access
- ✅ MkDocs Material documentation site built and tested

---

## Implementation Steps

### Step 1: Update MkDocs Configuration Files

Update the `site_url` in both mkdocs.yml files to use the custom subdomain.

#### File: `/Users/gw/prela/mkdocs.yml`

**Change:**
```yaml
site_url: https://prela.readthedocs.io
```

**To:**
```yaml
site_url: https://docs.prela.dev
```

#### File: `/Users/gw/prela/docs/mkdocs.yml`

**Change:**
```yaml
site_url: https://prela.readthedocs.io
```

**To:**
```yaml
site_url: https://docs.prela.dev
```

**Why:** This ensures MkDocs generates correct sitemaps, canonical URLs, and meta tags.

---

### Step 2: Create CNAME File for GitHub Pages

GitHub Pages needs a CNAME file to serve the site on a custom domain.

#### File: `/Users/gw/prela/docs/CNAME`

**Create new file with contents:**
```
docs.prela.dev
```

**Why:**
- MkDocs will copy this file to the built site (`site/CNAME`)
- `mkdocs gh-deploy` will include it when deploying to the `gh-pages` branch
- GitHub Pages reads this file to configure the custom domain
- Prevents the CNAME file from being overwritten on each deploy

---

### Step 3: Configure DNS (CNAME Record)

Add a CNAME record in your DNS provider to point to GitHub Pages.

**DNS Provider:** (Cloudflare, Namecheap, GoDaddy, or wherever `prela.dev` is hosted)

**CNAME Record:**
```
Type:  CNAME
Name:  docs
Value: garrettw2200.github.io
TTL:   Auto (or 3600 seconds)
```

**Based on your repository:**
- GitHub username: `garrettw2200`
- Repository: `prela-sdk`
- GitHub Pages URL: `garrettw2200.github.io`

**Result:** `docs.prela.dev` will point to `garrettw2200.github.io`

**Verification:**
```bash
# Wait 5-10 minutes after adding the record, then test:
dig docs.prela.dev CNAME
# Should show: docs.prela.dev. 3600 IN CNAME garrettw2200.github.io.
```

---

### Step 4: Configure GitHub Pages Custom Domain

Enable custom domain in your GitHub repository settings.

**Steps:**

1. Go to your GitHub repository: `https://github.com/garrettw2200/prela-sdk`
2. Click **Settings** (repository settings, not account settings)
3. Scroll down to **Pages** section in the left sidebar
4. Under **Custom domain**, enter: `docs.prela.dev`
5. Click **Save**
6. Wait for DNS check (GitHub will verify the CNAME record)
7. Once verified, check **Enforce HTTPS** (may take a few minutes for SSL cert)

**What happens:**
- GitHub creates/updates the CNAME file in the `gh-pages` branch
- GitHub provisions a free SSL certificate via Let's Encrypt
- HTTPS becomes available within 5-10 minutes

**Note:** The CNAME file you created in Step 2 ensures this setting persists across deployments.

---

### Step 5: Verify GitHub Actions Workflow

Your existing workflow should handle everything automatically.

#### File: `.github/workflows/docs.yml`

**Current configuration (no changes needed):**
```yaml
name: Documentation

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-docs:
    name: Build Documentation
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install mkdocs mkdocs-material mkdocstrings[python] pymdown-extensions

      - name: Build documentation
        working-directory: ./docs
        run: mkdocs build --strict

      - name: Deploy to GitHub Pages
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        working-directory: ./docs
        run: mkdocs gh-deploy --force
```

**What it does:**
1. Runs on every push to `main` branch
2. Installs Python dependencies
3. Builds docs with `mkdocs build --strict` (fails on warnings)
4. Deploys to GitHub Pages with `mkdocs gh-deploy --force`
5. The CNAME file is included in the deployment

**Verification:**
- After your next push to `main`, check the Actions tab
- Workflow should complete successfully
- `gh-pages` branch should contain the built site + CNAME file

---

### Step 6: Trigger Deployment

Push your changes to trigger the workflow.

```bash
cd /Users/gw/prela

# Stage changes
git add mkdocs.yml docs/mkdocs.yml docs/CNAME

# Commit
git commit -m "Configure docs.prela.dev custom domain for GitHub Pages

- Update site_url in mkdocs.yml files
- Add CNAME file for GitHub Pages custom domain
- Docs will be accessible at https://docs.prela.dev

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Push to main (triggers GitHub Actions workflow)
git push origin main
```

**Monitor deployment:**
1. Go to GitHub repository → Actions tab
2. Watch the "Documentation" workflow run
3. Should complete in 2-3 minutes

---

### Step 7: Wait for DNS Propagation and SSL

After DNS configuration and deployment:

**Timeline:**
- **DNS propagation:** 5-60 minutes (usually ~10 minutes)
- **SSL certificate:** 5-10 minutes after DNS propagates
- **Total wait time:** Up to 1 hour (typically ~15-20 minutes)

**Check DNS propagation:**
```bash
# Check CNAME record
dig docs.prela.dev CNAME

# Check A records (should point to GitHub Pages IPs)
dig docs.prela.dev A
```

**Expected GitHub Pages IPs:**
- 185.199.108.153
- 185.199.109.153
- 185.199.110.153
- 185.199.111.153

**Test the site:**
```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://docs.prela.dev

# Test HTTPS
curl -I https://docs.prela.dev
```

---

## Verification Checklist

After deployment completes:

### ✅ DNS Configuration
- [ ] CNAME record exists: `docs.prela.dev` → `garrettw2200.github.io`
- [ ] DNS propagation complete (`dig docs.prela.dev` shows correct CNAME)

### ✅ GitHub Pages Configuration
- [ ] Custom domain set in GitHub repository settings
- [ ] "Enforce HTTPS" is enabled
- [ ] SSL certificate is active (no browser warnings)

### ✅ Documentation Site
- [ ] Homepage loads: `https://docs.prela.dev`
- [ ] Navigation works (all menu items clickable)
- [ ] Search functionality works
- [ ] Code examples display with syntax highlighting
- [ ] Dark/light mode toggle works
- [ ] All pages accessible (no 404s)

### ✅ SEO and Metadata
- [ ] Sitemap generated: `https://docs.prela.dev/sitemap.xml`
- [ ] Robots.txt exists: `https://docs.prela.dev/robots.txt`
- [ ] Canonical URLs point to `docs.prela.dev` (check page source)

### ✅ Integration
- [ ] Links from `prela-website` to docs work correctly
- [ ] GitHub repo links work (edit page, view source)
- [ ] Social links work (GitHub, Discord)

---

## Post-Deployment Tasks

### 1. Update prela-website Links

Update any documentation links in the prela-website to point to the new URL.

**Files to check:**
- `/Users/gw/prela/prela-website/src/**/*.tsx`
- Navigation components
- Footer links
- CTA buttons

**Change from:**
- `https://prela.readthedocs.io/*`

**Change to:**
- `https://docs.prela.dev/*`

### 2. Update README.md

Update the main repository README with the new docs URL.

**File:** `/Users/gw/prela/README.md`

**Add/update:**
```markdown
## Documentation

Full documentation is available at [docs.prela.dev](https://docs.prela.dev)

- [Getting Started](https://docs.prela.dev/getting-started/)
- [Integrations](https://docs.prela.dev/integrations/)
- [API Reference](https://docs.prela.dev/api/)
```

### 3. Update Stripe Business Verification

Add the docs URL to your Stripe business profile:

1. Go to Stripe Dashboard → Settings → Business settings
2. Add `https://docs.prela.dev` as your documentation URL
3. Update business description to include: "Visit docs.prela.dev for technical documentation"

### 4. Configure Redirects (Optional)

If you want to redirect from old readthedocs.io URLs:

**Option A: Add redirect notice**
Create a banner in MkDocs Material theme announcing the new URL.

**Option B: Contact Read the Docs**
Request a redirect from `prela.readthedocs.io` to `docs.prela.dev`.

---

## Cost Analysis

**Total Cost: $0/month**

GitHub Pages includes:
- ✅ Free hosting for public repositories
- ✅ Unlimited bandwidth
- ✅ Free SSL/TLS certificates (Let's Encrypt)
- ✅ Global CDN (Fastly)
- ✅ Custom domain support
- ✅ Automatic HTTPS
- ✅ 100 GB/month bandwidth (soft limit)
- ✅ 100 GB storage

**Comparison:**
- Read the Docs: Free (public) or $50+/month (private)
- Railway hosting: $5-10/month
- Netlify: Free (public) or $19+/month
- Vercel: Free (public) or $20+/month

---

## Troubleshooting

### Issue: DNS not propagating

**Symptoms:** `dig docs.prela.dev` returns no results or SERVFAIL

**Solution:**
```bash
# Check if DNS provider accepted the record
# Use their web interface to verify the CNAME exists

# Try different DNS servers
dig @8.8.8.8 docs.prela.dev CNAME  # Google DNS
dig @1.1.1.1 docs.prela.dev CNAME  # Cloudflare DNS

# Wait 10-30 minutes and try again
```

### Issue: SSL certificate not provisioning

**Symptoms:** Browser shows "Not Secure" or certificate warning

**Solution:**
1. Wait longer (can take up to 24 hours, usually ~10 mins)
2. Verify DNS is fully propagated first
3. Ensure "Enforce HTTPS" is checked in GitHub Pages settings
4. Try disabling and re-enabling custom domain in GitHub settings

### Issue: 404 on custom domain

**Symptoms:** `docs.prela.dev` shows "404 - Page not found"

**Solution:**
1. Check that CNAME file exists in `gh-pages` branch
2. Verify workflow deployed successfully (check Actions tab)
3. Ensure custom domain is set in GitHub repository settings
4. Wait for GitHub Pages to rebuild (can take 10 minutes)

### Issue: CNAME file keeps getting deleted

**Symptoms:** Custom domain setting disappears after each deploy

**Solution:**
- Ensure CNAME file is in `/Users/gw/prela/docs/CNAME` (not in root)
- MkDocs will copy it to `site/CNAME` during build
- `mkdocs gh-deploy` will include it in the `gh-pages` branch

### Issue: Workflow fails with "Permission denied"

**Symptoms:** GitHub Actions workflow fails on `gh-deploy` step

**Solution:**
1. Go to repository Settings → Actions → General
2. Under "Workflow permissions", select "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"
4. Re-run the failed workflow

---

## Agent Knowledge Base Strategy (Future)

### Separation of Concerns

**Public Documentation (GitHub Pages):**
- Purpose: Customer-facing product documentation
- URL: `https://docs.prela.dev`
- Audience: Users, customers, prospects, Stripe verification
- Content: Product docs, API reference, guides, examples

**Internal Knowledge Base (Agent Containers):**
- Purpose: Agent training and RAG system
- Location: `/internal/knowledge-base/` (bundled in containers)
- Audience: Scout, Amplifier, Sentinel agents
- Content: Public docs + internal messaging + competitive intel + roadmaps

### Why Separate?

1. **Security:** Internal strategy, pricing, roadmaps not exposed publicly
2. **Performance:** Agents access local files (fast), no HTTP calls
3. **Reliability:** No runtime dependencies on external URLs
4. **Control:** Update agent knowledge independently from public docs

### Future Implementation

When deploying agents to Railway:

1. **Create internal knowledge base:**
   ```
   /internal/knowledge-base/
   ├── public-docs/      # Mirror of /docs
   ├── messaging/        # Already exists
   ├── competitive/      # Already exists
   ├── product/          # Internal roadmap
   └── README.md
   ```

2. **Update agent configs** to read from `/app/knowledge-base/` instead of local paths

3. **Bundle in Docker:** Copy knowledge-base into container during build

4. **Sync strategy:** Manual or automated sync from `/docs` to `/internal/knowledge-base/public-docs/`

**This is a future task** - not required for docs deployment.

---

## Rollback Procedure

If you need to revert the custom domain:

```bash
# Remove CNAME file
git rm docs/CNAME

# Revert mkdocs.yml changes
git checkout HEAD~1 -- mkdocs.yml docs/mkdocs.yml

# Commit and push
git commit -m "Revert to default GitHub Pages URL"
git push origin main

# In GitHub repository settings:
# Settings → Pages → Remove custom domain
# Delete DNS CNAME record from your provider
```

Documentation will return to the default GitHub Pages URL:
`https://garrettw2200.github.io/prela-sdk/`

---

## Summary

**What you're doing:**
- Configuring GitHub Pages to serve docs at `docs.prela.dev`
- Adding custom domain via DNS CNAME record
- Using existing GitHub Actions workflow for automatic deployment
- Zero cost, fully automated, with free SSL

**Files to modify:**
1. `/Users/gw/prela/mkdocs.yml` - Update site_url
2. `/Users/gw/prela/docs/mkdocs.yml` - Update site_url
3. `/Users/gw/prela/docs/CNAME` - Create new file

**External configuration:**
1. DNS CNAME: `docs` → `garrettw2200.github.io`
2. GitHub Pages: Set custom domain to `docs.prela.dev`

**Timeline:**
- File changes: 5 minutes
- DNS configuration: 5 minutes
- Git commit and push: 2 minutes
- Wait for DNS + SSL: 10-60 minutes
- **Total: ~30-90 minutes**

---

## Support Resources

- **MkDocs Material:** https://squidfunk.github.io/mkdocs-material/
- **GitHub Pages:** https://docs.github.com/en/pages
- **Custom Domains:** https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site
- **DNS Configuration:** Check your DNS provider's documentation

---

## Ready to Deploy?

Follow the steps in order:
1. ✅ Update mkdocs.yml files (Step 1)
2. ✅ Create CNAME file (Step 2)
3. ✅ Configure DNS (Step 3)
4. ✅ Configure GitHub Pages (Step 4)
5. ✅ Commit and push changes (Step 6)
6. ⏳ Wait for DNS + SSL (Step 7)
7. ✅ Verify deployment (Verification Checklist)

**Next step:** Update the mkdocs.yml files and create the CNAME file, then commit and push!
