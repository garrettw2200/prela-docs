# Railway Deployment Implementation Guide
## Prela Platform Production Deployment (prela.dev)

**Timeline**: 4-6 hours
**Estimated Cost**: $60-85/month (simplified architecture)
**Domain**: prela.dev

---

## ⚠️ IMPORTANT: Simplified Architecture (Feb 1, 2026)

**This guide was updated for the simplified architecture that removes Kafka and Trace Service:**

- ✅ **Kafka REMOVED** - Direct HTTP → ClickHouse writes (saves $30/mo)
- ✅ **Trace Service REMOVED** - No background worker needed (saves $20/mo)
- ✅ **Cost**: $60/month (down from $119/month)

**What to skip in this guide:**
- Part 1.2: Upstash Kafka setup → **SKIP**
- Part 3.2: Trace Service deployment → **SKIP**
- Kafka environment variables in Ingest Gateway → **OMIT**

**Current status:**
- ✅ Stripe: Already configured (8 products: Lunch Money $14, Pro $79, 6 overages)
- ✅ Clerk: Backend integrated, frontend using Clerk UI components
- ⏳ Need to create production Clerk application (currently using test/dev)
- ⏳ Need to create production Stripe products (currently using test mode)

---

## Pre-Deployment Preparation

### Generate Secrets

Run these commands and save the outputs:

```bash
# Generate JWT Secret
openssl rand -hex 32

# Generate another secret if needed for session management
openssl rand -hex 32
```

Save these in a secure location (password manager).

---

## Part 1: External Services Setup (60 minutes)

### ☐ 1.1 ClickHouse (15 min)

> **Alternative:** Self-host ClickHouse on your own server for free. See `CLICKHOUSE_SELF_HOST_IMPLEMENTATION.md` and Part 7.5 below. The current production setup uses a self-hosted instance at `clickhouse.prela.dev` via Cloudflare Tunnel.

**URL**: https://clickhouse.com/cloud

**Steps**:
1. Create account (if new)
2. Click "Create Service"
3. Configuration:
   - **Name**: `prela-production`
   - **Tier**: Development (free 30-day trial)
   - **Region**: US East (N. Virginia)
   - **Provider**: AWS

4. Wait for provisioning (~2 minutes)

5. Click "Connect" and save these values:

```bash
CLICKHOUSE_HOST=
CLICKHOUSE_PORT=8443
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=
CLICKHOUSE_DATABASE=prela
```

6. Test connection:
```bash
curl 'https://YOUR_HOST:8443/?query=SELECT%201' \
  --user 'default:YOUR_PASSWORD'
```

Expected: `1`

7. Create database:
```bash
curl 'https://YOUR_HOST:8443/?query=CREATE%20DATABASE%20IF%20NOT%20EXISTS%20prela' \
  --user 'default:YOUR_PASSWORD'
```

**✓ Checkpoint**: ClickHouse connection works and `prela` database exists

---

### ~~☐ 1.2 Upstash Kafka~~ -- REMOVED

> **Kafka was removed in the simplified architecture (Feb 1, 2026).** Ingest Gateway writes directly to ClickHouse via HTTP. No message queue needed.

---

### ☐ 1.3 Clerk Authentication (15 min)

**URL**: https://dashboard.clerk.com

**Current Status:** ✅ Backend integration complete, frontend using Clerk UI components

**Note:** If you already have a Clerk test/dev application, you can either:
- **Option A:** Use existing app for initial testing (faster)
- **Option B:** Create new production app (recommended for launch)

**Steps for New Production App:**
1. Create account or login
2. Click "Create Application"
3. Configuration:
   - **Name**: `Prela Production`
   - **Application type**: Personal
   - **Sign-in options**:
     - ✓ Email address (required)
     - ✓ Google OAuth (recommended)
     - ✓ GitHub OAuth (optional)

4. After creation, go to "Configure" → "Email, Phone, Username"
   - Ensure "Email address" is enabled and required
   - Optional: Add phone number support

5. Go to "Organizations" → Enable organizations (for future team features)

6. Go to "API Keys" and save:

```bash
CLERK_SECRET_KEY=sk_live_XXXXX  # For backend API Gateway
CLERK_PUBLISHABLE_KEY=pk_live_XXXXX  # For frontend dashboard
```

7. Go to "JWT Templates" → Click "New template" → "Blank"
   - **Name**: `prela-jwt`
   - Keep default settings (claims are automatically included)
   - Click "Apply changes"
   - The JWKS URL will be in format:

```bash
CLERK_JWKS_URL=https://[your-app-name].clerk.accounts.dev/.well-known/jwks.json
```

**✓ Checkpoint**: Clerk app created, API keys saved

**Note**: We'll add allowed domains/redirect URLs later after Railway deployment (Part 4)

---

### ☐ 1.4 Stripe Billing (15 min)

**URL**: https://dashboard.stripe.com

