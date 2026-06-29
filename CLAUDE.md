@AGENTS.md

# Environment & local setup

All runtime config is via env vars — see `.env.example` for the full list
(`cp .env.example .env.local` and fill in). Required: the Supabase URL + anon
key, the server-only `SUPABASE_SERVICE_ROLE_KEY`, `NEXT_PUBLIC_SITE_URL`, and
VAPID keys for Web Push (`npx web-push generate-vapid-keys --json`).

These live outside the repo (your machine / Vercel / the Supabase dashboard) and
cannot be set from a CI sandbox. To complete the checklists below in a real
project:

1. Apply migrations in order (`supabase db push`, or paste each
   `supabase/migrations/000*.sql` into the SQL editor).
2. Configure Supabase Auth (providers, redirect URLs, TOTP) per the auth
   checklist.
3. Seed a test account:
   `node scripts/create-test-account.mjs --email you@test.dev --password 'Passw0rd!' --role founder --name "Test" [--admin]`
   (`--admin` flips `profiles.is_admin` so it can open `/admin`).

## Running a Claude Code web session against Supabase

The cloud sandbox starts with no secrets. To connect a web session to the real
project, add the env vars (`NEXT_PUBLIC_SUPABASE_URL`,
`NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
`NEXT_PUBLIC_SITE_URL`, and the VAPID keys) in the **environment configuration**
of Claude Code on the web (Environment Variables) — not pasted into chat. They
are injected at container start, so they only appear in a **new** session, not
one already running. Verify with:
`node -e "console.log(!!process.env.SUPABASE_SERVICE_ROLE_KEY)"` (expect `true`),
then seed an account and `npm run dev`. The sandbox can reach Supabase
(outbound HTTPS is allowed) but binds to its own localhost — there's no UI for a
human to view; drive/verify via curl. Real interactive use is `npm run dev` on
your own machine.

# Auth system setup checklist

Fundable uses Supabase Auth with email/password, Google + LinkedIn OAuth,
magic links, password reset, and TOTP MFA. The code is complete; the items
below are the manual, out-of-repo steps needed to make it work in each
environment. They are marked done — revisit only if auth misbehaves.

- [x] **Enable Google provider** — Supabase Dashboard → Authentication →
      Providers → Google: add OAuth client ID + secret.
- [x] **Enable LinkedIn provider** — Authentication → Providers → LinkedIn
      (OIDC): add client ID + secret. Code uses the `linkedin_oidc` provider.
- [x] **Configure redirect URLs** — Authentication → URL Configuration: set the
      Site URL and add `<site>/auth/callback` to the redirect allow-list (for
      local + production origins).
- [x] **Enable TOTP MFA** — Authentication → Multi-Factor → enable TOTP.
- [x] **Set `NEXT_PUBLIC_SITE_URL`** — point to the deployed origin so reset,
      magic-link, and OAuth emails link to the right host. Also set
      `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
- [x] **Verify the auth flows** — sign up, social login, magic link, password
      reset (`/forgot-password` → `/auth/reset`), and MFA enrollment
      (`/app/security`) + challenge (`/auth/mfa`).

## Auth architecture notes

- Route protection lives in `src/proxy.ts` (Next.js 16 renamed `middleware` →
  `proxy`; Node runtime).
- MFA is enforced in `src/app/app/layout.tsx` via an AAL (`aal1` → `aal2`)
  check; password login also redirects to `/auth/mfa` when a factor exists.
- Server actions for auth live in `src/app/actions/auth.ts`. `next` redirect
  targets are restricted to relative paths to avoid open redirects.

# Security hardening checklist

A platform security pass added these requirements. Marked done; revisit if
something breaks.

- [x] **Apply migration `0002_security_hardening.sql`** — version-controls
      `investment_offers`, `push_subscriptions`, added columns, and a private
      `message-media` bucket; enables RLS with owner-scoped policies; restricts
      unpublished startup drafts to their owner.
- [x] **Set `SUPABASE_SERVICE_ROLE_KEY`** (server-only secret) — push delivery
      (`src/lib/push/send.ts`) reads other users' subscriptions via the service
      role so `push_subscriptions` RLS can stay owner-only. Never expose this to
      the client.
- [x] **Verify CSP** — `next.config.ts` sets a Content-Security-Policy and
      related headers. If a third-party embed/script is added later, update
      `connect-src`/`script-src` accordingly.
- [x] **Chat media is private** — stored in the private `message-media` bucket
      and served via short-lived signed URLs; the DB stores the object path.

Notes: social links and redirect targets are validated server-side
(`src/lib/security/url.ts`); image uploads are MIME/size-checked
(`src/lib/security/upload.ts`); abuse-prone actions are rate-limited
(`src/lib/security/rate-limit.ts`, in-memory/best-effort — back with a durable
store for multi-instance deployments). Two moderate `npm audit` advisories
remain inside Next's bundled `postcss`; they clear only via a Next upgrade,
not a forced downgrade.

# Caching & CDN

Deployed on Vercel. We use the lightweight ("previous") caching model — NOT
Cache Components (`cacheComponents` stays off, since every `/app/*` route reads
auth cookies at request time).

- **Cached data:** the non-personalized feed lists (published startups, active
  investors + offers) live in `src/lib/data/feed.ts` behind `unstable_cache`
  (Vercel Data Cache), read via the cookieless service-role client. Per-user
  bits (auth, connection state, excluding yourself) stay uncached in the feed
  page. Lists also time-revalidate every 5 min.
- **Invalidation:** mutations in `src/app/actions/profile.ts` call
  `revalidateTag('startups' | 'investors' | 'offers', 'max')` (two-arg form is
  required in Next 16). On Vercel this purges the Data Cache automatically — no
  manual CDN purge needed.
- **Page HTML:** `/app/*` is dynamic (cookies) so it isn't CDN-cached; the win
  is avoiding a Supabase round-trip per request. Marketing/auth routes (`/`,
  `/signup`, `/forgot-password`, `/auth/*`) are static and CDN-cached by Vercel.
- **Assets:** `/_next/static` is already hashed + `immutable`; Vercel's CDN
  serves them, so no `assetPrefix` is configured.

If you later flip to a non-Vercel CDN, add an explicit CDN purge alongside the
`revalidateTag` calls (the tag invalidates Next's cache, not a 3rd-party CDN).

# Admin monitoring dashboard

`/admin` is a platform monitoring dashboard (product + operational metrics).

- **Access:** gated on `profiles.is_admin` (added in migration
  `0003_admin_monitoring.sql`). The `/admin` layout checks it server-side and
  redirects non-admins; `/admin` is also in `proxy.ts` protected prefixes. Grant
  access with: `update profiles set is_admin = true where id = '<uid>'`. A
  "Platform monitoring" link appears on the profile page for admins only.
- **Metrics:** computed in `src/lib/data/admin.ts` via the service-role client
  (after the is_admin gate), cached 60s (`unstable_cache`, tag `admin-metrics`).
  Stat cards + dependency-free SVG bar charts (`src/app/admin/bar-chart.tsx`).
  Time-series bucket raw rows in JS — fine now; move to SQL `date_trunc`/rollups
  at scale (noted in the file).
- **Operational events:** `app_events` table (server-only RLS) is written via
  `logEvent()` in `src/lib/monitoring/events.ts` (best-effort, never throws).
  Currently instrumented: push delivery failures. This is the seam for a real
  APM (Sentry/Vercel) later — swap the sink in `logEvent`, keep call sites.

## Known follow-up

- OAuth-created users default to the `founder` role (the `handle_new_user`
  trigger reads role from signup metadata, which OAuth doesn't provide). Add a
  first-login role-selection step if this matters.
