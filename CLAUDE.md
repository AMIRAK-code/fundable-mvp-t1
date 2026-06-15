@AGENTS.md

# Fundable — Project Brief & Working Context

A mobile-first founder/investor matchmaking app. "Where Founders Meet Investors." Two-sided feed, opt-in connections, 1:1 realtime chat, web push notifications, PWA-installable on iOS and Android.

Production target: AAA polish — LinkedIn / Instagram-grade smoothness — while preserving the existing dark, minimal design DNA.

---

## Stack

- **Next.js 16.2.6** (App Router, Turbopack). `params`, `searchParams`, `cookies()` are async — `await` them. The "middleware" file convention is deprecated; this repo now uses `src/proxy.ts` with a named `proxy` export. **Read `node_modules/next/dist/docs/` before assuming any Next API** — this is not the Next.js you know.
- **React 19.2** — `useActionState`, `useOptimistic`, `useTransition` are available.
- **Tailwind v4** — `@import "tailwindcss"`, `@theme inline { ... }`, custom utilities via `@utility name { ... }`.
- **Base UI shadcn flavor** (`@base-ui/react` ^1.4.1). Composition via `render={<Component/>}` prop, NOT Radix's `asChild`. State attrs: `data-active`, `data-open`, `data-closed`.
- **Supabase** via `@supabase/ssr` ^0.10.3. SSR cookies, RLS, realtime, storage.
- **sonner** for toasts (`toast.success/error`) — `Toaster` mounted in `src/app/layout.tsx`.
- **web-push** for push notifications (VAPID).
- **lucide-react v1.x**. `Github`, `Linkedin`, `Instagram` icons DO NOT EXIST. Use `Code2`, `Link2`, `Camera`. Verify any new icon: `node -e "console.log(!!require('lucide-react').IconName)"`.

No new dependencies should be added without explicit user approval.

---

## Repo layout

```
src/
  app/
    layout.tsx               root (PWA metadata, dark hardcoded, fonts, Toaster)
    error.tsx / global-error.tsx / not-found.tsx
    page.tsx                 landing
    (auth)/layout.tsx
      login/page.tsx         useSearchParams wrapped in Suspense
      signup/page.tsx
    auth/callback/route.ts   Supabase OAuth/email callback
    onboarding/page.tsx + onboarding-form.tsx
    app/                     auth-gated shell (redirects to /login or /onboarding)
      layout.tsx             PushInit + main + BottomNav
      feed/
        page.tsx feed-header.tsx founder-card.tsx investor-card.tsx
        connect-button.tsx loading.tsx
      messages/
        page.tsx loading.tsx
        [roomId]/page.tsx chat-view.tsx loading.tsx
      profile/
        page.tsx founder-profile.tsx investor-profile.tsx
        investor-form.tsx investor-offers.tsx logout-button.tsx
        startup-dialog.tsx offer-dialog.tsx edit-profile.tsx
        confirm-delete-button.tsx loading.tsx
      requests/
        page.tsx request-row.tsx loading.tsx
    actions/                 'use server' files
      auth.ts connect.ts profile.ts push.ts requests.ts
  components/
    bottom-nav.tsx nav-badges.tsx push-init.tsx
    skeleton.tsx empty-state.tsx
    ui/                      Base UI shadcn primitives
  lib/
    supabase/{client,server,types}.ts
    push/send.ts
    time.ts                  timeAgo, timeOfDay, dayLabel, sameDay
    utils.ts                 cn()
  proxy.ts                   Next 16 proxy (replaces middleware.ts)
public/
  manifest.json sw.js
  icons/icon-{192,512}{,-maskable}.png  apple-touch-icon.png  icon.png
supabase/migrations/
  0001_fundable_schema.sql   initial
  0002_status_markers.sql    startups.status + investor_details.status
  0003_read_receipts.sql     message_reads + RPCs (MUST RUN — see below)
```

---

## Database

### Tables

