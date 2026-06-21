import type { Profile, Startup, InvestorDetail, InvestmentOffer } from '@/lib/supabase/types'

export interface CompletionStep {
  key: string
  label: string
  done: boolean
}

export interface CompletionSummary {
  steps: CompletionStep[]
  doneCount: number
  totalCount: number
  percent: number
}

export function getFounderCompletion(profile: Profile, startups: Startup[]): CompletionSummary {
  const hasStartup = startups.length > 0
  const hasPublished = startups.some((s) => s.published)
  const hasHero = startups.some((s) => !!s.hero_image_url)

  const steps: CompletionStep[] = [
    { key: 'avatar', label: 'Add a profile photo', done: !!profile.avatar_url },
    { key: 'bio', label: 'Write a short bio', done: !!profile.bio && profile.bio.trim().length >= 20 },
    { key: 'startup', label: 'Add your first startup', done: hasStartup },
    { key: 'hero', label: 'Upload a hero image', done: hasHero },
    { key: 'publish', label: 'Publish a startup to the feed', done: hasPublished },
  ]
  return summarize(steps)
}

export function getInvestorCompletion(
  profile: Profile,
  details: InvestorDetail | null,
  offers: InvestmentOffer[]
): CompletionSummary {
  const hasActiveOffer = offers.some((o) => o.status === 'active')
  const sectors = details?.sectors ?? []

  const steps: CompletionStep[] = [
    { key: 'avatar', label: 'Add a profile photo', done: !!profile.avatar_url },
    { key: 'bio', label: 'Write a short bio', done: !!profile.bio && profile.bio.trim().length >= 20 },
    { key: 'firm', label: 'Set your firm name', done: !!details?.firm_name?.trim() },
    { key: 'thesis', label: 'Describe your investment thesis', done: !!details?.thesis && details.thesis.trim().length >= 20 },
    { key: 'sectors', label: 'Pick at least one sector', done: sectors.length > 0 },
    { key: 'offer', label: 'Post an active offer', done: hasActiveOffer },
  ]
  return summarize(steps)
}

function summarize(steps: CompletionStep[]): CompletionSummary {
  const doneCount = steps.filter((s) => s.done).length
  const totalCount = steps.length
  const percent = totalCount === 0 ? 0 : Math.round((doneCount / totalCount) * 100)
  return { steps, doneCount, totalCount, percent }
}

export function normalizeSector(input: string): string {
  return input.trim().toLowerCase().replace(/\s+/g, ' ')
}

export function dedupeSectors(input: string[]): string[] {
  const seen = new Set<string>()
  const out: string[] = []
  for (const raw of input) {
    const norm = normalizeSector(raw)
    if (!norm || seen.has(norm)) continue
    seen.add(norm)
    out.push(norm)
  }
  return out
}