**Current Status:** ✅ Pricing structure defined ($14 Lunch Money, $79 Pro, 6 overages)

**Note:** If you already have Stripe test products configured, verify they match the pricing below. Otherwise, create new products.

**Steps**:
1. Login or create account
2. Switch to "Test mode" (toggle in top right) for initial testing
3. Go to "Products" → "Add product"

**Product 1: Lunch Money** ($14/month)
- **Name**: Lunch Money
- **Description**: Perfect for solo developers and small teams
- **Pricing**: Standard pricing
  - **Price**: $14.00 USD
  - **Billing period**: Monthly
  - **Payment type**: Recurring
- Click "Add product"
- **Save the Price ID**: `price_XXXXX` → This is `STRIPE_LUNCH_MONEY_PRICE_ID`

**Product 2: Pro** ($79/month base)
- **Name**: Pro
- **Description**: For growing teams with advanced needs (1M traces/month included + usage-based overages)
- **Pricing**: Standard pricing
  - **Price**: $79.00 USD
  - **Billing period**: Monthly
  - **Payment type**: Recurring
- Click "Add product"
- **Save the Price ID**: `price_XXXXX` → This is `STRIPE_PRO_PRICE_ID`

**Product 3-8: Pro Overages** (Usage-based)

For each overage, create a new product:

**Traces Overage**:
- **Name**: Pro - Traces Overage
- **Pricing**: Graduated pricing
  - **Usage is metered**: Yes
  - **Charge for metered usage**: During billing cycle
  - **Price**: $8.00 USD per 100,000 traces
- Save Price ID → `STRIPE_PRO_TRACES_PRICE_ID`

**Users Overage**:
- **Name**: Pro - Users Overage
- **Price**: $12.00 USD per user
- Save Price ID → `STRIPE_PRO_USERS_PRICE_ID`

**AI Hallucination Checks**:
- **Name**: Pro - AI Hallucination Detection
- **Price**: $5.00 USD per 10,000 checks
- Save Price ID → `STRIPE_PRO_AI_HALLUCINATION_PRICE_ID`

**AI Drift Baselines**:
- **Name**: Pro - AI Drift Detection
- **Price**: $2.00 USD per 10 baselines
- Save Price ID → `STRIPE_PRO_AI_DRIFT_PRICE_ID`

**AI NLP Searches**:
- **Name**: Pro - AI Semantic Search
- **Price**: $3.00 USD per 1,000 searches
- Save Price ID → `STRIPE_PRO_AI_NLP_PRICE_ID`

**Retention Extension**:
- **Name**: Pro - Extended Retention
- **Price**: $10.00 USD per 30 days
- Save Price ID → `STRIPE_PRO_RETENTION_PRICE_ID`

4. Go to "Developers" → "API keys" and save:

```bash
STRIPE_SECRET_KEY=sk_test_
STRIPE_PUBLISHABLE_KEY=pk_test_
```

**Note**: Switch to live mode keys before production launch

5. **Webhook setup** - We'll do this after API Gateway deployment

**✓ Checkpoint**: 8 products created, all Price IDs saved, API keys saved

---

## Part 2: Railway Project Setup (30 minutes)

### ☐ 2.1 Create Railway Project (5 min)

**URL**: https://railway.app

**Steps**:
1. Login or create account
2. Click "New Project" → "Empty Project"
3. Project name: `prela-production`
4. Select region: **US East**

**✓ Checkpoint**: Railway project created

---

### ☐ 2.2 Add PostgreSQL (5 min)

1. In your Railway project, click "+ New"
2. Select "Database" → "PostgreSQL"
3. Name it: `prela-postgres`
4. Wait for provisioning (~2 minutes)

