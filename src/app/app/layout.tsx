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

  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name')
    .eq('id', user.id)
    .single() as { data: { full_name: string | null } | null; error: unknown }

  if (!profile?.full_name) redirect('/onboarding')

  return (
    <div className="flex flex-col min-h-screen bg-background">
      <PushInit />
      <main className="flex-1 pb-20">{children}</main>
      <BottomNav />
    </div>
  )
}
