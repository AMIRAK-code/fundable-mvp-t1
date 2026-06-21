'use client'

import { useActionState, useEffect, useState } from 'react'
import { X } from 'lucide-react'
import { toast } from 'sonner'
import { upsertInvestorDetails } from '@/app/actions/profile'
import { normalizeSector } from '@/lib/profile-completion'
import type { InvestorDetail } from '@/lib/supabase/types'

const INIT = { error: null as string | null, success: false }
const THESIS_LIMIT = 500

export default function InvestorForm({ details }: { details: InvestorDetail | null }) {
  const [state, action, pending] = useActionState(upsertInvestorDetails, INIT)

  const [sectors, setSectors] = useState<string[]>(details?.sectors ?? [])
  const [sectorInput, setSectorInput] = useState('')
  const [thesis, setThesis] = useState(details?.thesis ?? '')

  useEffect(() => {
    if (state.success) toast.success('Investor details saved')
    else if (state.error) toast.error(state.error)
  }, [state])

  function addSector() {
    const val = normalizeSector(sectorInput)
    if (!val) {
      setSectorInput('')
      return
    }
    if (!sectors.some((s) => normalizeSector(s) === val)) {
      setSectors((prev) => [...prev, val])
    }
    setSectorInput('')
  }

  function removeSector(s: string) {
    setSectors((prev) => prev.filter((x) => x !== s))
  }

  const thesisOver = thesis.trim().length > THESIS_LIMIT

  return (
    <form action={action} className="space-y-4">
      <input type="hidden" name="sectors" value={sectors.join(',')} />

      <div className="space-y-1.5">
        <label htmlFor="firm_name" className="text-sm text-muted-foreground">
          Firm name
        </label>
        <input
          id="firm_name"
          name="firm_name"
          defaultValue={details?.firm_name ?? ''}
          placeholder="Sequoia Capital"
          autoComplete="organization"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="check_size" className="text-sm text-muted-foreground">
          Typical check size
        </label>
        <input
          id="check_size"
          name="check_size"
          defaultValue={details?.check_size ?? ''}
          placeholder="$250K – $1M"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="sector_input" className="text-sm text-muted-foreground">
          Sectors
        </label>
        <div className="flex gap-2">
          <input
            id="sector_input"
            value={sectorInput}
            onChange={(e) => setSectorInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ',') {
                e.preventDefault()
                addSector()
              }
            }}
            placeholder="Type a sector, press Enter"
            className="flex-1 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
          />
          <button
            type="button"
            onClick={addSector}
            className="px-4 py-2.5 rounded-xl border border-white/10 bg-white/5 text-sm font-medium text-muted-foreground hover:text-foreground hover:border-white/20 transition-colors min-h-[44px] min-w-[60px]"
          >
            Add
          </button>
        </div>
        {sectors.length > 0 && (
          <ul className="flex flex-wrap gap-1.5 pt-1" aria-label="Selected sectors">
            {sectors.map((s) => (
              <li key={s}>
                <span className="inline-flex items-center gap-1 pl-2.5 pr-1 py-1 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] text-xs font-semibold capitalize">
                  {s}
                  <button
                    type="button"
                    onClick={() => removeSector(s)}
                    aria-label={`Remove sector ${s}`}
                    className="inline-flex items-center justify-center w-6 h-6 rounded-full hover:bg-[var(--brand-success)]/20 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-success)]"
                  >
                    <X className="w-3 h-3" aria-hidden="true" />
                  </button>
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="space-y-1.5">
        <div className="flex items-baseline justify-between gap-3">
          <label htmlFor="thesis" className="text-sm text-muted-foreground">
            Investment thesis
          </label>
          <span className={`text-xs ${thesisOver ? 'text-destructive' : 'text-muted-foreground'}`}>
            {thesis.trim().length}/{THESIS_LIMIT}
          </span>
        </div>
        <textarea
          id="thesis"
          name="thesis"
          rows={4}
          value={thesis}
          onChange={(e) => setThesis(e.target.value)}
          placeholder="I invest in early-stage B2B SaaS companies solving…"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] resize-none"
          aria-invalid={thesisOver || undefined}
        />
      </div>

      <button
        type="submit"
        disabled={pending || thesisOver}
        aria-busy={pending}
        className="w-full rounded-xl bg-[var(--brand-primary)] py-3 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity min-h-[44px]"
      >
        {pending ? 'Saving…' : 'Save details'}
      </button>
    </form>
  )
}
