'use client'

import { useState } from 'react'
import Image from 'next/image'
import { User, Briefcase, Code2, Link2, Globe, Camera, ExternalLink, ChevronDown } from 'lucide-react'
import ConnectButton from './connect-button'
import type { ConnectionStatus, InvestorDetail, InvestmentOffer } from '@/lib/supabase/types'
import { INVESTOR_STATUS_LABELS, INVESTOR_STATUS_COLORS } from '@/lib/supabase/types'

// Joined profile shape returned by the feed query
interface FeedProfile {
  id: string
  full_name: string | null
  avatar_url: string | null
}

export type FeedInvestor = InvestorDetail & { profiles: FeedProfile }
export type FeedOffer = Pick<InvestmentOffer, 'id' | 'investor_id' | 'title' | 'amount' | 'stage' | 'sectors' | 'status' | 'links'>

interface Props {
  investor: FeedInvestor
  connection: { status: ConnectionStatus } | null
  offers?: FeedOffer[]
}

const LINK_ICONS = [
  { key: 'linkedin',  label: 'LinkedIn',  Icon: Link2 },
  { key: 'website',   label: 'Website',   Icon: Globe },
  { key: 'github',    label: 'GitHub',    Icon: Code2 },
  { key: 'instagram', label: 'Instagram', Icon: Camera },
  { key: 'reddit',    label: 'Reddit',    Icon: ExternalLink },
]

