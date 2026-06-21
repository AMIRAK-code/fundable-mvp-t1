// Centralized URL hardening helpers (isomorphic — safe in server and client).

/**
 * Returns a normalized http(s) URL, or null if the input is not a safe
 * external URL. Blocks dangerous schemes like `javascript:`, `data:`, and
 * `vbscript:` that would otherwise execute when used as an anchor `href`.
 * Bare domains (e.g. "example.com") are upgraded to https://.
 */
export function safeExternalUrl(raw: string | null | undefined): string | null {
  if (!raw) return null
  const value = raw.trim()
  if (!value) return null

  const parse = (candidate: string): string | null => {
    try {
      const u = new URL(candidate)
      return u.protocol === 'http:' || u.protocol === 'https:' ? u.toString() : null
    } catch {
      return null
    }
  }

  const direct = parse(value)
  if (direct) return direct

  // Upgrade a scheme-less bare domain ("acme.com/foo") to https.
  if (!value.includes(':') && /^[\w-]+(\.[\w-]+)+/.test(value)) {
    return parse(`https://${value}`)
  }
  return null
}

/**
 * Restricts a post-auth redirect target to an in-app relative path, defeating
 * open-redirect payloads such as `//evil.com`, `/\evil.com`, and `@evil.com`.
 */
export function safeRelativePath(
  next: string | null | undefined,
  fallback = '/app/feed'
): string {
  if (typeof next !== 'string' || !next.startsWith('/')) return fallback
  if (next.startsWith('//') || next.startsWith('/\\')) return fallback
  return next
}