- **profiles** (id refs auth.users, role 'founder'|'investor', full_name, avatar_url, bio, created_at)
- **startups** (id, founder_id, name, pitch, hero_image_url, industry, status, published bool, links jsonb, created_at)
- **investor_details** (id, investor_id UNIQUE, firm_name, check_size, sectors text[], thesis, status, created_at)
- **investment_offers** (id, investor_id, title, description, amount, stage, sectors text[], status 'active'|'closed', links jsonb, created_at)
- **connections** (id, sender_id, receiver_id, status 'pending'|'accepted'|'declined', UNIQUE(sender_id,receiver_id))
- **chat_rooms** (id, connection_id UNIQUE) — auto-created by trigger when a connection flips to 'accepted'
- **messages** (id, chat_room_id, sender_id, content, message_type 'text'|'image', media_url, created_at)
- **push_subscriptions** (user_id, endpoint, p256dh, auth, UNIQUE(user_id, endpoint))
- **message_reads** (chat_room_id, user_id, last_read_at) — PK on (room, user) — added in 0003

### Migrations applied vs. authored

The live DB is **ahead** of the SQL migration files. The following are in the live DB but were applied via the Supabase dashboard, not committed migrations: `investment_offers`, `push_subscriptions`, `startups.published`, `startups.links`, `messages.message_type`, `messages.media_url`, the `message-media` storage bucket, and the realtime publication for `messages`. A fresh DB built from `supabase/migrations/` alone would CRASH the app.

### Status enums (CHECK constraints, not Postgres enums)

```
StartupStatus  = idea | pre_seed | mvp | pre_launch | launched | scaling | profitable
InvestorStatus = looking | reviewing | invested | advisory | closed
```

Label and Tailwind-color maps exported from `src/lib/supabase/types.ts`:
`STARTUP_STATUS_LABELS`, `STARTUP_STATUS_COLORS`, `INVESTOR_STATUS_LABELS`, `INVESTOR_STATUS_COLORS`.

### RPC functions (migration 0003)

- `get_unread_counts()` → `[{ chat_room_id, unread_count }]`
- `get_conversation_overview()` → `[{ chat_room_id, last_content, last_type, last_sender_id, last_at, unread_count }]` — used by conversation list to avoid the previous fetch-ALL-messages pattern
- `get_push_targets(target uuid)` → `[{ endpoint, p256dh, auth }]` — security definer. **Fixes cross-user push delivery** (RLS made the direct SELECT return zero rows for other users; pushes silently never fired).

### RLS facts that constrain features

- Senders CANNOT update or delete connections they sent. Receivers update status. No one can delete.
- `connections` unique on `(sender_id, receiver_id)` — a declined sender cannot re-send (would unique-violate). Treat declined as terminal in UI.
- `messages` is append-only (no UPDATE/DELETE policies). No edits, no soft-delete.
- `chat_rooms` only created by the security-definer trigger — direct inserts will fail.
- All storage buckets are public-read. Chat images are world-readable by URL — privacy caveat for DMs.

---

## Auth and routing

- Middleware → `src/proxy.ts` (named export `proxy`, function name confirmed against Next 16 bundled docs).
- Matcher excludes `_next/static`, `_next/image`, `favicon.ico`, `sw.js`, `manifest.json`, icons/, image extensions. Auth/api paths run; static/PWA assets skip the Supabase round-trip.
- Auth gate in `src/app/app/layout.tsx`: `!user` → `/login`; `!profile.full_name` → `/onboarding`.
- Signup metadata (`raw_user_meta_data.role`, `.full_name`) is consumed by the `handle_new_user` trigger to seed `profiles`.
- Email callback at `/auth/callback` → on failure redirects to `/login?error=auth_error`. Login page surfaces this banner (read via `useSearchParams` inside a `<Suspense>` boundary).

---

## Design DNA

Tokens in `src/app/globals.css`:

- Brand: `--brand-primary` `#3b82f6` (Electric Blue) · `--brand-success` `#10b981` (Emerald)
- Dark-mode only. The `dark` class is hardcoded on `<html>` — there is no `next-themes` provider.

