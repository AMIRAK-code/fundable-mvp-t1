'use client'

import { useActionState, useEffect, useState } from 'react'
import { X, Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import { upsertInvestorDetails } from '@/app/actions/profile'
import type { InvestorDetail } from '@/lib/supabase/types'
import { INVESTOR_STATUS_LABELS } from '@/lib/supabase/types'

const INIT = { error: null as string | null, success: false }

export default function InvestorForm({ details }: { details: InvestorDetail | null }) {
  const [state, action, pending] = useActionState(upsertInvestorDetails, INIT)

  // Sectors chip input
  const [sectors, setSectors] = useState<string[]>(details?.sectors ?? [])
  const [sectorInput, setSectorInput] = useState('')

  useEffect(() => {
    if (state.success) toast.success('Profile saved')
    else if (state.error) toast.error(state.error)
  }, [state])

  function addSector() {
    const val = sectorInput.trim()
    if (val && !sectors.includes(val)) setSectors((prev) => [...prev, val])
    setSectorInput('')
  }

  function removeSector(s: string) {
    setSectors((prev) => prev.filter((x) => x !== s))
  }

  return (
    <form action={action} className="space-y-4">
      {/* Hidden serialised sectors field */}
      <input type="hidden" name="sectors" value={sectors.join(',')} />

      <div className="space-y-1.5">
        <label className="text-sm text-muted-foreground">Firm name</label>
        <input
          name="firm_name"
          maxLength={80}
          defaultValue={details?.firm_name ?? ''}
          placeholder="Sequoia Capital"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
        />
      </div>

      <div className="space-y-1.5">
        <label className="text-sm text-muted-foreground">Typical check size</label>
        <input
          name="check_size"
          maxLength={80}
          defaultValue={details?.check_size ?? ''}
          placeholder="$250K – $1M"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
        />
      </div>

      <div className="space-y-1.5">
        <label className="text-sm text-muted-foreground">Current status</label>
        <select
          name="status"
          defaultValue={details?.status ?? ''}
          className="w-full rounded-xl border border-white/10 bg-slate-900 px-4 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
        >
          <option value="">Not specified</option>
          {Object.entries(INVESTOR_STATUS_LABELS).map(([value, label]) => (
            <option key={value} value={value}>{label}</option>
          ))}
        </select>
      </div>

      <div className="space-y-1.5">
        <label className="text-sm text-muted-foreground">Sectors</label>
        <div className="flex gap-2">
          <input
            value={sectorInput}
            onChange={(e) => setSectorInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                addSector()
              }
            }}
            placeholder="Type sector, press Enter"
            aria-label="Add a sector"
            className="flex-1 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
          />
          <button
            type="button"
            onClick={addSector}
            className="press px-3 py-2.5 rounded-xl border border-white/10 bg-white/5 text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            Add
          </button>
        </div>
        {sectors.length > 0 && (
          <div className="flex flex-wrap gap-1.5 pt-1">
            {sectors.map((s) => (
              <span
                key={s}
                className="animate-pop flex items-center gap-1 px-2.5 py-1 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] text-xs font-semibold"
              >
                {s}
                <button
                  type="button"
                  onClick={() => removeSector(s)}
                  aria-label={`Remove ${s}`}
                  className="press hover:opacity-70"
                >
                  <X className="w-3 h-3" aria-hidden />
                </button>
              </span>
            ))}
          </div>
        )}
      </div>

      <div className="space-y-1.5">
        <label className="text-sm text-muted-foreground">Investment thesis</label>
        <textarea
          name="thesis"
          rows={4}
          maxLength={1000}
          defaultValue={details?.thesis ?? ''}
          placeholder="I invest in early-stage B2B SaaS companies solving…"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] resize-none"
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
        className="press w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
      >
        {pending ? (
          <span className="inline-flex items-center justify-center gap-2">
            <Loader2 className="w-4 h-4 animate-spin" aria-hidden />
            Saving…
          </span>
        ) : (
          'Save Details'
        )}
      </button>
    </form>
  )
}
