'use client'

import { useActionState } from 'react'
import { updatePassword } from '@/app/actions/auth'

const inputClass =
  'w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]'

export default function ResetPasswordPage() {
  const [state, action, pending] = useActionState(updatePassword, {
    error: null,
  })

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8">
      <h2 className="text-xl font-semibold mb-2">Set a new password</h2>
      <p className="text-sm text-muted-foreground mb-6">
        Choose a strong password you don&apos;t use elsewhere.
      </p>

      <form action={action} className="space-y-4">
        <div className="space-y-1.5">
          <label htmlFor="password" className="text-sm text-muted-foreground">
            New password
          </label>
          <input
            id="password"
            name="password"
            type="password"
            required
            minLength={8}
            autoComplete="new-password"
            className={inputClass}
            placeholder="Min. 8 characters"
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="confirm" className="text-sm text-muted-foreground">
            Confirm password
          </label>
          <input
            id="confirm"
            name="confirm"
            type="password"
            required
            minLength={8}
            autoComplete="new-password"
            className={inputClass}
            placeholder="Re-enter password"
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
          {pending ? 'Updating…' : 'Update password'}
        </button>
      </form>
    </div>
  )
}
