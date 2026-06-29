# Local setup — continue Fundable in a local Claude Code session

This is the handoff from the cloud session. The cloud environment's network
policy blocked outbound HTTPS to Supabase, so seeding/running against the live
DB has to happen somewhere with open network — your machine. All the code
(auth, security, caching, admin dashboard) is already done and committed on
branch `claude/fundable-repo-claude-md-jk1uz4`.

Follow these steps top to bottom. Should take ~10 minutes.

---

## 1. Get the code

```bash
git clone https://github.com/AMIRAK-code/fundable-mvp-t1.git
cd fundable-mvp-t1
git checkout claude/fundable-repo-claude-md-jk1uz4
git pull origin claude/fundable-repo-claude-md-jk1uz4
```

If you already have the repo cloned, just:

```bash
cd fundable-mvp-t1
git checkout claude/fundable-repo-claude-md-jk1uz4
git pull origin claude/fundable-repo-claude-md-jk1uz4
```

## 2. Install dependencies

```bash
npm install
```

> Node 20+ recommended (Next.js 16). Check with `node -v`.

## 3. Create `.env.local`

Copy the template and fill in real values. `.env.local` is gitignored — it
never gets committed.

```bash
cp .env.example .env.local
```

Then edit `.env.local`:

```dotenv
# Supabase — project ref kwthbutbsnyemssipnag
NEXT_PUBLIC_SUPABASE_URL=https://kwthbutbsnyemssipnag.supabase.co

# New-format Supabase keys (sb_publishable_… / sb_secret_…) work as drop-in
# values for these env vars.
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_…   # your full publishable key
SUPABASE_SERVICE_ROLE_KEY=sb_secret_…            # your secret key (server-only)

NEXT_PUBLIC_SITE_URL=http://localhost:3000

# VAPID (Web Push) — generate in the next step
VAPID_SUBJECT=mailto:amir.akbari@inrebus.it
NEXT_PUBLIC_VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY=
```

> ⚠️ **Rotate your secret key.** The `sb_secret_…` key was pasted into the
> cloud chat transcript. In Supabase → Settings → API Keys, roll the secret
> key and use the fresh value here.

## 4. Generate VAPID keys (Web Push)

```bash
npx web-push generate-vapid-keys --json
```

Paste `publicKey` → `NEXT_PUBLIC_VAPID_PUBLIC_KEY` and `privateKey` →
`VAPID_PRIVATE_KEY` in `.env.local`.

## 5. Apply database migrations

Migration `0001` is already applied to your project. Apply `0002` and `0003`
(both idempotent — safe to re-run). Easiest path: paste each file into the
Supabase SQL editor in order:

- `supabase/migrations/0002_security_hardening.sql`
- `supabase/migrations/0003_admin_monitoring.sql`

Or, if you have the Supabase CLI linked to the project:

```bash
supabase db push
```

## 6. Seed an admin test account

```bash
node scripts/create-test-account.mjs \
  --email you@test.dev --password 'Passw0rd!' \
  --role founder --name "Test Founder" --admin
```

`--admin` flips `profiles.is_admin = true` so the account can open `/admin`.
Re-running with an existing email is a harmless no-op error.

## 7. Run the app

```bash
npm run dev
```

Open http://localhost:3000 and verify:

- `/login` — sign in with the seeded email + password
- the feed (published startups / active investors)
- `/admin` — platform monitoring dashboard (admin-only)
- `/app/security` — MFA enrollment

## 8. (Optional) Supabase Auth dashboard config

For OAuth / magic links / password reset / MFA to fully work, set these in the
Supabase dashboard (see the checklist in `CLAUDE.md`):

- **URL Configuration** → Site URL = `http://localhost:3000`, add
  `http://localhost:3000/auth/callback` to the redirect allow-list.
- **Providers** → enable Google and LinkedIn (OIDC) with client id/secret.
- **Multi-Factor** → enable TOTP.

---

## Continuing with Claude Code locally

Start a local session with browser control:

```bash
claude --chrome
```

This lets the agent drive your browser (to click through the Supabase
dashboard, test auth flows, take screenshots, etc.).

### Connect the Supabase MCP server

The repo ships `.mcp.json` pointing at the Supabase MCP server for project
`kwthbutbsnyemssipnag`. In the local session, authenticate it:

```
/mcp
```

Follow the OAuth prompt for the `supabase` server. Once connected, the agent
can query/manage your Supabase project directly.

### A good first prompt for the local session

> Read CLAUDE.md and LOCAL_SETUP.md. My `.env.local` is filled in and
> migrations are applied. Seed an admin test account, run `npm run dev`, and
> verify auth, the feed, and `/admin` all work. Then let's keep building.

Everything is committed on `claude/fundable-repo-claude-md-jk1uz4`. The local
session will have open network access, so seeding and running against the live
DB will just work.