export default function InvestorCard({ investor, connection, offers = [] }: Props) {
  const [expanded, setExpanded] = useState(false)

  // Gather links from all active offers (take first offer's links as primary)
  const offerLinks = (offers[0]?.links ?? {}) as Record<string, string>
  const hasLinks = LINK_ICONS.some(({ key }) => offerLinks[key])
  const hasExpandable = Boolean(investor.thesis || hasLinks || offers.length > 0)

  const toggle = () => hasExpandable && setExpanded((v) => !v)
  const onKeyDown = (e: React.KeyboardEvent<HTMLDivElement>) => {
    if (e.target !== e.currentTarget) return
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      toggle()
    }
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md overflow-hidden animate-in-up">
      {/* Header — always visible */}
      <div
        className={`p-5 space-y-4 ${hasExpandable ? 'cursor-pointer press-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[var(--brand-primary)]' : ''}`}
        onClick={toggle}
        {...(hasExpandable
          ? {
              role: 'button',
              tabIndex: 0,
              'aria-expanded': expanded,
              'aria-label': `${investor.profiles.full_name ?? 'Investor'} — ${expanded ? 'collapse' : 'expand'} details`,
              onKeyDown,
            }
          : {})}
      >
        <div className="flex items-start gap-4">
          <div className="flex-shrink-0">
            {investor.profiles.avatar_url ? (
              <Image src={investor.profiles.avatar_url} alt={investor.profiles.full_name ?? ''} width={52} height={52} className="rounded-full object-cover border border-white/10" />
            ) : (
              <div className="w-[52px] h-[52px] rounded-full bg-white/10 border border-white/10 flex items-center justify-center">
                <User className="w-5 h-5 text-muted-foreground" />
              </div>
            )}
          </div>

          <div className="flex-1 min-w-0">
            <p className="font-semibold text-foreground leading-tight">{investor.profiles.full_name}</p>
            {investor.firm_name && <p className="text-xs text-[var(--brand-primary)] font-medium mt-0.5">{investor.firm_name}</p>}
            {investor.check_size && <p className="text-xs text-muted-foreground mt-0.5">Check: {investor.check_size}</p>}
            {investor.status && (
              <span className={`inline-block mt-1 px-2 py-0.5 rounded-full border text-[10px] font-semibold uppercase tracking-wide ${INVESTOR_STATUS_COLORS[investor.status]}`}>
                {INVESTOR_STATUS_LABELS[investor.status]}
              </span>
            )}
          </div>

          <div className="flex items-center gap-2 flex-shrink-0">
            {hasExpandable && (
              <span className={`text-muted-foreground transition-transform duration-300 ${expanded ? 'rotate-180' : ''}`}>
                <ChevronDown className="w-4 h-4" />
              </span>
            )}
            <div onClick={(e) => e.stopPropagation()}>
              <ConnectButton receiverId={investor.profiles.id} status={connection?.status ?? null} name={investor.profiles.full_name} />
            </div>
          </div>
        </div>

        {/* Sectors — always visible */}
        {investor.sectors && investor.sectors.length > 0 && (
          <div className="flex flex-wrap gap-1.5">
            {investor.sectors.map((s) => (
              <span key={s} className="px-2 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] text-[10px] font-semibold uppercase tracking-wide">{s}</span>
            ))}
          </div>
        )}

        {/* Thesis preview — collapsed */}
        {!expanded && investor.thesis && (
          <p className="text-sm text-muted-foreground line-clamp-2 leading-relaxed">{investor.thesis}</p>
        )}

        {/* Offer previews — collapsed */}
        {!expanded && offers.length > 0 && (
          <div className="space-y-2 pt-1 border-t border-white/10">
            <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
              <Briefcase className="w-3 h-3" /> Active Offers
            </p>
            {offers.slice(0, 1).map((o) => (
              <div key={o.id} className="rounded-xl bg-white/5 border border-white/10 px-3 py-2.5">
                <div className="flex items-baseline justify-between gap-2">
                  <p className="text-sm font-medium text-foreground truncate">{o.title}</p>
                  {o.amount && <span className="text-xs text-[var(--brand-primary)] flex-shrink-0">{o.amount}</span>}
                </div>
                {(o.stage || (o.sectors && o.sectors.length > 0)) && (
                  <div className="flex items-center gap-2 mt-1 flex-wrap">
                    {o.stage && <span className="text-[10px] text-muted-foreground">{o.stage}</span>}
                    {o.sectors?.slice(0, 3).map((s) => (
                      <span key={s} className="text-[10px] px-1.5 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] font-semibold uppercase tracking-wide">{s}</span>
                    ))}
                  </div>
                )}
              </div>
            ))}
            {offers.length > 1 && (
              <p className="text-[10px] text-muted-foreground text-center">+{offers.length - 1} more offer{offers.length > 2 ? 's' : ''} — tap to expand</p>
            )}
          </div>
        )}
      </div>

      {/* Expandable section — grid-rows trick handles any content height */}
      <div className={`grid transition-[grid-template-rows] duration-300 ease-in-out ${expanded ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'}`}>
        <div className="overflow-hidden min-h-0">
          <div className="px-5 pb-5 space-y-4 border-t border-white/10 pt-4">
            {/* Full thesis */}
            {investor.thesis && (
              <div className="space-y-1.5">
                <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Investment Thesis</p>
                <p className="text-sm text-muted-foreground leading-relaxed">{investor.thesis}</p>
              </div>
            )}

            {/* All offers */}
            {offers.length > 0 && (
              <div className="space-y-2">
                <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                  <Briefcase className="w-3 h-3" /> All Offers
                </p>
                {offers.map((o) => {
                  const ol = (o.links ?? {}) as Record<string, string>
                  const offerHasLinks = LINK_ICONS.some(({ key }) => ol[key])
                  return (
                    <div key={o.id} className="rounded-xl bg-white/5 border border-white/10 p-3 space-y-2">
                      <div className="flex items-baseline justify-between gap-2">
                        <p className="text-sm font-medium text-foreground">{o.title}</p>
                        {o.amount && <span className="text-xs text-[var(--brand-primary)] flex-shrink-0">{o.amount}</span>}
                      </div>
                      {(o.stage || (o.sectors && o.sectors.length > 0)) && (
                        <div className="flex items-center gap-2 flex-wrap">
                          {o.stage && <span className="text-[10px] text-muted-foreground">{o.stage}</span>}
                          {o.sectors?.map((s) => (
                            <span key={s} className="text-[10px] px-1.5 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] font-semibold uppercase tracking-wide">{s}</span>
                          ))}
                        </div>
                      )}
                      {offerHasLinks && (
                        <div className="flex flex-wrap gap-1.5 pt-1">
                          {LINK_ICONS.map(({ key, label, Icon }) =>
                            ol[key] ? (
                              <a key={key} href={ol[key]} target="_blank" rel="noopener noreferrer"
                                className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white/5 border border-white/10 text-xs text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors press-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
                                onClick={(e) => e.stopPropagation()}>
                                <Icon className="w-3 h-3" />{label}
                              </a>
                            ) : null
                          )}
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            )}

            {/* Investor links (from first offer if no per-offer links yet) */}
            {hasLinks && offers.length === 0 && (
              <div className="space-y-2">
                <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Links</p>
                <div className="flex flex-wrap gap-2">
                  {LINK_ICONS.map(({ key, label, Icon }) =>
                    offerLinks[key] ? (
                      <a key={key} href={offerLinks[key]} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-xs text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors press-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
                        onClick={(e) => e.stopPropagation()}>
                        <Icon className="w-3.5 h-3.5" />{label}
                      </a>
                    ) : null
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
