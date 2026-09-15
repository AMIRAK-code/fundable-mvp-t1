'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { isSupabaseConfigured } from '@/lib/supabase/config'
import { getBird } from '@/lib/birds/data'

export type BirdFormState = { error: string | null }

const TITLE_MIN = 8
const TITLE_MAX = 160
const BODY_MIN = 20
const BODY_MAX = 5000
const ANSWER_MIN = 10

/** Posts a question to the community and opens the new thread. */
export async function askQuestion(
  _prev: BirdFormState,
  formData: FormData
): Promise<BirdFormState> {
  if (!isSupabaseConfigured()) {
    return { error: 'Questions need a database connection. Set your Supabase keys to enable them.' }
  }

  const title = String(formData.get('title') ?? '').trim()
  const body = String(formData.get('body') ?? '').trim()
  const rawSlug = String(formData.get('species_slug') ?? '').trim()

  if (title.length < TITLE_MIN || title.length > TITLE_MAX) {
    return { error: `Give your question a title between ${TITLE_MIN} and ${TITLE_MAX} characters.` }
  }
  if (body.length < BODY_MIN || body.length > BODY_MAX) {
    return { error: `Describe what you observed in ${BODY_MIN} to ${BODY_MAX} characters.` }
  }

  // Only accept slugs that exist in the shipped catalogue
  const speciesSlug = rawSlug && getBird(rawSlug) ? rawSlug : null

  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Sign in to post a question.' }

  const { data, error } = await supabase
    .from('bird_questions')
    .insert({ author_id: user.id, title, body, species_slug: speciesSlug })
    .select('id')
    .single<{ id: string }>()

  if (error) return { error: error.message }

  revalidatePath('/birds/ask')
  if (speciesSlug) revalidatePath(`/birds/${speciesSlug}`)
  redirect(`/birds/ask/${data.id}`)
}

/** Adds an answer to an existing question. */
export async function postAnswer(
  _prev: BirdFormState,
  formData: FormData
): Promise<BirdFormState> {
  if (!isSupabaseConfigured()) {
    return { error: 'Answers need a database connection. Set your Supabase keys to enable them.' }
  }

  const questionId = String(formData.get('question_id') ?? '')
  const body = String(formData.get('body') ?? '').trim()

  if (!questionId) return { error: 'Missing question.' }
  if (body.length < ANSWER_MIN || body.length > BODY_MAX) {
    return { error: `Answers need to be between ${ANSWER_MIN} and ${BODY_MAX} characters.` }
  }

  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Sign in to answer.' }

  const { error } = await supabase
    .from('bird_answers')
    .insert({ question_id: questionId, author_id: user.id, body })

  if (error) return { error: error.message }

  revalidatePath(`/birds/ask/${questionId}`)
  revalidatePath('/birds/ask')
  return { error: null }
}
