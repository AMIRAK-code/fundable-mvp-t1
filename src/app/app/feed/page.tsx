import { createClient } from '@/lib/supabase/server'
import type { ConnectionStatus } from '@/lib/supabase/types'
import { getPublishedStartups, getActiveInvestors } from '@/lib/data/feed'
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
  // Cached list (same for everyone); exclude yourself at request time.
  const startups = (await getPublishedStartups()).filter(
    (s) => s.founder_id !== userId
  )

  if (!startups.length) {
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
          connection={connMap[s.profiles.id] ?? null}
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
  // Cached list (same for everyone); exclude yourself at request time.
  const { investors: allInvestors, offers } = await getActiveInvestors()
  const investors = allInvestors.filter((i) => i.investor_id !== userId)

  if (!investors.length) {
    return (
      <p className="text-center text-muted-foreground text-sm pt-20">
        No investors listed yet. Check back soon.
      </p>
    )
  }

  const offersByInvestor: Record<string, typeof offers> = {}
  for (const o of offers) {
    if (!offersByInvestor[o.investor_id]) offersByInvestor[o.investor_id] = []
    offersByInvestor[o.investor_id]!.push(o)
  }

  return (
    <>
      {investors.map((inv) => (
        <InvestorCard
          key={inv.id}
          investor={inv as Parameters<typeof InvestorCard>[0]['investor']}
          connection={connMap[inv.profiles.id] ?? null}
          offers={offersByInvestor[inv.investor_id] ?? []}
        />
      ))}
    </>
  )
}
