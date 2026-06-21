'use client'

import { useOptimistic, useState, useTransition } from 'react'
import { Plus, Trash2, Briefcase, Pencil } from 'lucide-react'
import { toast } from 'sonner'
import { deleteInvestmentOffer, toggleOfferStatus } from '@/app/actions/profile'
import type { InvestmentOffer } from '@/lib/supabase/types'
import OfferDialog from './offer-dialog'
import ConfirmDialog from './confirm-dialog'

type OptimisticAction =
  | { type: 'status'; id: string; status: 'active' | 'closed' }
  | { type: 'delete'; id: string }

export default function InvestorOffers({ offers }: { offers: InvestmentOffer[] }) {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editTarget, setEditTarget] = useState<InvestmentOffer | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<InvestmentOffer | null>(null)

  const [optimistic, applyOptimistic] = useOptimistic<InvestmentOffer[], OptimisticAction>(
    offers,
    (current, action) => {
      if (action.type === 'status') {
        return current.map((o) => (o.id === action.id ? { ...o, status: action.status } : o))
      }
      if (action.type === 'delete') {
        return current.filter((o) => o.id !== action.id)
      }
      return current
    }
  )

  function openAdd() {
    setEditTarget(null)
    setDialogOpen(true)
  }
  function openEdit(o: InvestmentOffer) {
    setEditTarget(o)
    setDialogOpen(true)
  }

  async function confirmDelete() {
    const target = deleteTarget
    if (!target) return
    applyOptimistic({ type: 'delete', id: target.id })
    const res = await deleteInvestmentOffer(target.id)
    if (res.error) toast.error(res.error)
    else toast.success('Offer deleted')
  }

  const isEmpty = optimistic.length === 0

  return (
    <section className="space-y-4" aria-label="My investment offers">
      <div className="flex items-center justify-between gap-3">
        <h2 className="font-semibold text-base sm:text-lg">My Offers</h2>
        {!isEmpty && (
          <button
            type="button"
            onClick={openAdd}
            className="inline-flex items-center gap-1.5 text-sm font-semibold text-white bg-[var(--brand-primary)] px-4 py-2 rounded-lg hover:opacity-90 transition-opacity min-h-[40px] flex-shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
          >
            <Plus className="w-4 h-4" aria-hidden="true" />
            Post
          </button>
        )}
      </div>

      {isEmpty ? (
        <div className="rounded-2xl border border-dashed border-white/15 bg-white/[0.02] p-6 sm:p-8 text-center">
          <div className="mx-auto w-12 h-12 rounded-full bg-[var(--brand-primary)]/10 flex items-center justify-center mb-3">
            <Briefcase className="w-6 h-6 text-[var(--brand-primary)]" aria-hidden="true" />
          </div>
          <p className="text-sm font-medium">No offers posted yet</p>
          <p className="text-xs text-muted-foreground mt-1 max-w-sm mx-auto">
            Post an offer with your check size and sectors to attract founders.
          </p>
          <button
            type="button"
            onClick={openAdd}
            className="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-white bg-[var(--brand-primary)] px-5 py-2.5 rounded-xl hover:opacity-90 transition-opacity min-h-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
          >
            <Plus className="w-4 h-4" aria-hidden="true" />
            Post your first offer
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {optimistic.map((o) => (
            <OfferRow
              key={o.id}
              offer={o}
              onEdit={() => openEdit(o)}
              onDelete={() => setDeleteTarget(o)}
              applyOptimistic={applyOptimistic}
            />
          ))}
        </div>
      )}

      <OfferDialog open={dialogOpen} onOpenChange={setDialogOpen} offer={editTarget} />
      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(v) => !v && setDeleteTarget(null)}
        title="Delete offer?"
        description={`"${deleteTarget?.title ?? ''}" will be removed from your profile and the feed.`}
        confirmLabel="Delete"
        destructive
        onConfirm={confirmDelete}
      />
    </section>
  )
}

function OfferRow({
  offer,
  onEdit,
  onDelete,
  applyOptimistic,
}: {
  offer: InvestmentOffer
  onEdit: () => void
  onDelete: () => void
  applyOptimistic: (a: OptimisticAction) => void
}) {
  const [toggling, startToggle] = useTransition()

  function handleToggle() {
    const next: 'active' | 'closed' = offer.status === 'active' ? 'closed' : 'active'
    startToggle(async () => {
      applyOptimistic({ type: 'status', id: offer.id, status: next })
      const res = await toggleOfferStatus(offer.id, next)
      if (res.error) toast.error(res.error)
      else toast.success(next === 'active' ? 'Offer reopened' : 'Offer closed')
    })
  }

  return (
    <article className="rounded-2xl border border-white/10 bg-white/5 p-4 space-y-3 flex flex-col">
      <div className="min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <p className="font-semibold text-sm flex-1 min-w-0 truncate">{offer.title}</p>
          <span
            className={`text-[10px] font-semibold px-2 py-0.5 rounded-full flex-shrink-0 ${
              offer.status === 'active'
                ? 'bg-[var(--brand-success)]/20 text-[var(--brand-success)]'
                : 'bg-white/10 text-muted-foreground'
            }`}
          >
            {offer.status === 'active' ? 'Active' : 'Closed'}
          </span>
        </div>
        <div className="flex gap-3 mt-0.5 flex-wrap">
          {offer.amount && <p className="text-xs text-[var(--brand-primary)]">{offer.amount}</p>}
          {offer.stage && <p className="text-xs text-muted-foreground">{offer.stage}</p>}
        </div>
      </div>
      <p className="text-xs text-muted-foreground line-clamp-3 [overflow-wrap:anywhere] flex-1">
        {offer.description}
      </p>
      {offer.sectors && offer.sectors.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {offer.sectors.map((s) => (
            <span
              key={s}
              className="px-2 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] text-[10px] font-semibold uppercase tracking-wide"
            >
              {s}
            </span>
          ))}
        </div>
      )}
      <div className="flex gap-2 pt-3 border-t border-white/5">
        <button
          type="button"
          onClick={onEdit}
          aria-label={`Edit ${offer.title}`}
          className="flex-1 inline-flex items-center justify-center gap-1.5 text-xs font-medium text-muted-foreground hover:text-foreground px-2 py-2 rounded-lg border border-white/10 hover:border-white/20 transition-colors min-h-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
        >
          <Pencil className="w-3.5 h-3.5" aria-hidden="true" />
          <span>Edit</span>
        </button>
        <button
          type="button"
          disabled={toggling}
          onClick={handleToggle}
          aria-pressed={offer.status === 'active'}
          className="flex-1 inline-flex items-center justify-center text-xs font-medium text-muted-foreground hover:text-foreground px-2 py-2 rounded-lg border border-white/10 hover:border-white/20 transition-colors disabled:opacity-50 min-h-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
        >
          {offer.status === 'active' ? 'Close' : 'Reopen'}
        </button>
        <button
          type="button"
          onClick={onDelete}
          aria-label={`Delete ${offer.title}`}
          className="inline-flex items-center justify-center text-destructive hover:bg-destructive/10 px-3 py-2 rounded-lg border border-destructive/20 transition-colors min-h-[44px] min-w-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive"
        >
          <Trash2 className="w-4 h-4" aria-hidden="true" />
        </button>
      </div>
    </article>
  )
}
