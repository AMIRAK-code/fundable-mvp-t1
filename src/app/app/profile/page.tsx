import Image from 'next/image'
import { User } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'
import type { Profile, Startup, InvestorDetail, InvestmentOffer } from '@/lib/supabase/types'
import FounderProfile from './founder-profile'
import InvestorProfile from './investor-profile'
import LogoutButton from './logout-button'

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

  return (
    <div className="max-w-lg mx-auto px-3 sm:px-4 pt-[calc(env(safe-area-inset-top)+1rem)] pb-4 space-y-5">
      {/* Profile header */}
      <div className="flex items-center gap-3 sm:gap-4">
        {profile.avatar_url ? (
          <Image
            src={profile.avatar_url}
            alt={profile.full_name ?? ''}
            width={56}
            height={56}
            className="rounded-full object-cover border-2 border-[var(--brand-primary)]/40 w-14 h-14 sm:w-16 sm:h-16 flex-shrink-0"
          />
        ) : (
          <div className="w-14 h-14 sm:w-16 sm:h-16 rounded-full bg-white/10 border border-white/10 flex items-center justify-center flex-shrink-0">
            <User className="w-6 h-6 sm:w-7 sm:h-7 text-muted-foreground" />
          </div>
        )}
        <div className="flex-1 min-w-0">
          <p className="font-bold text-base sm:text-lg leading-tight truncate">{profile.full_name}</p>
          <p className="text-xs text-[var(--brand-primary)] font-semibold capitalize mt-0.5">
            {profile.role}
          </p>
          {profile.bio && (
            <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{profile.bio}</p>
          )}
        </div>
      </div>

      <hr className="border-white/10" />

      {/* Role-specific section */}
      {profile.role === 'founder' ? (
        <FounderProfileSection userId={user!.id} />
      ) : (
        <InvestorProfileSection userId={user!.id} />
      )}

      <LogoutButton />
    </div>
  )
}

async function FounderProfileSection({ userId }: { userId: string }) {
  const supabase = await createClient()
  const { data: startups } = (await supabase
    .from('startups')
    .select('*')
    .eq('founder_id', userId)
    .order('created_at', { ascending: false })) as { data: Startup[] | null; error: unknown }

  return <FounderProfile startups={startups ?? []} />
}

async function InvestorProfileSection({ userId }: { userId: string }) {
  const supabase = await createClient()
  const [detailsRes, offersRes] = await Promise.all([
    supabase.from('investor_details').select('*').eq('investor_id', userId).maybeSingle(),
    supabase.from('investment_offers').select('*').eq('investor_id', userId).order('created_at', { ascending: false }),
  ])

  const details = (detailsRes.data ?? null) as InvestorDetail | null
  const offers = (offersRes.data ?? []) as InvestmentOffer[]

  return <InvestorProfile details={details} offers={offers} />
}
