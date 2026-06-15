'use client'

import { useOptimistic, useTransition, useState } from 'react'
import { Plus, Briefcase } from 'lucide-react'
import { toast } from 'sonner'
import { deleteInvestmentOffer, toggleOfferStatus } from '@/app/actions/profile'
import type { InvestmentOffer } from '@/lib/supabase/types'
import OfferDialog from './offer-dialog'
import ConfirmDeleteButton from './confirm-delete-button'

export default function InvestorOffers({ offers }: { offers: InvestmentOffer[] }) {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editTarget, setEditTarget] = useState<InvestmentOffer | null>(null)

  function openAdd() { setEditTarget(null); setDialogOpen(true) }
  function openEdit(o: InvestmentOffer) { setEditTarget(o); setDialogOpen(true) }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h2 className="font-semibold text-foreground">My Offers</h2>
        <button
          onClick={openAdd}
          className="press flex items-center gap-1.5 text-sm font-semibold text-white bg-[var(--brand-primary)] px-3.5 py-2 rounded-lg hover:opacity-90 transition-opacity min-h-[40px] flex-shrink-0"
        >
          <Plus className="w-4 h-4" aria-hidden />
          Post
        </button>
      </div>

      {offers.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-white/10 p-8 text-center animate-in-up">
          <Briefcase className="w-8 h-8 text-muted-foreground mx-auto mb-3" />
          <p className="text-sm text-muted-foreground">No offers posted yet.</p>
          <p className="text-xs text-muted-foreground mt-1">Post an offer to attract founders.</p>
        </div>
      ) : (
        <div className="space-y-4 stagger-children">
          {offers.map((o) => (
            <OfferRow key={o.id} offer={o} onEdit={() => openEdit(o)} />
          ))}
        </div>
      )}

      <OfferDialog open={dialogOpen} onOpenChange={setDialogOpen} offer={editTarget} />
    </div>
  )
}

function OfferRow({ offer, onEdit }: { offer: InvestmentOffer; onEdit: () => void }) {
  const [deleting, startDelete] = useTransition()
  const [, startToggle] = useTransition()
  const [status, setOptimisticStatus] = useOptimistic(
    offer.status,
    (_current, next: 'active' | 'closed') => next
  )

  function handleToggleStatus() {
    const next = offer.status === 'active' ? 'closed' : 'active'
    startToggle(async () => {
      setOptimisticStatus(next)
      const { error } = await toggleOfferStatus(offer.id, next)
      if (error) toast.error(error)
      else toast.success(next === 'active' ? 'Offer reopened' : 'Offer closed')
    })
  }

  function handleDelete() {
    startDelete(async () => {
      const { error } = await deleteInvestmentOffer(offer.id)
      if (error) toast.error(error)
      else toast.success('Offer deleted')
    })
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-4 space-y-3 animate-in-up">
      <div className="min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <p className="font-semibold text-sm flex-1 min-w-0 truncate">{offer.title}</p>
          <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full flex-shrink-0 ${
            status === 'active'
              ? 'bg-[var(--brand-success)]/20 text-[var(--brand-success)]'
              : 'bg-white/10 text-muted-foreground'
          }`}>
            {status === 'active' ? 'Active' : 'Closed'}
          </span>
        </div>
        <div className="flex gap-3 mt-0.5 flex-wrap">
          {offer.amount && <p className="text-xs text-[var(--brand-primary)]">{offer.amount}</p>}
          {offer.stage && <p className="text-xs text-muted-foreground">{offer.stage}</p>}
        </div>
      </div>
      <p className="text-xs text-muted-foreground line-clamp-2">{offer.description}</p>
      {offer.sectors && offer.sectors.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {offer.sectors.map((s) => (
            <span key={s} className="px-2 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] text-[10px] font-semibold uppercase tracking-wide">
              {s}
            </span>
          ))}
        </div>
      )}
      <div className="flex gap-2 pt-1 border-t border-white/5">
        <button
          onClick={onEdit}
          className="press flex-1 text-xs font-medium text-muted-foreground hover:text-foreground px-2 py-2 rounded-lg border border-white/10 transition-colors min-h-[36px]"
        >
          Edit
        </button>
        <button
          onClick={handleToggleStatus}
          aria-label={status === 'active' ? `Close offer ${offer.title}` : `Reopen offer ${offer.title}`}
          className="press flex-1 text-xs font-medium text-muted-foreground hover:text-foreground px-2 py-2 rounded-lg border border-white/10 transition-colors min-h-[36px]"
        >
          {status === 'active' ? 'Close' : 'Reopen'}
        </button>
        <ConfirmDeleteButton
          label={`Delete offer ${offer.title}`}
          pending={deleting}
          onConfirm={handleDelete}
        />
      </div>
    </div>
  )
}
