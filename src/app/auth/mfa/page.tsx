'use client'

import { Suspense, useEffect, useState } from 'react'
import { useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

function MfaChallenge() {
  const searchParams = useSearchParams()
  const rawNext = searchParams.get('next') ?? '/app/feed'
  const next =
    rawNext.startsWith('/') && !rawNext.startsWith('//') ? rawNext : '/app/feed'

  const [factorId, setFactorId] = useState<string | null>(null)
  const [code, setCode] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [ready, setReady] = useState(false)

  useEffect(() => {
    const supabase = createClient()
    supabase.auth.mfa.listFactors().then(({ data, error }) => {
      if (error) {
        setError(error.message)
      } else {
        const totp = data?.totp?.[0]
        if (totp) setFactorId(totp.id)
        else setError('No authenticator app is set up for this account.')
      }
      setReady(true)
    })
  }, [])

  async function verify(e: React.FormEvent) {
    e.preventDefault()
    if (!factorId) return
    setError(null)
    setLoading(true)

    const supabase = createClient()
    const { error } = await supabase.auth.mfa.challengeAndVerify({
      factorId,
      code: code.trim(),
    })

    if (error) {
      setError(error.message)
      setLoading(false)
      return
    }

    // Full navigation so the server (proxy + layout) sees the upgraded aal2 session.
    window.location.assign(next)
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8">
      <h2 className="text-xl font-semibold mb-2">Two-factor authentication</h2>
      <p className="text-sm text-muted-foreground mb-6">
        Enter the 6-digit code from your authenticator app.
      </p>

      <form onSubmit={verify} className="space-y-4">
        <input
          name="code"
          inputMode="numeric"
          autoComplete="one-time-code"
          pattern="[0-9]*"
          maxLength={6}
          required
          autoFocus
          value={code}
          onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
          disabled={!factorId || !ready}
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-center text-lg tracking-[0.5em] font-mono text-foreground placeholder:tracking-normal placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
          placeholder="000000"
        />

        {error && (
          <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={loading || !factorId || code.length < 6}
          className="w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
        >
          {loading ? 'Verifying…' : 'Verify'}
        </button>
      </form>
    </div>
  )
}

export default function MfaPage() {
  return (
    <Suspense
      fallback={
        <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8 text-center text-sm text-muted-foreground">
          Loading…
        </div>
      }
    >
      <MfaChallenge />
    </Suspense>
  )
}
