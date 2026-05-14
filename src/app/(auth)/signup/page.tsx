'use client'

import { useActionState, useState } from 'react'
import Link from 'next/link'
import { Building2, TrendingUp } from 'lucide-react'
import { signup } from '@/app/actions/auth'
import type { Role } from '@/lib/supabase/types'

const ROLES: { value: Role; label: string; tagline: string; icon: React.ReactNode }[] = [
  {
    value: 'founder',
    label: 'Founder',
    tagline: 'Raise capital & grow',
    icon: <Building2 className="w-5 h-5" />,
  },
  {
    value: 'investor',
    label: 'Investor',
    tagline: 'Discover & fund deals',
    icon: <TrendingUp className="w-5 h-5" />,
  },
]

export default function SignupPage() {
  const [role, setRole] = useState<Role>('founder')
  const [state, action, pending] = useActionState(signup, { error: null })

  if (state.emailSent) {
    return (
      <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8 text-center space-y-4">
        <div className="text-4xl">📬</div>
        <h2 className="text-xl font-semibold">Check your email</h2>
        <p className="text-muted-foreground text-sm">
          We sent a confirmation link. Click it to activate your account.
        </p>
        <Link
          href="/login"
          className="inline-block text-sm text-[var(--brand-primary)] hover:underline"
        >
          Back to sign in
        </Link>
      </div>
    )
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8">
      <h2 className="text-xl font-semibold mb-6">Create your account</h2>

      {/* Role selector */}
      <div className="grid grid-cols-2 gap-3 mb-6">
        {ROLES.map((r) => (
          <button
            key={r.value}
            type="button"
            onClick={() => setRole(r.value)}
            className={[
              'flex flex-col items-center gap-2 rounded-xl border p-4 text-center transition-all',
              role === r.value
                ? 'border-[var(--brand-primary)] bg-[var(--brand-primary)]/10 text-foreground'
                : 'border-white/10 bg-white/5 text-muted-foreground hover:border-white/20',
            ].join(' ')}
          >
            <span
              className={
                role === r.value ? 'text-[var(--brand-primary)]' : 'text-muted-foreground'
              }
            >
              {r.icon}
            </span>
            <span className="text-sm font-semibold">{r.label}</span>
            <span className="text-xs">{r.tagline}</span>
          </button>
        ))}
      </div>

      <form action={action} className="space-y-4">
        {/* Pass selected role as hidden field */}
        <input type="hidden" name="role" value={role} />

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
            minLength={8}
            autoComplete="new-password"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            placeholder="Min. 8 characters"
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
          {pending ? 'Creating account…' : `Join as ${role === 'founder' ? 'Founder' : 'Investor'}`}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-muted-foreground">
        Already have an account?{' '}
        <Link href="/login" className="text-[var(--brand-primary)] hover:underline">
          Sign in
        </Link>
      </p>
    </div>
  )
}
