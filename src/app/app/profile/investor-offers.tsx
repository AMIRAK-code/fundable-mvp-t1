'use client'

import { useTransition, useState } from 'react'
import { Plus, Trash2, Briefcase } from 'lucide-react'
import { deleteInvestmentOffer, toggleOfferStatus } from '@/app/actions/profile'
import type { InvestmentOffer } from '@/lib/supabase/types'
import OfferDialog from './offer-dialog'

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
          className="flex items-center gap-1.5 text-sm font-semibold text-white bg-[var(--brand-primary)] px-3.5 py-2 rounded-lg hover:opacity-90 transition-opacity min-h-[40px] flex-shrink-0"
        >
          <Plus className="w-4 h-4" />
          Post
        </button>
      </div>

      {offers.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-white/10 p-8 text-center">
          <Briefcase className="w-8 h-8 text-muted-foreground mx-auto mb-3" />
          <p className="text-sm text-muted-foreground">No offers posted yet.</p>
          <p className="text-xs text-muted-foreground mt-1">Post an offer to attract founders.</p>
        </div>
      ) : (
        offers.map((o) => (
          <OfferRow key={o.id} offer={o} onEdit={() => openEdit(o)} />
        ))
      )}

      <OfferDialog open={dialogOpen} onOpenChange={setDialogOpen} offer={editTarget} />
    </div>
  )
}

function OfferRow({ offer, onEdit }: { offer: InvestmentOffer; onEdit: () => void }) {
  const [deleting, startDelete] = useTransition()
  const [toggling, startToggle] = useTransition()

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-4 space-y-3">
      <div className="min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <p className="font-semibold text-sm flex-1 min-w-0 truncate">{offer.title}</p>
          <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full flex-shrink-0 ${
            offer.status === 'active'
              ? 'bg-[var(--brand-success)]/20 text-[var(--brand-success)]'
              : 'bg-white/10 text-muted-foreground'
          }`}>
            {offer.status === 'active' ? 'Active' : 'Closed'}
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
          className="flex-1 text-xs font-medium text-muted-foreground hover:text-foreground px-2 py-2 rounded-lg border border-white/10 transition-colors min-h-[36px]"
        >
          Edit
        </button>
        <button
          disabled={toggling}
          onClick={() => startToggle(() => { toggleOfferStatus(offer.id, offer.status === 'active' ? 'closed' : 'active') })}
          className="flex-1 text-xs font-medium text-muted-foreground hover:text-foreground px-2 py-2 rounded-lg border border-white/10 transition-colors disabled:opacity-50 min-h-[36px]"
        >
          {offer.status === 'active' ? 'Close' : 'Reopen'}
        </button>
        <button
          disabled={deleting}
          onClick={() => startDelete(() => { deleteInvestmentOffer(offer.id) })}
          aria-label="Delete offer"
          className="flex items-center justify-center text-destructive hover:text-red-400 px-3 py-2 rounded-lg border border-destructive/20 disabled:opacity-50 transition-colors min-h-[36px] min-w-[40px]"
        >
          <Trash2 className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  )
}
