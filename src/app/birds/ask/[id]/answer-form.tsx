'use client'

import { useActionState, useEffect, useRef } from 'react'
import { postAnswer, type BirdFormState } from '@/app/actions/birds'

const INITIAL: BirdFormState = { error: null }

export default function AnswerForm({ questionId }: { questionId: string }) {
  const [state, action, pending] = useActionState(postAnswer, INITIAL)
  const formRef = useRef<HTMLFormElement>(null)

  // Clear the box once the answer has been accepted
  useEffect(() => {
    if (!pending && !state.error) formRef.current?.reset()
  }, [pending, state])

  return (
    <form ref={formRef} action={action} className="space-y-3">
      <input type="hidden" name="question_id" value={questionId} />

      <label htmlFor="body" className="block text-sm text-muted-foreground">
        Your answer
      </label>
      <textarea
        id="body"
        name="body"
        required
        minLength={10}
        maxLength={5000}
        rows={5}
        placeholder="Say what makes you confident — the feature you keyed on, or what you would check next."
        className="w-full resize-y rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--bird-primary)]"
      />

      {state.error && (
        <p className="rounded-xl border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">
          {state.error}
        </p>
      )}

      <button
        type="submit"
        disabled={pending}
        className="rounded-xl bg-[var(--bird-primary)] px-4 py-2 text-sm font-semibold text-black transition-opacity hover:opacity-90 disabled:opacity-50"
      >
        {pending ? 'Posting…' : 'Post answer'}
      </button>
    </form>
  )
}
