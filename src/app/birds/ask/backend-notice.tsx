import { Database } from 'lucide-react'

/**
 * The species guide is static, but the question board needs Supabase. Shown
 * instead of an error when the environment has no credentials.
 */
export default function BackendNotice() {
  return (
    <div className="flex gap-3 rounded-2xl border border-[var(--bird-accent)]/30 bg-[var(--bird-accent)]/10 p-4">
      <Database className="mt-0.5 h-4 w-4 shrink-0 text-[var(--bird-accent)]" />
      <div className="text-sm leading-relaxed">
        <p className="font-medium">The question board is not connected yet.</p>
        <p className="mt-1 text-muted-foreground">
          Set <code className="text-xs">NEXT_PUBLIC_SUPABASE_URL</code> and{' '}
          <code className="text-xs">NEXT_PUBLIC_SUPABASE_ANON_KEY</code>, then run the
          migration in <code className="text-xs">supabase/migrations/0002_birds_qa.sql</code>.
          The species guide works without it.
        </p>
      </div>
    </div>
  )
}
