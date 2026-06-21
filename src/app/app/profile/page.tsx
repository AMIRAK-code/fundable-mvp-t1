import { createClient } from '@/lib/supabase/server'
import type { Profile, Startup, InvestorDetail, InvestmentOffer } from '@/lib/supabase/types'
import { getFounderCompletion, getInvestorCompletion } from '@/lib/profile-completion'
import FounderProfile from './founder-profile'
import InvestorProfile from './investor-profile'
import ProfileHeader from './profile-header'
import ProfileCompletion from './profile-completion'

export default async function ProfilePage() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { data: profile } = (await supabase
    .from('profiles')
    .select('*')
    .eq('id', user!.id)
    .single()) as { data: Profile | null; error: unknown }

  if (!profile) return null

  if (profile.role === 'founder') {
    const { data: startups } = (await supabase
      .from('startups')
      .select('*')
      .eq('founder_id', user!.id)
      .order('created_at', { ascending: false })) as { data: Startup[] | null; error: unknown }
    const list = startups ?? []
    const completion = getFounderCompletion(profile, list)

    return (
      <div className="mx-auto w-full max-w-lg md:max-w-3xl px-3 sm:px-5 pt-[calc(env(safe-area-inset-top)+1rem)] pb-6 space-y-6">
        <ProfileHeader profile={profile} />
        <ProfileCompletion summary={completion} />
        <FounderProfile startups={list} />
      </div>
    )
  }

  const [detailsRes, offersRes] = await Promise.all([
    supabase.from('investor_details').select('*').eq('investor_id', user!.id).maybeSingle(),
    supabase
      .from('investment_offers')
      .select('*')
      .eq('investor_id', user!.id)
      .order('created_at', { ascending: false }),
  ])
  const details = (detailsRes.data ?? null) as InvestorDetail | null
  const offers = (offersRes.data ?? []) as InvestmentOffer[]
  const completion = getInvestorCompletion(profile, details, offers)

  return (
    <div className="mx-auto w-full max-w-lg md:max-w-3xl px-3 sm:px-5 pt-[calc(env(safe-area-inset-top)+1rem)] pb-6 space-y-6">
      <ProfileHeader profile={profile} />
      <ProfileCompletion summary={completion} />
      <InvestorProfile details={details} offers={offers} />
    </div>
  )
}
