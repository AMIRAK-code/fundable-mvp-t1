import { unstable_cache } from 'next/cache'
import { createAdminClient } from '@/lib/supabase/admin'

// Non-personalized feed data, cached in the Next/Vercel Data Cache so we don't
// hit Supabase on every request. These lists are identical for every viewer —
// per-user concerns (auth, connection state, excluding yourself) are layered on
// in the page at request time and are NOT cached here.
//
// We read with the cookieless service-role client because unstable_cache may
// not access request APIs (cookies/headers), and our RLS policies are scoped to
// the `authenticated` role. The queries themselves constrain the result to the
// publicly-visible subset (published startups / active offers).
//
// Invalidate via revalidateTag('startups' | 'investors' | 'offers', 'max') from
// the mutating server actions in src/app/actions/profile.ts.

export interface FeedStartup {
  id: string
  founder_id: string
  name: string
  pitch: string
  hero_image_url: string | null
  industry: string | null
  links: Record<string, string>
  profiles: { id: string; full_name: string | null; avatar_url: string | null }
}

export interface FeedInvestor {
  id: string
  investor_id: string
  firm_name: string | null
  check_size: string | null
  sectors: string[] | null
  thesis: string | null
  profiles: { id: string; full_name: string | null; avatar_url: string | null }
}

export interface FeedOffer {
  id: string
  investor_id: string
  title: string
  amount: string | null
  stage: string | null
  sectors: string[] | null
  status: string
  links: Record<string, string>
}

const LIST_REVALIDATE_SECONDS = 300

export const getPublishedStartups = unstable_cache(
  async (): Promise<FeedStartup[]> => {
    const supabase = createAdminClient()
    const { data } = await supabase
      .from('startups')
      .select(
        'id, founder_id, name, pitch, hero_image_url, industry, links, profiles!inner(id, full_name, avatar_url)'
      )
      .eq('published', true)
      .order('created_at', { ascending: false })
    return (data ?? []) as unknown as FeedStartup[]
  },
  ['feed:published-startups'],
  { tags: ['startups'], revalidate: LIST_REVALIDATE_SECONDS }
)

export const getActiveInvestors = unstable_cache(
  async (): Promise<{ investors: FeedInvestor[]; offers: FeedOffer[] }> => {
    const supabase = createAdminClient()
    const [investorsRes, offersRes] = await Promise.all([
      supabase
        .from('investor_details')
        .select(
          'id, investor_id, firm_name, check_size, sectors, thesis, profiles!inner(id, full_name, avatar_url)'
        )
        .order('created_at', { ascending: false }),
      supabase
        .from('investment_offers')
        .select('id, investor_id, title, amount, stage, sectors, status, links')
        .eq('status', 'active'),
    ])
    return {
      investors: (investorsRes.data ?? []) as unknown as FeedInvestor[],
      offers: (offersRes.data ?? []) as unknown as FeedOffer[],
    }
  },
  ['feed:active-investors'],
  { tags: ['investors', 'offers'], revalidate: LIST_REVALIDATE_SECONDS }
)

// Per-conversation public profile panel: another user's profile plus their
// published startup (founders) or active offers (investors). Same for every
// viewer, so it's cached by user id (the argument is part of the cache key).
// Tagged broadly so startup/offer/investor edits invalidate it; profile edits
// invalidate via the 'startups'/'investors' tags too (see updateProfile).
export interface PeerProfile {
  otherUser: {
    id: string
    full_name: string | null
    avatar_url: string | null
    role: 'founder' | 'investor'
  } | null
  profileData:
    | { type: 'founder'; startup: Record<string, unknown> }
    | { type: 'investor'; detail: Record<string, unknown>; offers: Record<string, unknown>[] }
    | null
}

export const getPeerProfile = unstable_cache(
  async (userId: string): Promise<PeerProfile> => {
    const supabase = createAdminClient()
    const { data: otherUser } = await supabase
      .from('profiles')
      .select('id, full_name, avatar_url, role')
      .eq('id', userId)
      .maybeSingle()

    if (!otherUser) return { otherUser: null, profileData: null }

    if (otherUser.role === 'founder') {
      const { data: startup } = await supabase
        .from('startups')
        .select('id, name, pitch, hero_image_url, industry, links')
        .eq('founder_id', userId)
        .eq('published', true)
        .limit(1)
        .maybeSingle()
      return {
        otherUser,
        profileData: startup ? { type: 'founder', startup } : null,
      }
    }

    const [{ data: detail }, { data: offers }] = await Promise.all([
      supabase
        .from('investor_details')
        .select('id, firm_name, check_size, sectors, thesis')
        .eq('investor_id', userId)
        .maybeSingle(),
      supabase
        .from('investment_offers')
        .select('id, title, description, amount, stage, sectors, status, links')
        .eq('investor_id', userId)
        .eq('status', 'active'),
    ])

    return {
      otherUser,
      profileData: detail
        ? { type: 'investor', detail, offers: offers ?? [] }
        : null,
    }
  },
  ['feed:peer-profile'],
  { tags: ['startups', 'investors', 'offers'], revalidate: LIST_REVALIDATE_SECONDS }
)
