'use client'

import { useActionState, useEffect, useState } from 'react'
import { X, Code2, Link2, Globe, Camera, ExternalLink } from 'lucide-react'
import { upsertInvestmentOffer } from '@/app/actions/profile'
import type { InvestmentOffer } from '@/lib/supabase/types'

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  offer: InvestmentOffer | null
}

const INIT = { error: null as string | null, success: false }
const STAGES = ['Pre-seed', 'Seed', 'Series A', 'Series B', 'Growth', 'Any stage']

const SOCIAL_FIELDS = [
  { key: 'linkedin',  label: 'LinkedIn',  Icon: Link2,        placeholder: 'https://linkedin.com/in/yourprofile' },
  { key: 'website',   label: 'Website',   Icon: Globe,        placeholder: 'https://yourfirm.com' },
  { key: 'github',    label: 'GitHub',    Icon: Code2,        placeholder: 'https://github.com/username' },
  { key: 'instagram', label: 'Instagram', Icon: Camera,       placeholder: 'https://instagram.com/username' },
  { key: 'reddit',    label: 'Reddit',    Icon: ExternalLink, placeholder: 'https://reddit.com/u/username' },
]

export default function OfferDialog({ open, onOpenChange, offer }: Props) {
  const [state, action, pending] = useActionState(upsertInvestmentOffer, INIT)
  const [sectors, setSectors] = useState<string[]>(offer?.sectors ?? [])
  const [sectorInput, setSectorInput] = useState('')

  useEffect(() => { if (state.success) onOpenChange(false) }, [state.success, onOpenChange])
  useEffect(() => { if (!open) { setSectors(offer?.sectors ?? []); setSectorInput('') } }, [open, offer])

  function addSector() {
    const val = sectorInput.trim()
    if (val && !sectors.includes(val)) setSectors((prev) => [...prev, val])
    setSectorInput('')
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => onOpenChange(false)} />
      <div className="relative w-full sm:max-w-md bg-slate-900 border border-white/10 rounded-t-2xl sm:rounded-2xl p-6 z-10 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-5">
          <h3 className="font-semibold text-lg">{offer ? 'Edit Offer' : 'New Investment Offer'}</h3>
          <button onClick={() => onOpenChange(false)} className="text-muted-foreground hover:text-foreground transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form action={action} className="space-y-4">
          {offer && <input type="hidden" name="id" value={offer.id} />}
          <input type="hidden" name="sectors" value={sectors.join(',')} />

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">Offer title <span className="text-destructive">*</span></label>
            <input name="title" required defaultValue={offer?.title} placeholder="Seed investment in B2B SaaS"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]" />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">Description <span className="text-destructive">*</span></label>
            <textarea name="description" required rows={3} defaultValue={offer?.description}
              placeholder="What you're looking for, your value-add, terms…"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] resize-none" />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <label className="text-sm text-muted-foreground">Check size</label>
              <input name="amount" defaultValue={offer?.amount ?? ''} placeholder="$250K–$1M"
                className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]" />
            </div>
            <div className="space-y-1.5">
              <label className="text-sm text-muted-foreground">Stage</label>
              <select name="stage" defaultValue={offer?.stage ?? ''}
                className="w-full rounded-xl border border-white/10 bg-slate-900 px-4 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]">
                <option value="">Any stage</option>
                {STAGES.map((s) => <option key={s} value={s}>{s}</option>)}
              </select>
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">Sectors</label>
            <div className="flex gap-2">
              <input value={sectorInput} onChange={(e) => setSectorInput(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addSector() } }}
                placeholder="Type sector, press Enter"
                className="flex-1 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]" />
              <button type="button" onClick={addSector} className="px-3 py-2.5 rounded-xl border border-white/10 bg-white/5 text-sm text-muted-foreground hover:text-foreground transition-colors">Add</button>
            </div>
            {sectors.length > 0 && (
              <div className="flex flex-wrap gap-1.5 pt-1">
                {sectors.map((s) => (
                  <span key={s} className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] text-xs font-semibold">
                    {s}
                    <button type="button" onClick={() => setSectors((prev) => prev.filter((x) => x !== s))} className="hover:opacity-70">
                      <X className="w-3 h-3" />
                    </button>
                  </span>
                ))}
              </div>
            )}
          </div>

          {/* Social links */}
          <div className="space-y-2 pt-1">
            <p className="text-sm text-muted-foreground font-medium">Your Links <span className="text-xs font-normal">(optional)</span></p>
            {SOCIAL_FIELDS.map(({ key, label, Icon, placeholder }) => (
              <div key={key} className="flex items-center gap-2">
                <div className="w-8 h-8 flex items-center justify-center rounded-lg bg-white/5 border border-white/10 flex-shrink-0">
                  <Icon className="w-3.5 h-3.5 text-muted-foreground" />
                </div>
                <input
                  name={`link_${key}`}
                  defaultValue={(offer?.links as Record<string, string>)?.[key] ?? ''}
                  placeholder={placeholder}
                  className="flex-1 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
                />
              </div>
            ))}
          </div>

          {state.error && (
            <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5">{state.error}</p>
          )}

          <button type="submit" disabled={pending}
            className="w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity">
            {pending ? 'Saving…' : offer ? 'Save Changes' : 'Post Offer'}
          </button>
        </form>
      </div>
    </div>
  )
}
