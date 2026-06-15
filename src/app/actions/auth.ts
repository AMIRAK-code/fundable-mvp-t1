'use server'

import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

export async function login(
  _prevState: { error: string | null },
  formData: FormData
): Promise<{ error: string | null }> {
  const supabase = await createClient()

  const email = formData.get('email')
  const password = formData.get('password')
  if (typeof email !== 'string' || typeof password !== 'string' || !email || !password) {
    return { error: 'Missing required field' }
  }

  const { error } = await supabase.auth.signInWithPassword({ email, password })

  if (error) return { error: error.message }

  redirect('/app/feed')
}

export async function signup(
  _prevState: { error: string | null; emailSent?: boolean },
  formData: FormData
): Promise<{ error: string | null; emailSent?: boolean }> {
  const supabase = await createClient()

  const role = formData.get('role')
  const email = formData.get('email')
  const password = formData.get('password')
  if (
    typeof role !== 'string' ||
    typeof email !== 'string' ||
    typeof password !== 'string' ||
    !email ||
    !password
  ) {
    return { error: 'Missing required field' }
  }

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

export async function logout(): Promise<{ error: string } | void> {
  const supabase = await createClient()
  const { error } = await supabase.auth.signOut()
  if (error) return { error: error.message }
  redirect('/')
}

export async function updateProfile(
  _prevState: { error: string | null; success?: boolean },
  formData: FormData
): Promise<{ error: string | null; success?: boolean }> {
  const supabase = await createClient()

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser()

  if (!user || userError) return { error: 'Not authenticated' }

  const rawName = formData.get('full_name')
  const rawBio = formData.get('bio')
  if (typeof rawName !== 'string') return { error: 'Missing required field' }
  const fullName = rawName.trim().slice(0, 80)
  if (!fullName) return { error: 'Missing required field' }
  const bio = typeof rawBio === 'string' ? rawBio.trim().slice(0, 1000) : ''
  const avatarFile = formData.get('avatar')

  let avatarUrl: string | undefined

  if (avatarFile instanceof File && avatarFile.size > 0) {
    const ext = avatarFile.name.split('.').pop() ?? 'jpg'
    const path = `${user.id}/avatar.${ext}`

    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(path, avatarFile, { upsert: true })

    if (uploadError) return { error: uploadError.message }

    const {
      data: { publicUrl },
    } = supabase.storage.from('avatars').getPublicUrl(path)

    // The storage path is stable, so bust CDN/browser caches per upload
    avatarUrl = `${publicUrl}?v=${Date.now()}`
  }

  const payload: Record<string, string> = { full_name: fullName, bio }
  if (avatarUrl) payload.avatar_url = avatarUrl

  const { error } = await supabase
    .from('profiles')
    .update(payload)
    .eq('id', user.id)

  if (error) return { error: error.message }

  revalidatePath('/app/profile')
  revalidatePath('/app/feed')

  // In-app edits (profile page dialog) stay put; onboarding redirects to the feed
  if (formData.get('stay') === '1') return { error: null, success: true }

  redirect('/app/feed')
}
