'use client'

import { useActionState, useEffect, useId, useState } from 'react'
import { X, Code2, Link2, Globe, Camera, ExternalLink } from 'lucide-react'
import { toast } from 'sonner'
import { upsertInvestmentOffer } from '@/app/actions/profile'
import { normalizeSector } from '@/lib/profile-completion'
import type { InvestmentOffer } from '@/lib/supabase/types'
import SheetDialog from './sheet-dialog'

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  offer: InvestmentOffer | null
}

const INIT = { error: null as string | null, success: false }
const STAGES = ['Pre-seed', 'Seed', 'Series A', 'Series B', 'Growth', 'Any stage']
const DESC_LIMIT = 500

const SOCIAL_FIELDS = [
  { key: 'linkedin',  label: 'LinkedIn',  Icon: Link2,        placeholder: 'https://linkedin.com/in/yourprofile' },
  { key: 'website',   label: 'Website',   Icon: Globe,        placeholder: 'https://yourfirm.com' },
  { key: 'github',    label: 'GitHub',    Icon: Code2,        placeholder: 'https://github.com/username' },
  { key: 'instagram', label: 'Instagram', Icon: Camera,       placeholder: 'https://instagram.com/username' },
  { key: 'reddit',    label: 'Reddit',    Icon: ExternalLink, placeholder: 'https://reddit.com/u/username' },
] as const

export default function OfferDialog({ open, onOpenChange, offer }: Props) {
  const [state, action, pending] = useActionState(upsertInvestmentOffer, INIT)
  const [sectors, setSectors] = useState<string[]>(offer?.sectors ?? [])
  const [sectorInput, setSectorInput] = useState('')
  const [description, setDescription] = useState(offer?.description ?? '')
  const ids = useId()

  useEffect(() => {
    if (state.success) {
      toast.success(offer ? 'Offer updated' : 'Offer posted')
      onOpenChange(false)
    } else if (state.error) {
      toast.error(state.error)
    }
  }, [state, onOpenChange, offer])

  useEffect(() => {
    if (!open) {
      setSectors(offer?.sectors ?? [])
      setSectorInput('')
      setDescription(offer?.description ?? '')
    }
  }, [open, offer])

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

  const descOver = description.trim().length > DESC_LIMIT

  return (
    <SheetDialog
      open={open}
      onOpenChange={onOpenChange}
      title={offer ? 'Edit Offer' : 'New Investment Offer'}
      description={offer ? 'Update what founders see in the feed.' : 'Describe what you’re looking to invest in.'}
    >
      <form action={action} className="space-y-4">
        {offer && <input type="hidden" name="id" value={offer.id} />}
        <input type="hidden" name="sectors" value={sectors.join(',')} />

        <div className="space-y-1.5">
          <label htmlFor={`${ids}-title`} className="text-sm text-muted-foreground">
            Offer title <span className="text-destructive" aria-hidden="true">*</span>
          </label>
          <input
            id={`${ids}-title`}
            name="title"
            required
            maxLength={100}
            defaultValue={offer?.title}
            placeholder="Seed investment in B2B SaaS"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
          />
        </div>

        <div className="space-y-1.5">
          <div className="flex items-baseline justify-between gap-3">
            <label htmlFor={`${ids}-desc`} className="text-sm text-muted-foreground">
              Description <span className="text-destructive" aria-hidden="true">*</span>
            </label>
            <span className={`text-xs ${descOver ? 'text-destructive' : 'text-muted-foreground'}`}>
              {description.trim().length}/{DESC_LIMIT}
            </span>
          </div>
          <textarea
            id={`${ids}-desc`}
            name="description"
            required
            rows={3}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="What you're looking for, your value-add, terms…"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] resize-none"
            aria-invalid={descOver || undefined}
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div className="space-y-1.5">
            <label htmlFor={`${ids}-amount`} className="text-sm text-muted-foreground">
              Check size
            </label>
            <input
              id={`${ids}-amount`}
              name="amount"
              defaultValue={offer?.amount ?? ''}
              placeholder="$250K–$1M"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            />
          </div>
          <div className="space-y-1.5">
            <label htmlFor={`${ids}-stage`} className="text-sm text-muted-foreground">
              Stage
            </label>
            <select
              id={`${ids}-stage`}
              name="stage"
              defaultValue={offer?.stage ?? ''}
              className="w-full rounded-xl border border-white/10 bg-slate-900 px-4 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            >
              <option value="">Any stage</option>
              {STAGES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="space-y-1.5">
          <label htmlFor={`${ids}-sector-input`} className="text-sm text-muted-foreground">
            Sectors
          </label>
          <div className="flex gap-2">
            <input
              id={`${ids}-sector-input`}
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

        {/* Social links */}
        <fieldset className="space-y-2 pt-1">
          <legend className="text-sm text-muted-foreground font-medium">
            Your links <span className="text-xs font-normal">(optional)</span>
          </legend>
          {SOCIAL_FIELDS.map(({ key, label, Icon, placeholder }) => (
            <div key={key} className="flex items-center gap-2">
              <span
                aria-hidden="true"
                className="w-9 h-9 flex items-center justify-center rounded-lg bg-white/5 border border-white/10 flex-shrink-0"
              >
                <Icon className="w-4 h-4 text-muted-foreground" />
              </span>
              <input
                id={`${ids}-link-${key}`}
                name={`link_${key}`}
                type="url"
                inputMode="url"
                aria-label={`${label} URL`}
                defaultValue={(offer?.links as Record<string, string> | undefined)?.[key] ?? ''}
                placeholder={placeholder}
                className="flex-1 rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
              />
            </div>
          ))}
        </fieldset>

        <button
          type="submit"
          disabled={pending || descOver}
          aria-busy={pending}
          className="w-full rounded-xl bg-[var(--brand-primary)] py-3 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity min-h-[44px]"
        >
          {pending ? 'Saving…' : offer ? 'Save changes' : 'Post offer'}
        </button>
      </form>
    </SheetDialog>
  )
}
