'use client'

import { useActionState, useState } from 'react'
import Link from 'next/link'
import { login, sendMagicLink } from '@/app/actions/auth'

const inputClass =
  'w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]'

export default function LoginForm({ next }: { next: string }) {
  const [mode, setMode] = useState<'password' | 'magic'>('password')
  const [loginState, loginAction, loginPending] = useActionState(login, {
    error: null,
  })
  const [magicState, magicAction, magicPending] = useActionState(sendMagicLink, {
    error: null,
  })

  if (magicState.sent) {
    return (
      <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8 text-center space-y-4">
        <div className="text-4xl">✉️</div>
        <h2 className="text-xl font-semibold">Check your email</h2>
        <p className="text-muted-foreground text-sm">
          We sent a one-time sign-in link. Open it on this device to continue.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-5">
      {/* Mode toggle */}
      <div className="grid grid-cols-2 gap-1 rounded-xl border border-white/10 bg-white/5 p-1">
        {(['password', 'magic'] as const).map((m) => (
          <button
            key={m}
            type="button"
            onClick={() => setMode(m)}
            className={[
              'rounded-lg py-1.5 text-sm font-medium transition-colors',
              mode === m
                ? 'bg-[var(--brand-primary)] text-white'
                : 'text-muted-foreground hover:text-foreground',
            ].join(' ')}
          >
            {m === 'password' ? 'Password' : 'Magic link'}
          </button>
        ))}
      </div>

      {mode === 'password' ? (
        <form action={loginAction} className="space-y-4">
          <input type="hidden" name="next" value={next} />
          <div className="space-y-1.5">
            <label htmlFor="email" className="text-sm text-muted-foreground">
              Email
            </label>
            <input
              id="email"
              name="email"
              type="email"
              required
              autoComplete="email"
              className={inputClass}
              placeholder="you@example.com"
            />
          </div>

          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <label htmlFor="password" className="text-sm text-muted-foreground">
                Password
              </label>
              <Link
                href="/forgot-password"
                className="text-xs text-[var(--brand-primary)] hover:underline"
              >
                Forgot password?
              </Link>
            </div>
            <input
              id="password"
              name="password"
              type="password"
              required
              autoComplete="current-password"
              className={inputClass}
              placeholder="••••••••"
            />
          </div>

          {loginState.error && (
            <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5">
              {loginState.error}
            </p>
          )}

          <button
            type="submit"
            disabled={loginPending}
            className="w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
          >
            {loginPending ? 'Signing in…' : 'Sign In'}
          </button>
        </form>
      ) : (
        <form action={magicAction} className="space-y-4">
          <input type="hidden" name="next" value={next} />
          <div className="space-y-1.5">
            <label htmlFor="magic-email" className="text-sm text-muted-foreground">
              Email
            </label>
            <input
              id="magic-email"
              name="email"
              type="email"
              required
              autoComplete="email"
              className={inputClass}
              placeholder="you@example.com"
            />
          </div>

          {magicState.error && (
            <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5">
              {magicState.error}
            </p>
          )}

          <button
            type="submit"
            disabled={magicPending}
            className="w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
          >
            {magicPending ? 'Sending link…' : 'Email me a sign-in link'}
          </button>
        </form>
      )}
    </div>
  )
}
