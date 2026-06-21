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

## Known follow-up

- OAuth-created users default to the `founder` role (the `handle_new_user`
  trigger reads role from signup metadata, which OAuth doesn't provide). Add a
  first-login role-selection step if this matters.
