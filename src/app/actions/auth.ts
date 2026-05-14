'use server'

import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'

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
      emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'}/auth/callback?next=/app/onboarding`,
    },
  })

  if (error) return { error: error.message }

  // If session is null, email confirmation is required
  if (!data.session) return { error: null, emailSent: true }

  redirect('/app/onboarding')
}

export async function logout() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect('/')
}

export async function updateProfile(
  _prevState: { error: string | null },
  formData: FormData
): Promise<{ error: string | null }> {
  const supabase = await createClient()

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser()

  if (!user || userError) return { error: 'Not authenticated' }

  const fullName = (formData.get('full_name') as string).trim()
  const bio = (formData.get('bio') as string).trim()
  const avatarFile = formData.get('avatar') as File | null

  let avatarUrl: string | undefined

  if (avatarFile && avatarFile.size > 0) {
    const ext = avatarFile.name.split('.').pop() ?? 'jpg'
    const path = `${user.id}/avatar.${ext}`

    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(path, avatarFile, { upsert: true })

    if (uploadError) return { error: uploadError.message }

    const {
      data: { publicUrl },
    } = supabase.storage.from('avatars').getPublicUrl(path)

    avatarUrl = publicUrl
  }

  const payload: Record<string, string> = { full_name: fullName, bio }
  if (avatarUrl) payload.avatar_url = avatarUrl

  const { error } = await supabase
    .from('profiles')
    .update(payload)
    .eq('id', user.id)

  if (error) return { error: error.message }

  redirect('/app/feed')
}
