'use client'

import { useEffect, useState } from 'react'
import { ShieldCheck, Trash2 } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

type Factor = { id: string; friendly_name?: string; created_at: string }
type Enrollment = { factorId: string; qrCode: string; secret: string }

export default function MfaManager() {
  const [factors, setFactors] = useState<Factor[]>([])
  const [loading, setLoading] = useState(true)
  const [enrollment, setEnrollment] = useState<Enrollment | null>(null)
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function refresh() {
    const supabase = createClient()
    const { data, error } = await supabase.auth.mfa.listFactors()
    if (error) setError(error.message)
    else setFactors((data?.totp ?? []) as Factor[])
    setLoading(false)
  }

  useEffect(() => {
    let active = true
    createClient()
      .auth.mfa.listFactors()
      .then(({ data, error }) => {
        if (!active) return
        if (error) setError(error.message)
        else setFactors((data?.totp ?? []) as Factor[])
        setLoading(false)
      })
    return () => {
      active = false
    }
  }, [])

  async function startEnroll() {
    setError(null)
    setBusy(true)
    const supabase = createClient()
    const { data, error } = await supabase.auth.mfa.enroll({
      factorType: 'totp',
      friendlyName: `Authenticator ${new Date().toLocaleDateString()}`,
    })
    setBusy(false)
    if (error) {
      setError(error.message)
      return
    }
    setEnrollment({
      factorId: data.id,
      qrCode: data.totp.qr_code,
      secret: data.totp.secret,
    })
  }

  async function confirmEnroll(e: React.FormEvent) {
    e.preventDefault()
    if (!enrollment) return
    setError(null)
    setBusy(true)
    const supabase = createClient()
    const { error } = await supabase.auth.mfa.challengeAndVerify({
      factorId: enrollment.factorId,
      code: code.trim(),
    })
    setBusy(false)
    if (error) {
      setError(error.message)
      return
    }
    setEnrollment(null)
    setCode('')
    await refresh()
  }

  async function cancelEnroll() {
    if (enrollment) {
      const supabase = createClient()
      // Remove the half-finished (unverified) factor so it doesn't linger.
      await supabase.auth.mfa.unenroll({ factorId: enrollment.factorId })
    }
    setEnrollment(null)
    setCode('')
    setError(null)
  }

  async function remove(factorId: string) {
    setError(null)
    setBusy(true)
    const supabase = createClient()
    const { error } = await supabase.auth.mfa.unenroll({ factorId })
    setBusy(false)
    if (error) {
      setError(error.message)
      return
    }
    await refresh()
  }

  if (loading) {
    return <p className="text-sm text-muted-foreground">Loading…</p>
  }

  return (
    <div className="space-y-4">
      {error && (
        <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5">
          {error}
        </p>
      )}

      {/* Existing factors */}
      {factors.length > 0 && (
        <ul className="space-y-2">
          {factors.map((f) => (
            <li
              key={f.id}
              className="flex items-center justify-between rounded-xl border border-white/10 bg-white/5 px-4 py-3"
            >
              <div className="flex items-center gap-3">
                <ShieldCheck className="w-5 h-5 text-[var(--brand-primary)]" />
                <div>
                  <p className="text-sm font-medium">
                    {f.friendly_name || 'Authenticator app'}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Added {new Date(f.created_at).toLocaleDateString()}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => remove(f.id)}
                disabled={busy}
                className="flex items-center gap-1 text-xs text-destructive hover:underline disabled:opacity-50"
              >
                <Trash2 className="w-4 h-4" />
                Remove
              </button>
            </li>
          ))}
        </ul>
      )}

      {/* Enrollment flow */}
      {enrollment ? (
        <div className="rounded-xl border border-white/10 bg-white/5 p-5 space-y-4">
          <p className="text-sm text-muted-foreground">
            Scan this QR code with your authenticator app, then enter the
            6-digit code to confirm.
          </p>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={enrollment.qrCode}
            alt="TOTP QR code"
            className="mx-auto w-44 h-44 rounded-lg bg-white p-2"
          />
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">
              Or enter this key manually:
            </p>
            <code className="text-xs break-all select-all text-foreground">
              {enrollment.secret}
            </code>
          </div>

          <form onSubmit={confirmEnroll} className="space-y-3">
            <input
              inputMode="numeric"
              pattern="[0-9]*"
              maxLength={6}
              required
              autoFocus
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-center text-lg tracking-[0.5em] font-mono focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
              placeholder="000000"
            />
            <div className="flex gap-2">
              <button
                type="button"
                onClick={cancelEnroll}
                className="flex-1 rounded-xl border border-white/10 bg-white/5 py-2.5 text-sm font-medium hover:bg-white/10 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={busy || code.length < 6}
                className="flex-1 rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
              >
                {busy ? 'Verifying…' : 'Confirm'}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <button
          type="button"
          onClick={startEnroll}
          disabled={busy}
          className="w-full rounded-xl border border-[var(--brand-primary)]/40 bg-[var(--brand-primary)]/10 py-2.5 text-sm font-semibold text-[var(--brand-primary)] hover:bg-[var(--brand-primary)]/20 disabled:opacity-50 transition-colors"
        >
          {factors.length > 0 ? 'Add another authenticator' : 'Add authenticator app'}
        </button>
      )}
    </div>
  )
}
