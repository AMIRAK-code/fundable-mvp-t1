const MIN = 60_000
const HOUR = 3_600_000
const DAY = 86_400_000

/** Compact relative time: "now", "5m", "2h", "3d", then "Jan 5" / "Jan 5, 2025" */
export function timeAgo(iso: string): string {
  const then = new Date(iso)
  const diff = Date.now() - then.getTime()
  if (diff < MIN) return 'now'
  if (diff < HOUR) return `${Math.floor(diff / MIN)}m`
  if (diff < DAY) return `${Math.floor(diff / HOUR)}h`
  if (diff < 7 * DAY) return `${Math.floor(diff / DAY)}d`
  const sameYear = then.getFullYear() === new Date().getFullYear()
  return then.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    ...(sameYear ? {} : { year: 'numeric' }),
  })
}

/** "14:32" in the user's locale */
export function timeOfDay(iso: string): string {
  return new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

/** "Today" | "Yesterday" | "Mon, Jan 5" — for chat day separators */
export function dayLabel(iso: string): string {
  const then = new Date(iso)
  const now = new Date()
  const startOfDay = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
  const dayDiff = Math.round((startOfDay(now) - startOfDay(then)) / DAY)
  if (dayDiff === 0) return 'Today'
  if (dayDiff === 1) return 'Yesterday'
  return then.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })
}

export function sameDay(aIso: string, bIso: string): boolean {
  const a = new Date(aIso)
  const b = new Date(bIso)
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}
