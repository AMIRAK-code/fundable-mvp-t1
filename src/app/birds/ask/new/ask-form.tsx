'use client'

import { useActionState } from 'react'
import { askQuestion, type BirdFormState } from '@/app/actions/birds'

const INITIAL: BirdFormState = { error: null }

export default function AskForm({
  species,
  defaultTitle,
  speciesOptions,
}: {
  species: string
  defaultTitle: string
  speciesOptions: { slug: string; name: string }[]
}) {
  const [state, action, pending] = useActionState(askQuestion, INITIAL)

  return (
    <form action={action} className="space-y-5">
      <div className="space-y-1.5">
        <label htmlFor="title" className="text-sm text-muted-foreground">
          Question <span className="text-destructive">*</span>
        </label>
        <input
          id="title"
          name="title"
          type="text"
          required
          minLength={8}
          maxLength={160}
          defaultValue={defaultTitle}
          placeholder="Small brown bird with a rusty tail — what is it?"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--bird-primary)]"
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="species_slug" className="text-sm text-muted-foreground">
          Species (optional)
        </label>
        <select
          id="species_slug"
          name="species_slug"
          defaultValue={species}
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[var(--bird-primary)]"
        >
          <option value="">Not sure / not listed</option>
          {speciesOptions.map((o) => (
            <option key={o.slug} value={o.slug} className="bg-background">
              {o.name}
            </option>
          ))}
        </select>
      </div>

      <div className="space-y-1.5">
        <label htmlFor="body" className="text-sm text-muted-foreground">
          Details <span className="text-destructive">*</span>
        </label>
        <textarea
          id="body"
          name="body"
          required
          minLength={20}
          maxLength={5000}
          rows={7}
          placeholder="Where and when did you see it? Size compared to a familiar bird, what it was doing, any call you heard. For breeding questions: species, age, enclosure, diet and what has changed."
          className="w-full resize-y rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--bird-primary)]"
        />
      </div>

      {state.error && (
        <p className="rounded-xl border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">
          {state.error}
        </p>
      )}

      <button
        type="submit"
        disabled={pending}
        className="w-full rounded-xl bg-[var(--bird-primary)] px-4 py-2.5 text-sm font-semibold text-black transition-opacity hover:opacity-90 disabled:opacity-50"
      >
        {pending ? 'Posting…' : 'Post question'}
      </button>
    </form>
  )
}
