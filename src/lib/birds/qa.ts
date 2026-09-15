import { createClient } from '@/lib/supabase/server'
import { isSupabaseConfigured } from '@/lib/supabase/config'
import type { BirdAnswerWithAuthor, BirdQuestionWithAuthor } from '@/lib/supabase/types'

const AUTHOR_SELECT = 'profiles:author_id (id, full_name, avatar_url)'

/** Null when signed out — or when there is no backend configured at all. */
export async function getViewerId(): Promise<string | null> {
  if (!isSupabaseConfigured()) return null

  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  return user?.id ?? null
}

export type QuestionListResult = {
  configured: boolean
  questions: BirdQuestionWithAuthor[]
  error: string | null
}

export async function listQuestions(
  options: { speciesSlug?: string; limit?: number } = {}
): Promise<QuestionListResult> {
  if (!isSupabaseConfigured()) {
    return { configured: false, questions: [], error: null }
  }

  const supabase = await createClient()
  let query = supabase
    .from('bird_questions')
    .select(`*, ${AUTHOR_SELECT}`)
    .order('created_at', { ascending: false })
    .limit(options.limit ?? 50)

  if (options.speciesSlug) {
    query = query.eq('species_slug', options.speciesSlug)
  }

  const { data, error } = (await query) as {
    data: BirdQuestionWithAuthor[] | null
    error: { message: string } | null
  }

  return {
    configured: true,
    questions: data ?? [],
    error: error?.message ?? null,
  }
}

export type QuestionDetailResult = {
  configured: boolean
  question: BirdQuestionWithAuthor | null
  answers: BirdAnswerWithAuthor[]
}

export async function getQuestion(id: string): Promise<QuestionDetailResult> {
  if (!isSupabaseConfigured()) {
    return { configured: false, question: null, answers: [] }
  }

  const supabase = await createClient()

  const { data: question } = (await supabase
    .from('bird_questions')
    .select(`*, ${AUTHOR_SELECT}`)
    .eq('id', id)
    .single()) as { data: BirdQuestionWithAuthor | null }

  if (!question) return { configured: true, question: null, answers: [] }

  const { data: answers } = (await supabase
    .from('bird_answers')
    .select(`*, ${AUTHOR_SELECT}`)
    .eq('question_id', id)
    .order('created_at', { ascending: true })) as {
    data: BirdAnswerWithAuthor[] | null
  }

  return { configured: true, question, answers: answers ?? [] }
}
