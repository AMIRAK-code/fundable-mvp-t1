import { createClient as createSupabaseClient } from '@supabase/supabase-js'

/**
 * Service-role Supabase client. Bypasses RLS, so it must ONLY ever be used in
 * trusted server code (never imported into a client component) and never with
 * user-supplied table/column targets.
 *
 * Used by push delivery, which legitimately needs to read *another* user's
 * push subscriptions — something strict owner-only RLS (correctly) forbids for
 * the regular authenticated client.
 */
export function createAdminClient() {
  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false, autoRefreshToken: false } }
  )
}