Recurring class recipes:

- Card surface: `rounded-2xl border border-white/10 bg-white/5`
- Dialog panel: `bg-slate-900 border border-white/10`
- Input: `w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]`
- Primary CTA: `rounded-xl bg-[var(--brand-primary)] text-white text-sm font-semibold hover:opacity-90 disabled:opacity-50`
- Pill / chip: `px-2.5 py-0.5 rounded-full text-[10px] font-semibold uppercase tracking-wider`
- Page column: `max-w-lg mx-auto`

Custom utilities (Tailwind v4 `@utility`):

- `pb-safe` / `pt-safe` / `h-safe-screen` / `min-h-safe-screen` — iOS notch/home-indicator
- `press` / `press-subtle` — tactile scale-down on `:active`
- `skeleton` — shimmer background
- `animate-in-up` — fade-up entrance
- `animate-pop` — springy pop (badges, sent messages, status changes)
- `no-scrollbar` — for chip rows
- `stagger-children` — 40ms delay steps for child `animate-in-up`
- Reduced-motion media query disables animations globally

Mobile rules:

- `input/textarea/select` font-size forced to 16px ≤640px (prevents iOS auto-zoom-on-focus)
- `touch-action: manipulation` on buttons/links (removes 300ms tap delay)
- `viewportFit: 'cover'` + `themeColor: '#0a0a0a'` in root `viewport` export
- `overscroll-behavior-y: none` on body

PWA assets:

- `public/manifest.json`, `apple-touch-icon.png`, `icons/icon-{192,512}{,-maskable}.png`. Wired via Next 16 Metadata API (`metadata.manifest`, `metadata.appleWebApp`, `metadata.icons`) in `src/app/layout.tsx`.
- Service worker `public/sw.js` handles `push` and `notificationclick`. Uses `tag` (the url) + `renotify: true` so notifications collapse per conversation.

---

## Patterns and conventions

### Code style

- 2-space indent, single quotes, no semicolons by default, trailing commas, kebab-case for files.
- TypeScript everywhere. The `Database` generic in `src/lib/supabase/types.ts` exists but is NOT currently applied to `createBrowserClient` / `createServerClient` — clients are loosely typed. Adding the generic is a future tightening pass.

### Server Actions

All under `src/app/actions/`. Convention:

- Form-driven actions take `(prevState, formData) → Promise<{ error, success? }>` and are consumed via `useActionState`.
- Imperative actions take direct args and return `{ error: string | null }`.
- A `str(formData, key, max)` helper in `profile.ts` does null-guarded, trimmed, length-capped string reads.

### Optimistic UI everywhere

- `ConnectButton`: flips to "Pending" instantly, reverts on `{ error }` + `toast.error`; `toast.success('Request sent')` on success.
- `RequestRow`: Accept morphs row into accepted state with a Message CTA; Decline fades out. Reverts + toast on error.
- Chat send: client-generated `crypto.randomUUID()`, append local message with status `sending`, insert with that id, mark `sent` / `failed`. Realtime dedupe by id.

### Realtime

- Channel naming: `room-${roomId}` for chat, `'nav-badges'` (or similar) for nav refresh.
- Subscription teardown: always call `supabase.removeChannel(channel)` on cleanup.
- Reconnect: pass a status callback to `.subscribe((status) => ...)`. On re-subscribe, refetch latest and merge-dedupe by id.

### Loading states

Every route has a `loading.tsx` skeleton mirroring the real page layout (sticky header, list rows, message bubbles). Skeletons use `Skeleton` / `SkeletonText` / `SkeletonAvatar` + `stagger-children` + `animate-in-up`. The bottom-nav padding `pb-[calc(64px+env(safe-area-inset-bottom)+8px)]` MUST be preserved on the main content wrapper or content gets hidden under the nav.

### Bottom navigation

`src/components/bottom-nav.tsx` + `src/components/nav-badges.tsx`. Live numeric badges:

