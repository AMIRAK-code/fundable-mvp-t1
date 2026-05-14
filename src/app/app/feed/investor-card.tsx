import Image from 'next/image'
import { User, Briefcase } from 'lucide-react'
import ConnectButton from './connect-button'
import type { ConnectionStatus } from '@/lib/supabase/types'

interface Investor {
  id: string
  investor_id: string
  firm_name: string | null
  check_size: string | null
  sectors: string[] | null
  thesis: string | null
  profiles: { id: string; full_name: string | null; avatar_url: string | null }
}

interface Offer {
  id: string
  investor_id: string
  title: string
  amount: string | null
  stage: string | null
  sectors: string[] | null
  status: string
}

interface Props {
  investor: Investor
  connection: { status: ConnectionStatus } | null
  offers?: Offer[]
}

export default function InvestorCard({ investor, connection, offers = [] }: Props) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-5 space-y-4">
      <div className="flex items-start gap-4">
        {/* Avatar */}
        <div className="flex-shrink-0">
          {investor.profiles.avatar_url ? (
            <Image
              src={investor.profiles.avatar_url}
              alt={investor.profiles.full_name ?? ''}
              width={52}
              height={52}
              className="rounded-full object-cover border border-white/10"
            />
          ) : (
            <div className="w-[52px] h-[52px] rounded-full bg-white/10 border border-white/10 flex items-center justify-center">
              <User className="w-5 h-5 text-muted-foreground" />
            </div>
          )}
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-foreground leading-tight">{investor.profiles.full_name}</p>
          {investor.firm_name && (
            <p className="text-xs text-[var(--brand-primary)] font-medium mt-0.5">{investor.firm_name}</p>
          )}
          {investor.check_size && (
            <p className="text-xs text-muted-foreground mt-0.5">Check: {investor.check_size}</p>
          )}
        </div>

        <ConnectButton
          receiverId={investor.profiles.id}
          status={connection?.status ?? null}
        />
      </div>

      {/* Sectors */}
      {investor.sectors && investor.sectors.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {investor.sectors.map((s) => (
            <span
              key={s}
              className="px-2 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] text-[10px] font-semibold uppercase tracking-wide"
            >
              {s}
            </span>
          ))}
        </div>
      )}

      {/* Thesis */}
      {investor.thesis && (
        <p className="text-sm text-muted-foreground line-clamp-2 leading-relaxed">{investor.thesis}</p>
      )}

      {/* Active offers */}
      {offers.length > 0 && (
        <div className="space-y-2 pt-1 border-t border-white/10">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
            <Briefcase className="w-3 h-3" /> Active Offers
          </p>
          {offers.map((o) => (
            <div key={o.id} className="rounded-xl bg-white/5 border border-white/10 px-3 py-2.5">
              <div className="flex items-baseline justify-between gap-2">
                <p className="text-sm font-medium text-foreground truncate">{o.title}</p>
                {o.amount && <span className="text-xs text-[var(--brand-primary)] flex-shrink-0">{o.amount}</span>}
              </div>
              {(o.stage || (o.sectors && o.sectors.length > 0)) && (
                <div className="flex items-center gap-2 mt-1 flex-wrap">
                  {o.stage && <span className="text-[10px] text-muted-foreground">{o.stage}</span>}
                  {o.sectors?.slice(0, 3).map((s) => (
                    <span key={s} className="text-[10px] px-1.5 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] font-semibold uppercase tracking-wide">
                      {s}
                    </span>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
