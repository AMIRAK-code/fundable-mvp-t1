import { createAdminClient } from '@/lib/supabase/admin'

export type EventLevel = 'info' | 'warn' | 'error'

/**
 * Records an operational event to `app_events` (best-effort: never throws, so a
 * logging failure can't break the calling path). This is the seam for future
 * monitoring — today it's backed by a Postgres table; a Sentry/Vercel sink
 * could be added here without touching call sites.
 */
export async function logEvent(
  type: string,
  opts: { level?: EventLevel; message?: string; context?: Record<string, unknown> } = {}
): Promise<void> {
  try {
    const supabase = createAdminClient()
    await supabase.from('app_events').insert({
      type,
      level: opts.level ?? 'info',
      message: opts.message ?? null,
      context: opts.context ?? {},
    })
  } catch {
    // Swallow — monitoring must not affect the request it's observing.
  }
}
