'use client'

import { Suspense, useActionState } from 'react'
import Link from 'next/link'
import { useSearchParams } from 'next/navigation'
import { login } from '@/app/actions/auth'

function CallbackErrorBanner() {
  const searchParams = useSearchParams()
  if (searchParams.get('error') !== 'auth_error') return null
  return (
    <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5 mb-4 animate-in-up">
      Sign-in link expired or invalid — try again.
    </p>
  )
}

export default function LoginPage() {
  const [state, action, pending] = useActionState(login, { error: null })

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8">
      <h2 className="text-xl font-semibold mb-6">Sign in to your account</h2>

      <Suspense fallback={null}>
        <CallbackErrorBanner />
      </Suspense>

      <form action={action} className="space-y-4">
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
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            placeholder="you@example.com"
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="password" className="text-sm text-muted-foreground">
            Password
          </label>
          <input
            id="password"
            name="password"
            type="password"
            required
            autoComplete="current-password"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            placeholder="••••••••"
          />
        </div>

        {state.error && (
          <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5">
            {state.error}
          </p>
        )}

        <button
          type="submit"
          disabled={pending}
          className="w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
        >
          {pending ? 'Signing in…' : 'Sign In'}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-muted-foreground">
        No account?{' '}
        <Link href="/signup" className="text-[var(--brand-primary)] hover:underline">
          Sign up
        </Link>
      </p>
    </div>
  )
}
