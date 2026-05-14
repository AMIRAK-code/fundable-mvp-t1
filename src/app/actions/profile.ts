'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

export async function upsertStartup(
  _prevState: { error: string | null; success: boolean },
  formData: FormData
): Promise<{ error: string | null; success: boolean }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated', success: false }

  const id = formData.get('id') as string | null
  const name = (formData.get('name') as string).trim()
  const pitch = (formData.get('pitch') as string).trim()
  const industry = (formData.get('industry') as string).trim()
  const heroFile = formData.get('hero_image') as File | null

  let heroImageUrl: string | undefined
  if (heroFile && heroFile.size > 0) {
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
    const val = (formData.get(`link_${key}`) as string | null)?.trim()
    if (val) links[key] = val
  }

  const payload = {
    name,
    pitch,
    industry,
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

  const firmName = (formData.get('firm_name') as string).trim()
  const checkSize = (formData.get('check_size') as string).trim()
  const thesis = (formData.get('thesis') as string).trim()
  const sectorsRaw = (formData.get('sectors') as string) ?? ''
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
      sectors,
    },
    { onConflict: 'investor_id' }
  )

  if (error) return { error: error.message, success: false }
  revalidatePath('/app/profile')
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

  const id = formData.get('id') as string | null
  const title = (formData.get('title') as string).trim()
  const description = (formData.get('description') as string).trim()
  const amount = (formData.get('amount') as string).trim()
  const stage = (formData.get('stage') as string).trim()
  const sectorsRaw = (formData.get('sectors') as string) ?? ''
  const sectors = sectorsRaw.split(',').map((s) => s.trim()).filter(Boolean)

  const links: Record<string, string> = {}
  for (const key of ['github', 'linkedin', 'reddit', 'instagram', 'website']) {
    const val = (formData.get(`link_${key}`) as string | null)?.trim()
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
