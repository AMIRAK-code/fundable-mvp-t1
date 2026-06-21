@AGENTS.md

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

## Known follow-up

- OAuth-created users default to the `founder` role (the `handle_new_user`
  trigger reads role from signup metadata, which OAuth doesn't provide). Add a
  first-login role-selection step if this matters.
