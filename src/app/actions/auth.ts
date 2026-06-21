'use server'

import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

const MAX_IMAGE_BYTES = 5 * 1024 * 1024
const ALLOWED_IMAGE_TYPES = new Set(['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/gif'])

export async function login(
  _prevState: { error: string | null },
  formData: FormData
): Promise<{ error: string | null }> {
  const supabase = await createClient()

  const { error } = await supabase.auth.signInWithPassword({
    email: formData.get('email') as string,
    password: formData.get('password') as string,
  })

  if (error) return { error: error.message }

  redirect('/app/feed')
}

export async function signup(
  _prevState: { error: string | null; emailSent?: boolean },
  formData: FormData
): Promise<{ error: string | null; emailSent?: boolean }> {
  const supabase = await createClient()

  const role = formData.get('role') as string
  const email = formData.get('email') as string
  const password = formData.get('password') as string

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { role },
      emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'}/auth/callback?next=/onboarding`,
    },
  })

  if (error) return { error: error.message }

  // If session is null, email confirmation is required
  if (!data.session) return { error: null, emailSent: true }

  redirect('/onboarding')
}

export async function logout() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect('/')
}

export async function updateProfile(
  _prevState: { error: string | null; success?: boolean },
  formData: FormData
): Promise<{ error: string | null; success: boolean }> {
  const supabase = await createClient()

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser()

  if (!user || userError) return { error: 'Not authenticated', success: false }

  const next = (formData.get('next') as string | null)?.trim() || null
  const fullName = (formData.get('full_name') as string).trim()
  const bio = (formData.get('bio') as string).trim()
  const avatarFile = formData.get('avatar') as File | null

  if (!fullName) return { error: 'Name is required.', success: false }
  if (bio.length > 280) return { error: 'Bio must be 280 characters or fewer.', success: false }

  let avatarUrl: string | undefined

  if (avatarFile && avatarFile.size > 0) {
    if (avatarFile.size > MAX_IMAGE_BYTES) {
      return { error: 'Image must be under 5MB.', success: false }
    }
    if (!ALLOWED_IMAGE_TYPES.has(avatarFile.type)) {
      return { error: 'Image must be a PNG, JPEG, WebP, or GIF.', success: false }
    }

    const path = `${user.id}/avatar`

    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(path, avatarFile, { upsert: true, contentType: avatarFile.type })

    if (uploadError) return { error: uploadError.message, success: false }

    const {
      data: { publicUrl },
    } = supabase.storage.from('avatars').getPublicUrl(path)

    avatarUrl = `${publicUrl}?v=${Date.now()}`
  }

  const payload: Record<string, string> = { full_name: fullName, bio }
  if (avatarUrl) payload.avatar_url = avatarUrl

  const { error } = await supabase
    .from('profiles')
    .update(payload)
    .eq('id', user.id)

  if (error) return { error: error.message, success: false }

  revalidatePath('/app/profile')
  revalidatePath('/app/feed')

  if (next) redirect(next)
  return { error: null, success: true }
}
