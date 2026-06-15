import { createClient } from '@/lib/supabase/server'
import { Search, Users } from 'lucide-react'
import EmptyState from '@/components/empty-state'
import type { ConnectionStatus, StartupStatus } from '@/lib/supabase/types'
import { STARTUP_STATUS_LABELS } from '@/lib/supabase/types'
import FeedHeader from './feed-header'
import FounderCard, { type FeedStartup } from './founder-card'
import InvestorCard, { type FeedInvestor, type FeedOffer } from './investor-card'

type ConnectionInfo = { status: ConnectionStatus; isSender: boolean }

const VALID_STAGES = Object.keys(STARTUP_STATUS_LABELS)

/** Strip characters that would break PostgREST or() filter syntax */
function sanitizeQuery(raw: string | undefined): string {
  return (raw ?? '').replace(/[,%()]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 80)
}

function buildConnMap(
  connections: { sender_id: string; receiver_id: string; status: string }[] | null,
  userId: string
): Record<string, ConnectionInfo> {
  const connMap: Record<string, ConnectionInfo> = {}
  for (const c of connections ?? []) {
    const other = c.sender_id === userId ? c.receiver_id : c.sender_id
    connMap[other] = {
      status: c.status as ConnectionStatus,
      isSender: c.sender_id === userId,
    }
  }
  return connMap
}

export default async function FeedPage({
  searchParams,
}: {
  searchParams: Promise<{ view?: string; q?: string; stage?: string }>
}) {
  const { view: rawView, q: rawQ, stage: rawStage } = await searchParams
  const view = rawView === 'investors' ? 'investors' : 'founders'
  const q = sanitizeQuery(rawQ)
  const stage =
    view === 'founders' && rawStage && VALID_STAGES.includes(rawStage)
      ? (rawStage as StartupStatus)
      : null

  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  const userId = user!.id

  const connectionsQuery = supabase
    .from('connections')
    .select('id, sender_id, receiver_id, status')
    .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)

  let content: React.ReactNode

  if (view === 'founders') {
    let startupsQuery = supabase
      .from('startups')
      .select('*, profiles!inner(id, full_name, avatar_url)')
      .neq('founder_id', userId)
      .eq('published', true)
    if (stage) startupsQuery = startupsQuery.eq('status', stage)
    if (q) startupsQuery = startupsQuery.or(`name.ilike.%${q}%,pitch.ilike.%${q}%,industry.ilike.%${q}%`)

    const [{ data: connections }, { data: startups }] = await Promise.all([
      connectionsQuery,
      startupsQuery.order('created_at', { ascending: false }).limit(40),
    ])
    const connMap = buildConnMap(connections, userId)

    if (!startups?.length) {
      content =
        q || stage ? (
          <EmptyState
            icon={Search}
            title="No matches found"
            hint={q ? `Nothing matches “${q}”. Try a different search or clear the filters.` : 'No startups at this stage yet. Try a different filter.'}
          />
        ) : (
          <EmptyState
            icon={Users}
            title="No startups yet"
            hint="Founders are joining every day — check back soon."
          />
        )
    } else {
      content = (startups as FeedStartup[]).map((s, i) => (
        <FounderCard
          key={s.id}
          startup={s}
          connection={connMap[s.profiles.id] ?? null}
          priority={i === 0}
        />
      ))
    }
  } else {
    let investorsQuery = supabase
      .from('investor_details')
      .select('*, profiles!inner(id, full_name, avatar_url)')
      .neq('investor_id', userId)
    if (q) investorsQuery = investorsQuery.or(`firm_name.ilike.%${q}%,thesis.ilike.%${q}%`)

    const [{ data: connections }, { data: investors }] = await Promise.all([
      connectionsQuery,
      investorsQuery.order('created_at', { ascending: false }).limit(40),
    ])
    const connMap = buildConnMap(connections, userId)

    if (!investors?.length) {
      content = q ? (
        <EmptyState
          icon={Search}
          title="No matches found"
          hint={`Nothing matches “${q}”. Try a different search.`}
        />
      ) : (
        <EmptyState
          icon={Users}
          title="No investors yet"
          hint="Investors are joining every day — check back soon."
        />
      )
    } else {
      // Fetch active offers for these investors (depends on the list above)
      const investorIds = (investors as FeedInvestor[]).map((i) => i.investor_id)
      const { data: offers } = await supabase
        .from('investment_offers')
        .select('id, investor_id, title, amount, stage, sectors, status, links')
        .in('investor_id', investorIds)
        .eq('status', 'active')

      const offersByInvestor: Record<string, FeedOffer[]> = {}
      for (const o of (offers ?? []) as FeedOffer[]) {
        if (!offersByInvestor[o.investor_id]) offersByInvestor[o.investor_id] = []
        offersByInvestor[o.investor_id].push(o)
      }

      content = (investors as FeedInvestor[]).map((inv) => (
        <InvestorCard
          key={inv.id}
          investor={inv}
          connection={connMap[inv.profiles.id] ?? null}
          offers={offersByInvestor[inv.investor_id] ?? []}
        />
      ))
    }
  }

  return (
    <div className="flex flex-col min-h-screen">
      <FeedHeader view={view} q={q} stage={stage} />

      <div className="flex-1 px-4 pt-4 pb-6 max-w-lg mx-auto w-full space-y-4 stagger-children">
        {content}
      </div>
    </div>
  )
}