- Requests: count of pending incoming connections
- Messages: sum of `unread_count` from `get_unread_counts()`
- Refresh on pathname change, window focus, document visibility, and realtime INSERT/UPDATE on `connections`/`messages` (debounced 500ms).
- Badge pill: `bg-[var(--brand-primary)] text-white text-[9px] font-bold min-w-[16px] h-4 px-1 rounded-full`, caps at "9+", `animate-pop` on change.

### A11y baseline

- Every icon-only button has `aria-label`.
- Expand toggles are `role='button' tabIndex={0} aria-expanded` with Enter/Space keydown handling.
- Dialogs: `role='dialog' aria-modal='true' aria-labelledby` + body scroll lock + Escape closes.
- Message list: `role='log' aria-live='polite'`.

### Expandable cards

Use the grid-rows trick, NOT max-height (which clips):

```tsx
<div className={`grid transition-[grid-template-rows] duration-300 ease-in-out ${expanded ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'}`}>
  <div className="overflow-hidden min-h-0">...</div>
</div>
```

### Dialog reset pattern

Returning `if (!open) return null` from the dialog wrapper unmounts the inner form, so `useActionState` naturally resets on the next open. Do NOT use the `setState-in-effect` pattern to bump a key counter — eslint plugin `react-hooks/set-state-in-effect` flags it as a cascading-render anti-pattern.

---

## Recent session work — AAA upgrade

Status: implementation is ~80% complete; build passes; remaining items below.

### Shipped (this session)

- **PWA installability**: manifest, icons, Apple meta tags, security headers, sw.js update-policy.
- **CSS animation/polish system**: press, animate-in-up, animate-pop, skeleton, stagger-children, no-scrollbar, reduced-motion override.
- **Shared utilities**: `lib/time.ts` (timeAgo/timeOfDay/dayLabel/sameDay), `components/skeleton.tsx`, `components/empty-state.tsx`.
- **Error / not-found / global-error pages**.
- **Migration 0003**: read receipts table, `get_unread_counts`, `get_conversation_overview`, `get_push_targets` (security-definer fix for broken cross-user push delivery), realtime publication enable, secondary indexes.
- **Status markers** (founders + investors) with color-coded pills on feed cards, chat header expandable panel, own profile.
- **Feed**: optimistic ConnectButton, search (?q=), founder stage filter (?stage=), instant tab switch via useOptimistic, parallel queries, .limit(40), priority on first hero image, EmptyState empty/no-results variants, animate-in-up + stagger.
- **Cards**: grid-rows expansion trick, keyboard-accessible expand, press-subtle, animate-in-up.
- **Bottom nav**: live numeric badges (requests + messages) with realtime + focus/visibility refetch, animate-pop on change. Old `unread-dot.tsx` deleted.
- **Middleware → proxy.ts** with narrowed matcher.
- **Loading skeletons** for feed, messages, messages/[roomId], profile, requests.
- **Push delivery fix** via `get_push_targets` RPC (was silently broken under RLS).
- **Conversation list** rewritten to use `get_conversation_overview` (unbounded fetch eliminated), with unread pills and bold-unread names.
- **Chat view**: optimistic send + status ticks (Clock/Check/AlertCircle "Tap to retry"), day separators, message grouping, smart scroll + scroll-to-bottom FAB, typing indicator via broadcast, mark-read on visibility, reconnect resilience, linkify bug fix.
- **Dialogs**: Escape closes, body scroll lock, ARIA, animate-in-up entrance, two-tap delete confirms in profile rows.
- **Edit profile dialog**: avatar+name+bio editing from `/app/profile`.
- **Forms hardened**: null-guarded formData reads, length-capped inputs, toast feedback for all save/delete/publish actions, avatar cache-busting via `?v=` timestamp.
- **Auth pages**: login surfaces `?error=auth_error` callback errors (inside Suspense), autoComplete attributes, pending spinners.
- **Memory leak fixes**: `URL.createObjectURL` previews revoked on replace + unmount in onboarding-form, startup-dialog, edit-profile.
- **Lint cleanup**: replaced `setState-in-effect` patterns in dialog files with mount/unmount-based resets.

### Pending (next session priority order)

1. **User must run `supabase/migrations/0003_read_receipts.sql`** in Supabase SQL Editor before deploy. Until then: unread counts return empty, conversation list breaks, push delivery to recipients is broken.
2. **Adversarial review pass** — not yet executed. Spawn a Workflow with multiple parallel reviewers verifying: chat optimistic-send dedup correctness, nav-badges realtime cleanup, dialog accessibility, no broken imports, no silent error paths.
3. **Final lint sweep** — last build had a few `react-hooks/set-state-in-effect` and one `react/no-unescaped-entities` in `src/app/onboarding/page.tsx`. Some may already be fixed; rerun `npx eslint src`.
4. **Verify proxy.ts deprecation warning is gone** at build time. If Next 16.2.6 still warns, double-check the named export shape against `node_modules/next/dist/docs/`.
5. **Commit + push to `mobile` branch** (work has not been committed since the AAA upgrade started).
6. **Smoke test on a phone** via the Vercel preview deploy.

### Known risks / caveats

- Two of four implementation agents (`impl:chat`, `impl:profile`) hit session-limit mid-run during the parallel workflow. Their work was partially completed; some tasks were resumed by the user's intentional follow-up edits (visible in `startup-dialog.tsx`, `investor-form.tsx`, `founder-card.tsx`, `chat-view.tsx`, `messages/[roomId]/page.tsx`, `founder-profile.tsx`, `investor-card.tsx`).
- `realtime postgres_changes` requires the messages/connections tables to be in the `supabase_realtime` publication. Migration 0003 enables it idempotently, but until 0003 runs, nav badges and chat realtime degrade to focus/visibility refetches.
- `declined` connection status renders as terminal "Unavailable" for both directions (the card only receives status, not isSender). Matches the "treat declined as terminal" RLS contract but a receiver-side decliner also sees Unavailable.
- Multiple lockfiles warning at build time (root `package-lock.json` competing with `fundable/package-lock.json`). To silence: set `turbopack.root` in `next.config.ts` or remove the root lockfile.
- Supabase clients are still loosely typed — `Database` generic is not applied. Future tightening pass.
- Status enums are CHECK-constraint text, not Postgres enums. `supabase gen types` output would not match the hand-written `types.ts`.

---

## Working preferences

- Mobile-first dark UI only. No light mode requested.
- Keep dialogs hand-rolled (do NOT swap to Radix/shadcn Dialog primitive). Preserve the slate-900 panel style.
- Optimistic everywhere. Silent failures are unacceptable — every async action gives instant feedback + toast on error.
- Preserve scroll position across navigations. `revalidatePath` only when content actually changed.
- Two-tap confirms for destructive actions, never `window.confirm`.
- Keep code style consistent: no semicolons, single quotes, 2-space indent, no comments unless capturing non-obvious WHY.
- Push to the `mobile` branch by default (not `main`).
- `.claude/settings.local.json` allows Bash + PowerShell without prompt for this project.

---

## Commands

```
npx next dev               # dev server
npx next build             # production build (run after major changes)
npx next lint              # ESLint
node -e "console.log(!!require('lucide-react').IconName)"   # verify lucide icon exists
```

Git: working branch is `mobile`. Main has the pre-AAA-upgrade state. PR open URL: `https://github.com/AMIRAK-code/fundable-mvp-t1/compare/main...mobile`.

---

## When picking up next session

1. Run `git status` and `git diff --stat` to see uncommitted work.
2. Run `npx next build` to confirm the build is still green.
3. Run `npx eslint src` to spot any lint regressions.
4. Read the "Pending" section above for priority order.
5. If migration 0003 hasn't been applied yet, that is the single highest-leverage step — the app's chat unread counts and push delivery to recipients depend on it.
