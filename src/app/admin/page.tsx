import { getDashboardData } from '@/lib/data/admin'
import StatCard from './stat-card'
import BarChart from './bar-chart'

const LEVEL_STYLES: Record<string, string> = {
  error: 'text-destructive bg-destructive/10',
  warn: 'text-amber-400 bg-amber-400/10',
  info: 'text-muted-foreground bg-white/5',
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="space-y-3">
      <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
        {title}
      </h2>
      {children}
    </section>
  )
}

export default async function AdminDashboardPage() {
  const { overview, growth, operational, generatedAt } = await getDashboardData()

  return (
    <div className="space-y-8">
      <Section title="Overview">
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
          <StatCard label="Total users" value={overview.totalUsers} hint={`${overview.admins} admin${overview.admins === 1 ? '' : 's'}`} />
          <StatCard label="Founders" value={overview.founders} />
          <StatCard label="Investors" value={overview.investors} />
          <StatCard label="Active users (7d)" value={overview.activeUsers7d} hint="sent a message" />
          <StatCard label="Startups" value={overview.startupsTotal} hint={`${overview.startupsPublished} published`} />
          <StatCard label="Offers" value={overview.offersTotal} hint={`${overview.offersActive} active`} />
          <StatCard label="Connections" value={overview.connectionsAccepted} hint={`${overview.connectionsPending} pending`} />
          <StatCard label="Messages" value={overview.messagesTotal} />
        </div>
      </Section>

      <Section title="Growth (last 30 days)">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          <BarChart title="Signups" data={growth.signups} />
          <BarChart title="Connections" data={growth.connections} />
          <BarChart title="Messages" data={growth.messages} />
        </div>
      </Section>

      <Section title="Operational health">
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <StatCard label="Errors (24h)" value={operational.errors24h} accent={operational.errors24h > 0 ? 'error' : 'default'} />
          <StatCard label="Warnings (24h)" value={operational.warns24h} accent={operational.warns24h > 0 ? 'warn' : 'default'} />
          <StatCard label="Errors (7d)" value={operational.errors7d} accent={operational.errors7d > 0 ? 'error' : 'default'} />
          <StatCard label="Push failures (7d)" value={operational.pushFailures7d} accent={operational.pushFailures7d > 0 ? 'warn' : 'default'} />
        </div>

        <div className="rounded-2xl border border-white/10 bg-white/5 overflow-hidden">
          <p className="px-4 py-2.5 text-sm font-medium border-b border-white/10">Recent events</p>
          {operational.recentEvents.length === 0 ? (
            <p className="px-4 py-6 text-sm text-muted-foreground text-center">
              No events recorded yet.
            </p>
          ) : (
            <ul className="divide-y divide-white/5">
              {operational.recentEvents.map((e) => (
                <li key={e.id} className="flex items-center gap-3 px-4 py-2.5 text-sm">
                  <span className={`px-1.5 py-0.5 rounded text-[10px] font-semibold uppercase ${LEVEL_STYLES[e.level] ?? LEVEL_STYLES.info}`}>
                    {e.level}
                  </span>
                  <span className="font-mono text-xs text-muted-foreground">{e.type}</span>
                  <span className="flex-1 min-w-0 truncate text-muted-foreground">{e.message}</span>
                  <span className="text-[10px] text-muted-foreground tabular-nums flex-shrink-0">
                    {new Date(e.created_at).toLocaleString()}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </Section>

      <p className="text-[10px] text-muted-foreground text-center">
        Cached up to 60s · generated {new Date(generatedAt).toLocaleString()}
      </p>
    </div>
  )
}
