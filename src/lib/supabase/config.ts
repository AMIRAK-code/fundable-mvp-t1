/**
 * The public bird study area renders without a backend, so every entry point
 * that touches Supabase checks this first rather than throwing on a missing
 * URL or key.
 */
export function isSupabaseConfigured(): boolean {
  return Boolean(
    process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  )
}
