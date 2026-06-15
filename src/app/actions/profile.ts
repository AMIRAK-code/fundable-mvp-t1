'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

/** Safely read a string field: null if absent/not a string, otherwise trimmed + capped. */
function str(formData: FormData, key: string, max: number): string | null {
  const v = formData.get(key)
  if (typeof v !== 'string') return null
  return v.trim().slice(0, max)
}

export async function upsertStartup(
  _prevState: { error: string | null; success: boolean },
  formData: FormData
): Promise<{ error: string | null; success: boolean }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated', success: false }

  const id = str(formData, 'id', 64)
  const name = str(formData, 'name', 80)
  const pitch = str(formData, 'pitch', 200)
  if (!name || !pitch) return { error: 'Missing required field', success: false }

  const industry = str(formData, 'industry', 80) ?? ''
  const status = str(formData, 'status', 40) || null
  const heroFile = formData.get('hero_image')

  let heroImageUrl: string | undefined
  if (heroFile instanceof File && heroFile.size > 0) {
    const ext = heroFile.name.split('.').pop() ?? 'jpg'
    const path = `${user.id}/${Date.now()}.${ext}`
    const { error: uploadError } = await supabase.storage
      .from('hero-images')
      .upload(path, heroFile, { upsert: true })
    if (uploadError) return { error: uploadError.message, success: false }
    const {
      data: { publicUrl },
    } = supabase.storage.from('hero-images').getPublicUrl(path)
    heroImageUrl = publicUrl
  }

  const links: Record<string, string> = {}
  for (const key of ['github', 'linkedin', 'reddit', 'instagram', 'website']) {
    const val = str(formData, `link_${key}`, 300)
    if (val) links[key] = val
  }

  const payload = {
    name,
    pitch,
    industry,
    status,
    links,
    ...(heroImageUrl ? { hero_image_url: heroImageUrl } : {}),
  }

  if (id) {
    const { error } = await supabase
      .from('startups')
      .update(payload)
      .eq('id', id)
      .eq('founder_id', user.id)
    if (error) return { error: error.message, success: false }
  } else {
    const { error } = await supabase
      .from('startups')
      .insert({ founder_id: user.id, ...payload })
    if (error) return { error: error.message, success: false }
  }

  revalidatePath('/app/profile')
  revalidatePath('/app/feed')
  return { error: null, success: true }
}

export async function toggleStartupPublished(
  startupId: string,
  published: boolean
): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('startups')
    .update({ published })
    .eq('id', startupId)
    .eq('founder_id', user.id)

  if (error) return { error: error.message }
  revalidatePath('/app/profile')
  revalidatePath('/app/feed')
  return { error: null }
}

export async function deleteStartup(startupId: string): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('startups')
    .delete()
    .eq('id', startupId)
    .eq('founder_id', user.id)

  if (error) return { error: error.message }
  revalidatePath('/app/profile')
  revalidatePath('/app/feed')
  return { error: null }
}

export async function upsertInvestorDetails(
  _prevState: { error: string | null; success: boolean },
  formData: FormData
): Promise<{ error: string | null; success: boolean }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated', success: false }

  const firmName = str(formData, 'firm_name', 80)
  const checkSize = str(formData, 'check_size', 80)
  const thesis = str(formData, 'thesis', 1000)
  if (firmName === null || checkSize === null || thesis === null) {
    return { error: 'Missing required field', success: false }
  }
  const status = str(formData, 'status', 40) || null
  const sectorsRaw = str(formData, 'sectors', 500) ?? ''
  const sectors = sectorsRaw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)

  const { error } = await supabase.from('investor_details').upsert(
    {
      investor_id: user.id,
      firm_name: firmName,
      check_size: checkSize,
      thesis,
      status,
      sectors,
    },
    { onConflict: 'investor_id' }
  )

  if (error) return { error: error.message, success: false }
  revalidatePath('/app/profile')
  revalidatePath('/app/feed')
  return { error: null, success: true }
}

export async function upsertInvestmentOffer(
  _prevState: { error: string | null; success: boolean },
  formData: FormData
): Promise<{ error: string | null; success: boolean }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated', success: false }

  const id = str(formData, 'id', 64)
  const title = str(formData, 'title', 80)
  const description = str(formData, 'description', 1000)
  if (!title || !description) return { error: 'Missing required field', success: false }

  const amount = str(formData, 'amount', 80) ?? ''
  const stage = str(formData, 'stage', 40) ?? ''
  const sectorsRaw = str(formData, 'sectors', 500) ?? ''
  const sectors = sectorsRaw.split(',').map((s) => s.trim()).filter(Boolean)

  const links: Record<string, string> = {}
  for (const key of ['github', 'linkedin', 'reddit', 'instagram', 'website']) {
    const val = str(formData, `link_${key}`, 300)
    if (val) links[key] = val
  }

  const payload = { title, description, amount: amount || null, stage: stage || null, sectors, links }

  if (id) {
    const { error } = await supabase
      .from('investment_offers')
      .update(payload)
      .eq('id', id)
      .eq('investor_id', user.id)
    if (error) return { error: error.message, success: false }
  } else {
    const { error } = await supabase
      .from('investment_offers')
      .insert({ investor_id: user.id, status: 'active', ...payload })
    if (error) return { error: error.message, success: false }
  }

  revalidatePath('/app/profile')
  revalidatePath('/app/feed')
  return { error: null, success: true }
}

export async function deleteInvestmentOffer(offerId: string): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('investment_offers')
    .delete()
    .eq('id', offerId)
    .eq('investor_id', user.id)

  if (error) return { error: error.message }
  revalidatePath('/app/profile')
  revalidatePath('/app/feed')
  return { error: null }
}

export async function toggleOfferStatus(
  offerId: string,
  status: 'active' | 'closed'
): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('investment_offers')
    .update({ status })
    .eq('id', offerId)
    .eq('investor_id', user.id)

  if (error) return { error: error.message }
  revalidatePath('/app/profile')
  revalidatePath('/app/feed')
  return { error: null }
}