5. Click on the Postgres service → "Variables" tab
6. **Save the DATABASE_URL** (you'll reference this as `${{Postgres.DATABASE_URL}}`)

**✓ Checkpoint**: PostgreSQL provisioned, DATABASE_URL saved

---

### ☐ 2.3 Add Redis (5 min)

1. Click "+ New" → "Database" → "Redis"
2. Name it: `prela-redis`
3. Wait for provisioning (~1 minute)

4. Click on Redis service → "Variables" tab
5. **Save the REDIS_URL** (you'll reference this as `${{Redis.REDIS_URL}}`)

**✓ Checkpoint**: Redis provisioned, REDIS_URL saved

---

### ☐ 2.4 Run Database Migrations (15 min)

> **How Railway DB access works**: The `DATABASE_URL` in service variables uses the private `postgres.railway.internal` hostname — only reachable from within Railway's network. To run migrations locally, use the **public proxy URL** from the Postgres service's own variables (`DATABASE_PUBLIC_URL`).

**Getting the public URL**:
```bash
# Must be linked to the api-gateway service (or any service in the project)
cd /path/to/prela/backend/services/api-gateway
railway variables --service Postgres --json | python3 -c "
import sys, json; d = json.load(sys.stdin)
print(d['DATABASE_PUBLIC_URL'])
"
```

This outputs something like:
```
postgresql://postgres:<password>@switchyard.proxy.rlwy.net:<port>/railway
```

**Run all migrations** (run from repo root):
```bash
PUBLIC_DB="postgresql://postgres:<password>@switchyard.proxy.rlwy.net:<port>/railway"

for f in backend/migrations/*.sql; do
  echo "Running $f..."
  psql "$PUBLIC_DB" -f "$f"
done
```

Or run a single migration:
```bash
psql "$PUBLIC_DB" -f backend/migrations/001_create_users_and_subscriptions.sql
```

**Option B: Using TablePlus/pgAdmin/DBeaver**

1. In Railway dashboard → Postgres service → **Connect** tab → copy the public connection string
2. Open your SQL client and connect using those credentials
3. Open and execute each file in `backend/migrations/` in order

**Verify migrations**:
```bash
psql "$PUBLIC_DB" -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
"
```

Expected tables (after all migrations):
- api_keys
- data_sources
- project_teams
- subscriptions
- team_invitations
- team_members
- teams
- usage_overages
- usage_records
- users

**✓ Checkpoint**: All tables created successfully

---

## Part 3: Backend Services Deployment (90 minutes)

### Environment Variables Template

Create a file `railway-env-template.txt` with all your secrets filled in:

```bash
# ============================================
# CLICKHOUSE (from Part 1.1)
# ============================================
CLICKHOUSE_HOST=xxxxx.us-east-1.aws.clickhouse.cloud
CLICKHOUSE_PORT=8443
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=YOUR_PASSWORD_HERE
CLICKHOUSE_DATABASE=prela

# ============================================
# CLERK (from Part 1.3)
# ============================================
CLERK_SECRET_KEY=sk_live_XXXXX
CLERK_PUBLISHABLE_KEY=pk_live_XXXXX
CLERK_JWKS_URL=https://XXXXX.clerk.accounts.dev/.well-known/jwks.json

# ============================================
# STRIPE (from Part 1.4)
# ============================================
STRIPE_SECRET_KEY=sk_test_XXXXX
STRIPE_PUBLISHABLE_KEY=pk_test_XXXXX
STRIPE_WEBHOOK_SECRET=whsec_XXXXX
STRIPE_LUNCH_MONEY_PRICE_ID=price_XXXXX
STRIPE_PRO_PRICE_ID=price_XXXXX
STRIPE_PRO_TRACES_PRICE_ID=price_XXXXX
STRIPE_PRO_USERS_PRICE_ID=price_XXXXX
STRIPE_PRO_AI_HALLUCINATION_PRICE_ID=price_XXXXX
STRIPE_PRO_AI_DRIFT_PRICE_ID=price_XXXXX
STRIPE_PRO_AI_NLP_PRICE_ID=price_XXXXX
STRIPE_PRO_RETENTION_PRICE_ID=price_XXXXX

# ============================================
# JWT SECRET (generated earlier)
# ============================================
JWT_SECRET=YOUR_32_BYTE_HEX_HERE
JWT_ALGORITHM=HS256
JWT_EXPIRATION_MINUTES=60
```

---

### ☐ 3.1 Deploy Ingest Gateway (20 min)

1. In Railway project, click "+ New"
2. Select "GitHub Repo"
3. If first time:
   - Click "Configure GitHub App"
   - Select your repository
   - Return to Railway

4. Select your `prela` repository
5. Click "Add variables" later (we'll configure the service first)

**Service Configuration**:
- **Service name**: `prela-ingest-gateway`
- Click on the service → "Settings"
- **Root Directory**: `backend/services/ingest-gateway`
- **Watch Paths**: (leave default)

**Environment Variables**:

Click "Variables" tab and add:

```bash
# Service Config
SERVICE_NAME=prela-ingest-gateway
ENVIRONMENT=production
LOG_LEVEL=INFO

# Database
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Redis
REDIS_URL=${{Redis.REDIS_URL}}

# ClickHouse (paste your values from Part 1.1)
CLICKHOUSE_HOST=xxxxx.us-east-1.aws.clickhouse.cloud
CLICKHOUSE_PORT=8443
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=YOUR_PASSWORD_HERE
CLICKHOUSE_DATABASE=prela

# ⚠️ KAFKA VARIABLES REMOVED (simplified architecture)
# Direct HTTP → ClickHouse writes (no message queue)
# If you need Kafka later, see INFRASTRUCTURE_SIMPLIFICATION.md

# CORS (temporary - we'll update after frontend deployment)
CORS_ORIGINS=["*"]

# Rate Limiting
RATE_LIMIT_PER_MINUTE=1000
```

**Deploy**:
- **Preferred:** Push to GitHub — Railway auto-deploys on every push to `main`
- **Manual fallback:** `cd` into the service directory and run `railway up`
  - Each service is linked separately; Railway uses CWD as the upload root
  - Do NOT run `railway up` from a parent directory (e.g. `backend/`) — it won't find the Dockerfile
- Wait 3-5 minutes for build
- Check "Deployments" tab for status

**Get Public URL**:
- Go to "Settings" → "Networking"
- Click "Generate Domain"
- Your URL: `prela-ingest-gateway-production.up.railway.app`
- **Save this URL**: `INGEST_GATEWAY_URL=https://prela-ingest-gateway-production.up.railway.app`

**Verify Health**:
```bash
curl https://prela-ingest-gateway-production.up.railway.app/health
```

Expected: `{"status":"healthy"}`

**✓ Checkpoint**: Ingest Gateway deployed and health check passes

---

### ☐ 3.2 Deploy Trace Service (20 min) - ⚠️ **SKIP THIS STEP**

**Status:** **NOT NEEDED** for simplified architecture (removed Feb 1, 2026)

**Why skipped:**
- Ingest Gateway now writes directly to ClickHouse (no Kafka consumer needed)
- Saves $10-20/month in compute costs
- Reduces architectural complexity
- ClickHouse tables are created by Ingest Gateway on first write

**What happens instead:**
- Ingest Gateway receives traces via HTTP POST
- Applies gzip decompression if needed
- Writes directly to ClickHouse in batches
- Returns success response to SDK immediately

**Verification (do this after deploying Ingest Gateway in Part 3.1):**

Check that ClickHouse tables exist:
```bash
curl 'https://YOUR_CLICKHOUSE_HOST:8443/?query=SHOW%20TABLES%20FROM%20prela' \
  --user 'default:YOUR_PASSWORD'
```

Expected: `traces` and `spans` tables

Check Ingest Gateway logs for direct writes:
```
[INFO] Received batch: 10 traces
[INFO] Writing directly to ClickHouse
[INFO] Successfully wrote 10 traces to ClickHouse
```

**When to add Trace Service back:**
- If you add Kafka back (>500 users, see Part 1.2 notes)
- If you need asynchronous processing
- If ClickHouse downtime is causing ingestion failures

**Action:** Continue to Part 3.3 (API Gateway deployment)

---

### ☐ 3.3 Deploy API Gateway (30 min)

1. Click "+ New" → "GitHub Repo"
2. Select your `prela` repository

**Service Configuration**:
- **Service name**: `prela-api-gateway`
- Go to "Settings"
- **Root Directory**: `backend/services/api-gateway`

**Environment Variables**:

```bash
# Service Config
SERVICE_NAME=prela-api-gateway
ENVIRONMENT=production
LOG_LEVEL=INFO

# Database
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Redis
REDIS_URL=${{Redis.REDIS_URL}}

# ClickHouse (same as other services)
CLICKHOUSE_HOST=
CLICKHOUSE_PORT=8443
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=
CLICKHOUSE_DATABASE=prela

# JWT Authentication (use generated secret)
JWT_SECRET=
JWT_ALGORITHM=HS256
JWT_EXPIRATION_MINUTES=60

# Clerk (from Part 1.3)
CLERK_SECRET_KEY=
CLERK_PUBLISHABLE_KEY=
CLERK_JWKS_URL=

# Stripe (from Part 1.4)
STRIPE_SECRET_KEY=
STRIPE_PUBLISHABLE_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_LUNCH_MONEY_PRICE_ID=
STRIPE_PRO_PRICE_ID=
STRIPE_PRO_TRACES_PRICE_ID=
STRIPE_PRO_USERS_PRICE_ID=
STRIPE_PRO_AI_HALLUCINATION_PRICE_ID=
STRIPE_PRO_AI_DRIFT_PRICE_ID=
STRIPE_PRO_AI_NLP_PRICE_ID=
STRIPE_PRO_RETENTION_PRICE_ID=

# CORS (temporary - update after frontend)
CORS_ORIGINS=["*"]

# Rate Limiting
RATE_LIMIT_PER_MINUTE=100
```

**Deploy**:
- **Preferred:** Push to GitHub — Railway auto-deploys on every push to `main`
- **Manual fallback:** `cd services/api-gateway && railway up`
- Wait 3-5 minutes for build

**Get Public URL**:
- Settings → Networking → "Generate Domain"
- Your URL: `prela-api-gateway-production.up.railway.app`
- **Save this URL**: `API_GATEWAY_URL=https://prela-api-gateway-production.up.railway.app`

**Verify Health**:
```bash
# Basic health
curl https://prela-api-gateway-production.up.railway.app/api/v1/health

# Readiness check
curl https://prela-api-gateway-production.up.railway.app/api/v1/ready
```

Expected: `{"status":"healthy"}` and `{"status":"ready"}`

**Configure Stripe Webhook**:
1. Go to Stripe Dashboard → Developers → Webhooks
2. Click "Add endpoint"
3. **Endpoint URL**: `https://prela-api-gateway-production.up.railway.app/api/v1/billing/webhook`
4. **Select events**:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Click "Add endpoint"
6. Copy the "Signing secret" (starts with `whsec_`)
7. Go back to Railway → API Gateway → Variables
8. Update `STRIPE_WEBHOOK_SECRET` with the new value

**✓ Checkpoint**: API Gateway deployed, health checks pass, Stripe webhook configured

---

## Part 4: Frontend Deployment (60 minutes)

### ☐ 4.1 Deploy Dashboard (30 min)

1. Click "+ New" → "GitHub Repo"
2. Select your `prela` repository

**Service Configuration**:
- **Service name**: `prela-dashboard`
- Go to "Settings"
- **Root Directory**: `frontend`
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run preview`

**Environment Variables**:

```bash
# Clerk Authentication
VITE_CLERK_PUBLISHABLE_KEY=pk_live_XXXXX

# API Gateway URL (from Part 3.3)
VITE_API_BASE_URL=https://prela-api-gateway-production.up.railway.app
```

**Deploy**:
- Wait 2-3 minutes for build

**Get Public URL**:
- Settings → Networking → "Generate Domain"
- Your URL: `prela-dashboard-production.up.railway.app`
- **Save this URL**: `DASHBOARD_URL=https://prela-dashboard-production.up.railway.app`

**Update CORS Settings**:

Go back to **Ingest Gateway** and **API Gateway**:
1. Click each service → "Variables"
2. Update `CORS_ORIGINS`:
   ```bash
   CORS_ORIGINS=["https://prela-dashboard-production.up.railway.app","https://dashboard.prela.dev"]
   ```
3. Services will auto-restart

**Update Clerk Allowed Origins**:
1. Go to Clerk Dashboard → Configure → Paths
2. Under "Allowed origins", add:
   - `https://prela-dashboard-production.up.railway.app`
   - `https://dashboard.prela.dev` (we'll add custom domain next)

**Test Dashboard**:
1. Open `https://prela-dashboard-production.up.railway.app`
2. Click "Sign Up"
3. Create test account
4. Verify you can login

**✓ Checkpoint**: Dashboard deployed, auth working

---

### ☐ 4.2 Deploy Marketing Website (30 min)

**Option 1: Railway** (if you want everything in one place)

**Important Pre-Deployment Steps:**

1. Navigate to `prela-website` directory and create `railway.json`:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm install && npm run build"
  },
  "deploy": {
    "startCommand": "npx vite preview --port $PORT --host 0.0.0.0",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

2. Update `vite.config.ts` to allow Railway hosts:

```typescript
preview: {
  host: "0.0.0.0",
  port: 8080,
  strictPort: false,
  allowedHosts: true, // Allow all hosts for Railway deployment
},
```

3. If `bun.lockb` exists, delete it (force npm usage):
```bash
cd prela-website
rm bun.lockb  # Railway will use npm with package-lock.json
```

**Deploy via Railway CLI:**

1. Navigate to prela-website directory:
```bash
cd /path/to/prela/prela-website
```

2. Link to Railway project:
```bash
railway link
# Select: prela-production project
# Select: Create new service
```

3. **Important**: In Railway dashboard, go to service Settings and **clear the Root Directory field** (leave it empty)

4. Deploy:
```bash
railway up
```

**Get Public URL**:
- Run `railway domain` or
- Settings → Networking → "Generate Domain"
- Your URL: `website-production-XXXX.up.railway.app`

**Option 2: Vercel/Netlify** (Recommended for static sites)

Better performance and easier custom domain setup for marketing sites.

**Vercel**:
1. Go to vercel.com
2. Import your `prela` repository
3. Configure:
   - **Root Directory**: `prela-website`
   - **Framework Preset**: Vite
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
4. Add environment variables (same as above)
5. Deploy

**✓ Checkpoint**: Marketing website deployed

---

## Part 5: Custom Domains Setup (30 minutes)

### ☐ 5.1 Configure DNS

Go to your DNS provider (e.g., Cloudflare, Namecheap) and add these records:

**Root Domain**:
```
Type: A
Name: @
Value: [Get from Vercel/Railway]
TTL: Auto

Type: CNAME
Name: www
Value: prela-website-production.up.railway.app (or Vercel URL)
TTL: Auto
```

**Dashboard Subdomain**:
```
Type: CNAME
Name: dashboard
Value: prela-dashboard-production.up.railway.app
TTL: Auto
```

**API Subdomain**:
```
Type: CNAME
Name: api
Value: prela-api-gateway-production.up.railway.app
TTL: Auto
```

**Ingest Subdomain**:
```
Type: CNAME
Name: ingest
Value: prela-ingest-gateway-production.up.railway.app
TTL: Auto
```

---

### ☐ 5.2 Add Custom Domains to Railway

**For each service**:

1. Click service → Settings → Networking
2. Click "Custom Domain"
3. Enter domain:
   - Dashboard: `dashboard.prela.dev`
   - API Gateway: `api.prela.dev`
   - Ingest Gateway: `ingest.prela.dev`
4. Railway will generate SSL certificate (5-10 minutes)

---

### ☐ 5.3 Update Environment Variables with Custom Domains

**Update Ingest Gateway and API Gateway**:
```bash
CORS_ORIGINS=["https://dashboard.prela.dev","https://prela.dev"]
```

**Update Dashboard**:
```bash
VITE_API_BASE_URL=https://api.prela.dev
```

**Update Clerk**:
1. Clerk Dashboard → Configure → Paths
2. Update allowed origins to include `https://dashboard.prela.dev`

**Update SDK Documentation** (sdk/README.md):
```python
prela.init(
    api_key="prela_sk_xxxxx",
    ingest_url="https://ingest.prela.dev"
)
```

**✓ Checkpoint**: Custom domains configured and SSL active

---

## Part 6: End-to-End Testing (30 minutes)

### ☐ 6.1 Test Trace Ingestion

**Create API Key**:

1. Login to dashboard: `https://dashboard.prela.dev`
2. Go to Settings → API Keys
3. Click "Generate New Key"
4. Copy the key (starts with `prela_sk_`)

**Send Test Trace**:

```bash
curl -X POST https://ingest.prela.dev/v1/traces \
  -H "Authorization: Bearer prela_sk_YOUR_KEY_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "trace_id": "test-trace-001",
    "service_name": "test-service",
    "started_at": "2026-02-02T10:00:00Z",
    "completed_at": "2026-02-02T10:00:01Z",
    "duration_ms": 1000,
    "status": "SUCCESS",
    "spans": [
      {
        "span_id": "span-001",
        "trace_id": "test-trace-001",
        "name": "test-operation",
        "span_type": "LLM",
        "started_at": "2026-02-02T10:00:00Z",
        "ended_at": "2026-02-02T10:00:01Z",
        "duration_ms": 1000,
        "status": "SUCCESS",
        "attributes": {
          "model": "claude-3-5-sonnet",
          "prompt_tokens": 100,
          "completion_tokens": 50
        }
      }
    ]
  }'
```

**Expected Response**:
```json
{
  "status": "accepted",
  "trace_id": "test-trace-001",
  "usage": {
    "current": 1,
    "limit": 100000
  }
}
```

**Verify in Dashboard**:
1. Refresh dashboard
2. You should see the trace appear
3. Click on it to view details

**✓ Checkpoint**: Trace successfully ingested and visible in dashboard

---

### ☐ 6.2 Test Data Pipeline (Simplified Architecture)

**⚠️ Note:** Kafka and Trace Service checks are skipped in simplified architecture

**Check ClickHouse (Direct Write)**:
```bash
curl 'https://YOUR_CLICKHOUSE_HOST:8443/?query=SELECT%20*%20FROM%20prela.traces%20WHERE%20trace_id%3D%27test-trace-001%27%20FORMAT%20JSON' \
  --user 'default:YOUR_PASSWORD'
```

You should get JSON response with your trace data.

**Check Ingest Gateway Logs** (Railway):
1. Go to Ingest Gateway → Logs
2. Look for:
   ```
   [INFO] Received batch: 1 traces
   [INFO] Writing directly to ClickHouse (Kafka bypassed)
   [INFO] Successfully wrote 1 traces to ClickHouse
   [INFO] Write latency: 45ms
   ```

**Check API Gateway** (Query the trace via REST API):
```bash
curl https://api.prela.dev/api/v1/traces/test-trace-001 \
  -H "Authorization: Bearer prela_sk_YOUR_KEY"
```

You should get the full trace with all spans.

**✓ Checkpoint**: Data flowing through simplified pipeline (Ingest → ClickHouse → API)

**Performance Notes:**
- Direct ClickHouse writes: 20-50ms latency
- No message queue delay
- Immediate consistency (no eventual consistency lag)

---

### ☐ 6.3 Test Billing Flow

**Test Subscription Upgrade**:
1. Login to dashboard
2. Go to "Billing" or "Upgrade" page
3. Click "Upgrade to Lunch Money"
4. Use Stripe test card: `4242 4242 4242 4242`
5. Any future date for expiry
6. Any 3 digits for CVC
7. Complete checkout

**Verify**:
1. Check Stripe Dashboard → Customers → You should see new customer
2. Check Stripe Dashboard → Subscriptions → Active subscription
3. In Railway → API Gateway → Logs → Look for webhook event
4. In dashboard → Your tier should show "Lunch Money"

**Check Database**:
```sql
SELECT * FROM subscriptions WHERE user_id = 'YOUR_USER_ID';
```

Should show `tier = 'lunch-money'` and `trace_limit = 100000`

**✓ Checkpoint**: Billing integration working

---

### ☐ 6.4 Test Authentication

**Test Invalid Auth**:
```bash
# No auth header
curl https://api.prela.dev/api/v1/traces
# Expected: 401 Unauthorized

# Invalid API key
curl -X POST https://ingest.prela.dev/v1/traces \
  -H "Authorization: Bearer invalid_key_12345"
# Expected: 401 Unauthorized with error message
```

**Test Valid Auth**:
```bash
# Should work with your real API key
curl https://api.prela.dev/api/v1/traces \
  -H "Authorization: Bearer prela_sk_YOUR_KEY"
# Expected: 200 with trace list
```

**✓ Checkpoint**: Authentication working correctly

---

## Part 7: Monitoring & Alerts (20 minutes)

### ☐ 7.1 Railway Alerts

For each service:
1. Click service → Settings → "Alerts"
2. Enable:
   - ☐ High CPU usage (>80%)
   - ☐ High memory usage (>80%)
   - ☐ Deployment failed
   - ☐ Service crashed
3. Add notification email

**✓ Checkpoint**: Alerts configured for all services

---

### ☐ 7.2 External Monitoring (Optional but Recommended)

**UptimeRobot** (Free):
1. Go to uptimerobot.com
2. Add monitors:
   - **Ingest Gateway**: https://ingest.prela.dev/health (every 5 min)
   - **API Gateway**: https://api.prela.dev/api/v1/health (every 5 min)
   - **Dashboard**: https://dashboard.prela.dev (every 5 min)

**Sentry** (Error Tracking) - Optional:
1. Create Sentry project for each service
2. Add Sentry DSN to environment variables
3. Capture errors and performance

**✓ Checkpoint**: External monitoring configured

---

## Part 7.5: New Features (Post-Launch)

The following features are integrated into the API Gateway and require no additional Railway services or environment variables. ClickHouse tables are created automatically on first API request.

### Guardrails

- **Route**: `/api/v1/guardrails` (registered in API Gateway)
- **ClickHouse tables**: `guardrail_configs`, `guardrail_violations` (auto-created)
- **No new env vars required**

### Alerting

- **Route**: `/api/v1/alerts` (registered in API Gateway)
- **ClickHouse tables**: `generic_alert_rules`, `alert_evaluations` (auto-created)
- **Background task**: `background_alert_evaluation_loop()` runs in API Gateway lifespan (every 5 min)
- **Notification channels configured per-rule**: Slack webhook URL, email addresses (requires SMTP), PagerDuty routing key

### Prompt Management

- **Route**: `/api/v1/prompts` (registered in API Gateway)
- **ClickHouse tables**: `prompt_templates` (auto-created)
- **No new env vars required**

### Drift Detection

- **Route**: `/api/v1/drift` (registered in API Gateway)
- **ClickHouse tables**: `agent_baselines`, `drift_alerts` (auto-created)
- **Background task**: drift detection loop runs in API Gateway lifespan

### Background Tasks

The API Gateway lifespan runs 4 background async tasks:

1. `data_source_sync` -- syncs external data sources
2. `security_scan` -- background security scanning
3. `drift_detection` -- detects agent behavior drift
4. `alert_evaluation` -- evaluates alert rules continuously

These run in-process. If the API Gateway restarts (Railway auto-restart), they resume automatically.

### Verification Checklist

After deploying the API Gateway with these features:

- [ ] `GET /api/v1/guardrails/projects/{id}/configs` returns 200
- [ ] `GET /api/v1/alerts/projects/{id}/rules` returns 200
- [ ] `GET /api/v1/prompts/projects/{id}/prompts` returns 200
- [ ] `GET /api/v1/drift/projects/{id}/baselines` returns 200
- [ ] API Gateway logs show "Starting background..." messages for all 4 tasks

### Self-Hosted ClickHouse (Alternative to Cloud)

ClickHouse Cloud can be replaced with a self-hosted instance for cost savings (~$200-335/mo saved). The p8-cluster runs ClickHouse via Docker, exposed through a Cloudflare Tunnel at `clickhouse.prela.dev`.

To switch Railway services to self-hosted ClickHouse:

```bash
CLICKHOUSE_HOST=clickhouse.prela.dev
CLICKHOUSE_PORT=443
CLICKHOUSE_SECURE=true
CLICKHOUSE_USER=prela_app
CLICKHOUSE_PASSWORD=<set in Railway>
CLICKHOUSE_DATABASE=prela
```

See `CLICKHOUSE_SELF_HOST_IMPLEMENTATION.md` for full setup details.

---

## Part 8: Final Checklist

### Pre-Launch Verification

- [ ] ClickHouse accessible and `prela` database exists
- [ ] Clerk application configured with correct allowed origins
- [ ] Stripe has all 8 products/prices created
- [ ] Stripe webhook configured and testing successfully
- [ ] Railway Postgres has all tables from migrations
- [ ] Railway Redis accessible
- [ ] Ingest Gateway health check returns 200
- [ ] API Gateway health check returns 200
- [ ] Dashboard loads and auth works
- [ ] Marketing website loads
- [ ] Custom domains configured with SSL
- [ ] CORS configured correctly for all domains
- [ ] Test trace successfully ingests
- [ ] Trace visible in dashboard
- [ ] Billing upgrade flow works
- [ ] Stripe webhooks firing correctly
- [ ] Monitoring and alerts configured

### Security Checklist

- [ ] All secrets stored in Railway variables (not in code)
- [ ] CORS restricted to specific domains (not "*")
- [ ] JWT secret is strong random string (32+ bytes)
- [ ] Stripe webhook secret configured
- [ ] Rate limiting enabled (1000/min ingest, 100/min API)
- [ ] Database credentials not exposed
- [ ] ClickHouse password is strong

### Cost Monitoring

- [ ] Railway usage tracked (check billing page)
- [ ] ClickHouse storage monitored (~$10-20/month after free trial)
- [ ] Upstash Kafka message count tracked (free tier: 10k/day)
- [ ] Stripe account in test mode initially
- [ ] Set up cost alerts if usage spikes

---

## Rollback Procedures

### Service Rollback

If a deployment fails:

1. Go to Railway → Click failing service
2. Click "Deployments" tab
3. Find last successful deployment (green checkmark)
4. Click "⋯" → "Redeploy"
5. Wait 2-3 minutes

### Database Rollback

If migration causes issues:

```bash
# Get the public URL first (see Part 2.4 above)
PUBLIC_DB="postgresql://postgres:<password>@switchyard.proxy.rlwy.net:<port>/railway"

# Connect interactively
psql "$PUBLIC_DB"

# Or run a one-off rollback command
psql "$PUBLIC_DB" -c "ALTER TABLE api_keys DROP COLUMN IF EXISTS team_id;"
```

Or restore from Railway automatic backup:
1. Railway → Postgres service → "Backups" tab
2. Select backup → "Restore"

### Emergency Procedures

If everything is broken:

1. **Pause all deployments**:
   - Each service → Settings → "Service" → Pause

2. **Display maintenance page**:
   - Update DNS to point to static maintenance page

3. **Notify users**:
   - Update status page
   - Post on Twitter/Discord
   - Email active users

4. **Investigate and fix**:
   - Check logs across all services
   - Verify external service status (ClickHouse, Clerk)
   - Rollback or hotfix

---

## Cost Breakdown

**Monthly Recurring Costs**:

| Service | Cost | Notes |
|---------|------|-------|
| Railway Postgres | $10 | Managed database |
| Railway Redis | $5 | Managed cache |
| Railway Ingest Gateway | $10-15 | 1 replica, ~512MB RAM |
| Railway API Gateway | $10-15 | 1 replica, ~512MB RAM |
| Railway Dashboard | $5-10 | Static/preview server |
| Railway Website | $0-5 | If on Vercel: free |
| **Railway Total** | **$50-75** | |
| | |
| ClickHouse | $0 | Self-hosted on p8 (or Cloud ~$10-20/mo) |
| Clerk | $0 | Free up to 10k MAU |
| Stripe | Variable | 2.9% + $0.30/transaction |
| **External Total** | **$0-30** | |
| | |
| **Grand Total** | **$50-105/month** | |

**Optimization Tips**:
- Use Railway Hobby plan ($5/service vs $10)
- Set ClickHouse TTL to 90 days (reduces storage)
- Self-host ClickHouse on p8 to eliminate Cloud costs (see CLICKHOUSE_SELF_HOST_IMPLEMENTATION.md)
- Combine frontend services if possible
- Monitor usage and scale down if over-provisioned

---

## Support Resources

**Railway**:
- Docs: https://docs.railway.app
- Discord: https://discord.gg/railway
- Status: https://status.railway.app

**ClickHouse**:
- Docs: https://clickhouse.com/docs
- Slack: https://clickhouse.com/slack

**Upstash**:
- Docs: https://upstash.com/docs/kafka
- Discord: https://upstash.com/discord

**Clerk**:
- Docs: https://clerk.com/docs
- Support: support@clerk.com

**Stripe**:
- Docs: https://stripe.com/docs
- Support: https://support.stripe.com

---

## Next Steps After Deployment

1. **Week 1**:
   - Monitor production metrics daily
   - Respond to early user feedback
   - Fix critical bugs
   - Optimize performance

2. **Month 1**:
   - Scale services based on load
   - Add usage analytics
   - Set up status page
   - Consider deploying Scout agent (after 100+ users)

3. **Months 2-3**:
   - Multi-region if needed
   - Add CDN for frontend
   - Optimize ClickHouse queries
   - Deploy remaining agents

4. **Switch to Production Stripe**:
   - When ready for real payments
   - Stripe Dashboard → Toggle "Live mode"
   - Update Railway env vars with live keys
   - Update webhook with live endpoint

---

## Congratulations! 🎉

Your Prela platform is now live at:
- **Dashboard**: https://dashboard.prela.dev
- **Website**: https://prela.dev
- **API**: https://api.prela.dev
- **Ingest**: https://ingest.prela.dev

You're ready to launch your SDK!
