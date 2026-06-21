'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import { dedupeSectors } from '@/lib/profile-completion'

const MAX_IMAGE_BYTES = 5 * 1024 * 1024
const ALLOWED_IMAGE_TYPES = new Set(['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/gif'])
const SOCIAL_KEYS = ['github', 'linkedin', 'reddit', 'instagram', 'website'] as const

function normalizeUrl(raw: string | null | undefined): { ok: true; value: string } | { ok: false; error: string } | null {
  if (!raw) return null
  const trimmed = raw.trim()
  if (!trimmed) return null
  const withScheme = /^https?:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`
  try {
    const url = new URL(withScheme)
    return { ok: true, value: url.toString() }
  } catch {
    return { ok: false, error: `Invalid URL: ${trimmed}` }
  }
}

function collectLinks(formData: FormData): { ok: true; links: Record<string, string> } | { ok: false; error: string } {
  const links: Record<string, string> = {}
  for (const key of SOCIAL_KEYS) {
    const raw = formData.get(`link_${key}`) as string | null
    const result = normalizeUrl(raw)
    if (!result) continue
    if (!result.ok) return { ok: false, error: `${key}: ${result.error}` }
    links[key] = result.value
  }
  return { ok: true, links }
}

function validateImage(file: File | null): { ok: true; file: File | null } | { ok: false; error: string } {
  if (!file || file.size === 0) return { ok: true, file: null }
  if (file.size > MAX_IMAGE_BYTES) return { ok: false, error: 'Image must be under 5MB.' }
  if (!ALLOWED_IMAGE_TYPES.has(file.type)) return { ok: false, error: 'Image must be PNG, JPEG, WebP, or GIF.' }
  return { ok: true, file }
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

  const id = formData.get('id') as string | null
  const name = (formData.get('name') as string).trim()
  const pitch = (formData.get('pitch') as string).trim()
  const industry = (formData.get('industry') as string).trim()
  const heroFile = formData.get('hero_image') as File | null

  if (!name) return { error: 'Startup name is required.', success: false }
  if (!pitch) return { error: 'A one-line pitch is required.', success: false }
  if (name.length > 80) return { error: 'Name must be 80 characters or fewer.', success: false }
  if (pitch.length > 200) return { error: 'Pitch must be 200 characters or fewer.', success: false }

  const imgCheck = validateImage(heroFile)
  if (!imgCheck.ok) return { error: imgCheck.error, success: false }

  const linkRes = collectLinks(formData)
  if (!linkRes.ok) return { error: linkRes.error, success: false }

  let heroImageUrl: string | undefined
  if (imgCheck.file) {
    const path = `${user.id}/${id ?? 'new'}-${Date.now()}`
    const { error: uploadError } = await supabase.storage
      .from('hero-images')
      .upload(path, imgCheck.file, { upsert: true, contentType: imgCheck.file.type })
    if (uploadError) return { error: uploadError.message, success: false }
    const {
      data: { publicUrl },
    } = supabase.storage.from('hero-images').getPublicUrl(path)
    heroImageUrl = publicUrl

    if (id) {
      const { data: existing } = await supabase
        .from('startups')
        .select('hero_image_url')
        .eq('id', id)
        .eq('founder_id', user.id)
        .maybeSingle()
      const oldUrl = (existing as { hero_image_url: string | null } | null)?.hero_image_url
      if (oldUrl) {
        const marker = '/hero-images/'
        const ix = oldUrl.indexOf(marker)
        if (ix !== -1) {
          const oldPath = oldUrl.slice(ix + marker.length)
          await supabase.storage.from('hero-images').remove([oldPath])
        }
      }
    }
  }

  const payload = {
    name,
    pitch,
    industry,
    links: linkRes.links,
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

  const { data: existing } = await supabase
    .from('startups')
    .select('hero_image_url')
    .eq('id', startupId)
    .eq('founder_id', user.id)
    .maybeSingle()

  const { error } = await supabase
    .from('startups')
    .delete()
    .eq('id', startupId)
    .eq('founder_id', user.id)

  if (error) return { error: error.message }

  const heroUrl = (existing as { hero_image_url: string | null } | null)?.hero_image_url
  if (heroUrl) {
    const marker = '/hero-images/'
    const ix = heroUrl.indexOf(marker)
    if (ix !== -1) {
      const oldPath = heroUrl.slice(ix + marker.length)
      await supabase.storage.from('hero-images').remove([oldPath])
    }
  }

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

  const firmName = (formData.get('firm_name') as string).trim()
  const checkSize = (formData.get('check_size') as string).trim()
  const thesis = (formData.get('thesis') as string).trim()
  const sectorsRaw = (formData.get('sectors') as string) ?? ''
  const sectors = dedupeSectors(sectorsRaw.split(','))

  if (thesis.length > 500) return { error: 'Thesis must be 500 characters or fewer.', success: false }

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

  const id = formData.get('id') as string | null
  const title = (formData.get('title') as string).trim()
  const description = (formData.get('description') as string).trim()
  const amount = (formData.get('amount') as string).trim()
  const stage = (formData.get('stage') as string).trim()
  const sectorsRaw = (formData.get('sectors') as string) ?? ''
  const sectors = dedupeSectors(sectorsRaw.split(','))

  if (!title) return { error: 'Title is required.', success: false }
  if (!description) return { error: 'Description is required.', success: false }
  if (title.length > 100) return { error: 'Title must be 100 characters or fewer.', success: false }
  if (description.length > 500) return { error: 'Description must be 500 characters or fewer.', success: false }

  const linkRes = collectLinks(formData)
  if (!linkRes.ok) return { error: linkRes.error, success: false }

  const payload = { title, description, amount: amount || null, stage: stage || null, sectors, links: linkRes.links }

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
