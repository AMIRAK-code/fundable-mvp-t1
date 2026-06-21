import { unstable_cache } from 'next/cache'
import { createAdminClient } from '@/lib/supabase/admin'

// Admin monitoring metrics. Computed with the service-role client (the /admin
// route gates access on profiles.is_admin before this runs) and cached briefly
// so repeated dashboard loads don't hammer the database.
//
// Scalability note: time-series here fetch raw rows for the last 30 days and
// bucket in JS — fine at current volume. At scale, replace these with SQL
// aggregation (date_trunc + group by) or a materialized view / rollup table.

export interface DayPoint {
  date: string // YYYY-MM-DD
  value: number
}

export interface EventRow {
  id: string
  type: string
  level: 'info' | 'warn' | 'error'
  message: string | null
  created_at: string
}

export interface DashboardData {
  overview: {
    totalUsers: number
    founders: number
    investors: number
    admins: number
    startupsTotal: number
    startupsPublished: number
    offersActive: number
    offersTotal: number
    connectionsPending: number
    connectionsAccepted: number
    messagesTotal: number
    pushSubscribers: number
    activeUsers7d: number
  }
  growth: {
    signups: DayPoint[]
    connections: DayPoint[]
    messages: DayPoint[]
  }
  operational: {
    errors24h: number
    warns24h: number
    errors7d: number
    pushFailures7d: number
    recentEvents: EventRow[]
  }
  generatedAt: string
}

const DAY_MS = 86_400_000

function bucketByDay(rows: { created_at: string }[], days: number): DayPoint[] {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const counts = new Map<string, number>()
  const keys: string[] = []
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(today.getTime() - i * DAY_MS)
    const key = d.toISOString().slice(0, 10)
    counts.set(key, 0)
    keys.push(key)
  }
  for (const r of rows) {
    const key = r.created_at.slice(0, 10)
    if (counts.has(key)) counts.set(key, counts.get(key)! + 1)
  }
  return keys.map((date) => ({ date, value: counts.get(date) ?? 0 }))
}

export const getDashboardData = unstable_cache(
  async (): Promise<DashboardData> => {
    const supabase = createAdminClient()
    const now = Date.now()
    const since30d = new Date(now - 30 * DAY_MS).toISOString()
    const since7d = new Date(now - 7 * DAY_MS).toISOString()
    const since24h = new Date(now - DAY_MS).toISOString()

    const exact = { count: 'exact' as const, head: true }

    const [
      totalUsers,
      founders,
      investors,
      admins,
      startupsTotal,
      startupsPublished,
      offersActive,
      offersTotal,
      connectionsPending,
      connectionsAccepted,
      messagesTotal,
      pushSubscribers,
      signupRows,
      connectionRows,
      messageRows,
      events7d,
      recentEvents,
    ] = await Promise.all([
      supabase.from('profiles').select('*', exact),
      supabase.from('profiles').select('*', exact).eq('role', 'founder'),
      supabase.from('profiles').select('*', exact).eq('role', 'investor'),
      supabase.from('profiles').select('*', exact).eq('is_admin', true),
      supabase.from('startups').select('*', exact),
      supabase.from('startups').select('*', exact).eq('published', true),
      supabase.from('investment_offers').select('*', exact).eq('status', 'active'),
      supabase.from('investment_offers').select('*', exact),
      supabase.from('connections').select('*', exact).eq('status', 'pending'),
      supabase.from('connections').select('*', exact).eq('status', 'accepted'),
      supabase.from('messages').select('*', exact),
      supabase.from('push_subscriptions').select('*', exact),
      supabase.from('profiles').select('created_at').gte('created_at', since30d),
      supabase.from('connections').select('created_at').gte('created_at', since30d),
      supabase.from('messages').select('sender_id, created_at').gte('created_at', since30d),
      supabase.from('app_events').select('level, created_at, type').gte('created_at', since7d),
      supabase
        .from('app_events')
        .select('id, type, level, message, created_at')
        .order('created_at', { ascending: false })
        .limit(25),
    ])

    const msgRows = (messageRows.data ?? []) as { sender_id: string; created_at: string }[]
    const activeUsers7d = new Set(
      msgRows.filter((m) => m.created_at >= since7d).map((m) => m.sender_id)
    ).size

    const evRows = (events7d.data ?? []) as { level: string; created_at: string; type: string }[]

    return {
      overview: {
        totalUsers: totalUsers.count ?? 0,
        founders: founders.count ?? 0,
        investors: investors.count ?? 0,
        admins: admins.count ?? 0,
        startupsTotal: startupsTotal.count ?? 0,
        startupsPublished: startupsPublished.count ?? 0,
        offersActive: offersActive.count ?? 0,
        offersTotal: offersTotal.count ?? 0,
        connectionsPending: connectionsPending.count ?? 0,
        connectionsAccepted: connectionsAccepted.count ?? 0,
        messagesTotal: messagesTotal.count ?? 0,
        pushSubscribers: pushSubscribers.count ?? 0,
        activeUsers7d,
      },
      growth: {
        signups: bucketByDay(signupRows.data ?? [], 30),
        connections: bucketByDay(connectionRows.data ?? [], 30),
        messages: bucketByDay(msgRows, 30),
      },
      operational: {
        errors24h: evRows.filter((e) => e.level === 'error' && e.created_at >= since24h).length,
        warns24h: evRows.filter((e) => e.level === 'warn' && e.created_at >= since24h).length,
        errors7d: evRows.filter((e) => e.level === 'error').length,
        pushFailures7d: evRows.filter((e) => e.type === 'push.delivery_failed').length,
        recentEvents: (recentEvents.data ?? []) as EventRow[],
      },
      generatedAt: new Date().toISOString(),
    }
  },
  ['admin:dashboard'],
  { tags: ['admin-metrics'], revalidate: 60 }
)
