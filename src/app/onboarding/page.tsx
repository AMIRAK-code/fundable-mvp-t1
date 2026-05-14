import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import OnboardingForm from './onboarding-form'

export default async function OnboardingPage() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name, role')
    .eq('id', user.id)
    .single() as { data: { full_name: string | null; role: string } | null; error: unknown }

  // Already onboarded — go to the feed
  if (profile?.full_name) redirect('/app/feed')

  return (
    <div className="min-h-safe-screen flex items-center justify-center px-4 py-8 sm:py-12 pt-[calc(env(safe-area-inset-top)+2rem)] pb-[calc(env(safe-area-inset-bottom)+2rem)] bg-background">
      <div className="w-full max-w-md">
        <div className="text-center mb-6 sm:mb-8">
          <h1 className="text-3xl sm:text-4xl font-bold tracking-tight">
            Fund<span className="text-[var(--brand-primary)]">able</span>
          </h1>
          <p className="text-muted-foreground mt-2 text-sm">
            Let's set up your profile
          </p>
        </div>
        <OnboardingForm role={(profile?.role ?? 'founder') as import('@/lib/supabase/types').Role} />
      </div>
    </div>
  )
}
