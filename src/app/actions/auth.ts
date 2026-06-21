'use server'

import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { safeRelativePath } from '@/lib/security/url'
import { validateImageUpload } from '@/lib/security/upload'
import { rateLimit } from '@/lib/security/rate-limit'

function siteUrl() {
  return process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'
}

// Only allow relative, in-app redirect targets to avoid open-redirect abuse.
function safeNext(next: FormDataEntryValue | null): string {
  return safeRelativePath(typeof next === 'string' ? next : null)
}

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

  // If the account has a verified second factor, the password only gets us to
  // aal1 — route to the MFA challenge before landing in the app.
  const { data: aal } =
    await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
  if (aal?.nextLevel === 'aal2' && aal.nextLevel !== aal.currentLevel) {
    const mfaUrl = `/auth/mfa?next=${encodeURIComponent(safeNext(formData.get('next')))}`
    redirect(mfaUrl)
  }

  redirect(safeNext(formData.get('next')))
}

export async function sendMagicLink(
  _prevState: { error: string | null; sent?: boolean },
  formData: FormData
): Promise<{ error: string | null; sent?: boolean }> {
  const supabase = await createClient()
  const email = (formData.get('email') as string).trim()
  const next = safeNext(formData.get('next'))

  // Throttle to limit email-sending abuse / enumeration.
  if (!rateLimit(`magic:${email.toLowerCase()}`, 5, 15 * 60_000)) {
    return { error: 'Too many requests. Please wait a few minutes and try again.' }
  }

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      // Don't silently create brand-new accounts from the login screen.
      shouldCreateUser: false,
      emailRedirectTo: `${siteUrl()}/auth/callback?next=${encodeURIComponent(next)}`,
    },
  })

  if (error) return { error: error.message }
  return { error: null, sent: true }
}

export async function requestPasswordReset(
  _prevState: { error: string | null; sent?: boolean },
  formData: FormData
): Promise<{ error: string | null; sent?: boolean }> {
  const supabase = await createClient()
  const email = (formData.get('email') as string).trim()

  // Throttle to limit reset-email spam / enumeration.
  if (!rateLimit(`reset:${email.toLowerCase()}`, 5, 15 * 60_000)) {
    return { error: 'Too many requests. Please wait a few minutes and try again.' }
  }

  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${siteUrl()}/auth/callback?next=/auth/reset`,
  })

  if (error) return { error: error.message }
  return { error: null, sent: true }
}

export async function updatePassword(
  _prevState: { error: string | null },
  formData: FormData
): Promise<{ error: string | null }> {
  const supabase = await createClient()

  // The recovery link established a session via /auth/callback, so this user
  // is authenticated and allowed to set a new password.
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Your reset link has expired. Request a new one.' }

  const password = formData.get('password') as string
  const confirm = formData.get('confirm') as string
  if (password !== confirm) return { error: 'Passwords do not match.' }
  if (password.length < 8)
    return { error: 'Password must be at least 8 characters.' }

  const { error } = await supabase.auth.updateUser({ password })
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
    const valid = validateImageUpload(avatarFile)
    if (!valid.ok) return { error: valid.error }
    const path = `${user.id}/avatar.${valid.ext}`

    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(path, avatarFile, { upsert: true, contentType: avatarFile.type })

    if (uploadError) return { error: 'Image upload failed. Please try again.' }

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
