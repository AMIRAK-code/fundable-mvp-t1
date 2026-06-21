import type { DayPoint } from '@/lib/data/admin'

// Dependency-free SVG bar chart (pure server component). Renders one bar per
// day, scaled to the series max, with a couple of axis labels.
export default function BarChart({
  title,
  data,
}: {
  title: string
  data: DayPoint[]
}) {
  const max = Math.max(1, ...data.map((d) => d.value))
  const total = data.reduce((sum, d) => sum + d.value, 0)
  const W = 100
  const H = 36
  const gap = 0.6
  const barW = data.length > 0 ? W / data.length - gap : W
  const fmt = (iso: string) => {
    const [, m, d] = iso.split('-')
    return `${Number(m)}/${Number(d)}`
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
      <div className="flex items-baseline justify-between">
        <p className="text-sm font-medium">{title}</p>
        <p className="text-xs text-muted-foreground">
          {total.toLocaleString()} · last {data.length}d
        </p>
      </div>

      <svg
        viewBox={`0 0 ${W} ${H}`}
        preserveAspectRatio="none"
        className="mt-3 w-full h-24"
        role="img"
        aria-label={`${title}: ${total} over ${data.length} days`}
      >
        {data.map((d, i) => {
          const h = (d.value / max) * (H - 2)
          return (
            <rect
              key={d.date}
              x={i * (barW + gap)}
              y={H - h}
              width={barW}
              height={h}
              rx={0.4}
              className="fill-[var(--brand-primary)]"
              opacity={d.value === 0 ? 0.25 : 0.85}
            >
              <title>{`${d.date}: ${d.value}`}</title>
            </rect>
          )
        })}
      </svg>

      {data.length > 0 && (
        <div className="mt-1.5 flex justify-between text-[10px] text-muted-foreground tabular-nums">
          <span>{fmt(data[0].date)}</span>
          <span>peak {max}</span>
          <span>{fmt(data[data.length - 1].date)}</span>
        </div>
      )}
    </div>
  )
}
