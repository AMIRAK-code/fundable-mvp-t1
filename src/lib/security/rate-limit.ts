// Lightweight in-memory fixed-window rate limiter.
//
// NOTE: state lives in the server process, so limits are per-instance and
// reset on redeploy. It meaningfully blunts spam/abuse from a single client
// but is best-effort. For hard guarantees across a horizontally-scaled
// deployment, back this with a durable store (e.g. Upstash/Redis).

type Window = { count: number; resetAt: number }

const buckets = new Map<string, Window>()

/**
 * Returns true if the action identified by `key` is allowed under `limit`
 * calls per `windowMs`, false if the caller should be throttled.
 */
export function rateLimit(key: string, limit: number, windowMs: number): boolean {
  const now = Date.now()
  const existing = buckets.get(key)

  if (!existing || now > existing.resetAt) {
    buckets.set(key, { count: 1, resetAt: now + windowMs })
    return true
  }
  if (existing.count >= limit) return false
  existing.count += 1
  return true
}
