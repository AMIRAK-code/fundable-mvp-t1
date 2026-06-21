import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import BottomNav from '@/components/bottom-nav'
import PushInit from '@/components/push-init'

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  // Enforce MFA: if the account has a verified second factor but this session
  // is still aal1, send them to the challenge before any app route renders.
  const { data: aal } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
  if (aal?.nextLevel === 'aal2' && aal.nextLevel !== aal.currentLevel) {
    redirect('/auth/mfa')
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name')
    .eq('id', user.id)
    .single() as { data: { full_name: string | null } | null; error: unknown }

  if (!profile?.full_name) redirect('/onboarding')

  return (
    <div className="flex flex-col min-h-safe-screen bg-background">
      <PushInit />
      <main className="flex-1 pb-[calc(64px+env(safe-area-inset-bottom)+8px)]">
        {children}
      </main>
      <BottomNav />
    </div>
  )
}
