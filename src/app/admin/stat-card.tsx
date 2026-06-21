export default function StatCard({
  label,
  value,
  hint,
  accent,
}: {
  label: string
  value: string | number
  hint?: string
  accent?: 'default' | 'warn' | 'error'
}) {
  const valueColor =
    accent === 'error'
      ? 'text-destructive'
      : accent === 'warn'
        ? 'text-amber-400'
        : 'text-foreground'

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
      <p className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
        {label}
      </p>
      <p className={`mt-1.5 text-2xl font-bold tabular-nums ${valueColor}`}>
        {typeof value === 'number' ? value.toLocaleString() : value}
      </p>
      {hint && <p className="mt-0.5 text-xs text-muted-foreground">{hint}</p>}
    </div>
  )
}
