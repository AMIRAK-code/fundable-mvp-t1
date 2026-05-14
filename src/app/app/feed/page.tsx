import { createClient } from '@/lib/supabase/server'
import type { ConnectionStatus } from '@/lib/supabase/types'
import FeedHeader from './feed-header'
import FounderCard from './founder-card'
import InvestorCard from './investor-card'

type ConnectionInfo = { status: ConnectionStatus; isSender: boolean }

export default async function FeedPage({
  searchParams,
}: {
  searchParams: Promise<{ view?: string }>
}) {
  const { view: rawView } = await searchParams
  const view = rawView === 'investors' ? 'investors' : 'founders'

  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Build a map of otherId → connection info for button states
  const { data: connections } = await supabase
    .from('connections')
    .select('id, sender_id, receiver_id, status')
    .or(`sender_id.eq.${user!.id},receiver_id.eq.${user!.id}`)

  const connMap: Record<string, ConnectionInfo> = {}
  for (const c of connections ?? []) {
    const other = c.sender_id === user!.id ? c.receiver_id : c.sender_id
    connMap[other] = {
      status: c.status as ConnectionStatus,
      isSender: c.sender_id === user!.id,
    }
  }

  return (
    <div className="flex flex-col min-h-screen">
      <FeedHeader view={view} />

      <div className="flex-1 px-4 pt-4 pb-6 max-w-lg mx-auto w-full space-y-4">
        {view === 'founders' ? (
          <FoundersFeed userId={user!.id} connMap={connMap} />
        ) : (
          <InvestorsFeed userId={user!.id} connMap={connMap} />
        )}
      </div>
    </div>
  )
}

async function FoundersFeed({
  userId,
  connMap,
}: {
  userId: string
  connMap: Record<string, ConnectionInfo>
}) {
  const supabase = await createClient()
  const { data: startups } = await supabase
    .from('startups')
    .select('*, profiles!inner(id, full_name, avatar_url)')
    .neq('founder_id', userId)
    .eq('published', true)
    .order('created_at', { ascending: false })

  if (!startups?.length) {
    return (
      <p className="text-center text-muted-foreground text-sm pt-20">
        No startups listed yet. Check back soon.
      </p>
    )
  }

  return (
    <>
      {startups.map((s) => (
        <FounderCard
          key={s.id}
          startup={s as Parameters<typeof FounderCard>[0]['startup']}
          connection={connMap[(s.profiles as { id: string }).id] ?? null}
        />
      ))}
    </>
  )
}

async function InvestorsFeed({
  userId,
  connMap,
}: {
  userId: string
  connMap: Record<string, ConnectionInfo>
}) {
  const supabase = await createClient()
  const { data: investors } = await supabase
    .from('investor_details')
    .select('*, profiles!inner(id, full_name, avatar_url)')
    .neq('investor_id', userId)
    .order('created_at', { ascending: false })

  if (!investors?.length) {
    return (
      <p className="text-center text-muted-foreground text-sm pt-20">
        No investors listed yet. Check back soon.
      </p>
    )
  }

  // Fetch active offers for these investors
  const investorIds = investors.map((i) => i.investor_id)
  const { data: offers } = await supabase
    .from('investment_offers')
    .select('id, investor_id, title, amount, stage, sectors, status, links')
    .in('investor_id', investorIds)
    .eq('status', 'active')

  const offersByInvestor: Record<string, typeof offers> = {}
  for (const o of offers ?? []) {
    if (!offersByInvestor[o.investor_id]) offersByInvestor[o.investor_id] = []
    offersByInvestor[o.investor_id]!.push(o)
  }

  return (
    <>
      {investors.map((inv) => (
        <InvestorCard
          key={inv.id}
          investor={inv as Parameters<typeof InvestorCard>[0]['investor']}
          connection={connMap[(inv.profiles as { id: string }).id] ?? null}
          offers={offersByInvestor[inv.investor_id] ?? []}
        />
      ))}
    </>
  )
}
