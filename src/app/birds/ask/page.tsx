import Link from 'next/link'
import { MessagesSquare, Plus } from 'lucide-react'
import { listQuestions } from '@/lib/birds/qa'
import { getBird } from '@/lib/birds/data'
import BackendNotice from './backend-notice'

export const metadata = { title: 'Ask the community' }

function timeAgo(iso: string): string {
  const seconds = Math.floor((Date.now() - new Date(iso).getTime()) / 1000)
  const units: [number, Intl.RelativeTimeFormatUnit][] = [
    [60, 'second'],
    [60, 'minute'],
    [24, 'hour'],
    [7, 'day'],
    [4.35, 'week'],
    [12, 'month'],
  ]

  let value = seconds
  let unit: Intl.RelativeTimeFormatUnit = 'second'

  for (const [step, nextUnit] of units) {
    if (Math.abs(value) < step) break
    value = Math.round(value / step)
    unit = nextUnit
  }

  return new Intl.RelativeTimeFormat('en', { numeric: 'auto' }).format(-value, unit)
}

export default async function AskIndexPage() {
  const { configured, questions, error } = await listQuestions()

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Ask the community</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Identification puzzles, behaviour you cannot explain, breeding problems.
          </p>
        </div>
        <Link
          href="/birds/ask/new"
          className="inline-flex shrink-0 items-center gap-1.5 rounded-xl bg-[var(--bird-primary)] px-3.5 py-2 text-sm font-semibold text-black hover:opacity-90"
        >
          <Plus className="h-4 w-4" />
          Ask
        </Link>
      </div>

      {!configured && <BackendNotice />}

      {error && (
        <p className="rounded-xl border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">
          {error}
        </p>
      )}

      {configured && questions.length === 0 && !error && (
        <div className="rounded-2xl border border-dashed border-white/15 p-8 text-center">
          <p className="text-sm text-muted-foreground">
            No questions yet. Be the first to ask one.
          </p>
        </div>
      )}

      <ul className="space-y-3">
        {questions.map((q) => {
          const bird = q.species_slug ? getBird(q.species_slug) : undefined

          return (
            <li key={q.id}>
              <Link
                href={`/birds/ask/${q.id}`}
                className="block rounded-2xl border border-white/10 bg-white/5 p-4 transition-colors hover:border-[var(--bird-primary)]/40"
              >
                <div className="flex items-start justify-between gap-3">
                  <h2 className="font-semibold">{q.title}</h2>
                  <span className="flex shrink-0 items-center gap-1 text-xs text-muted-foreground">
                    <MessagesSquare className="h-3.5 w-3.5" />
                    {q.answer_count}
                  </span>
                </div>

                <p className="mt-1.5 line-clamp-2 text-sm leading-relaxed text-muted-foreground">
                  {q.body}
                </p>

                <div className="mt-2.5 flex flex-wrap items-center gap-2 text-[11px] text-muted-foreground">
                  {bird && (
                    <span className="rounded-md bg-[var(--bird-primary)]/15 px-1.5 py-0.5 font-medium text-[var(--bird-primary)]">
                      {bird.commonName}
                    </span>
                  )}
                  <span>{q.profiles?.full_name ?? 'A birder'}</span>
                  <span>·</span>
                  <span>{timeAgo(q.created_at)}</span>
                </div>
              </Link>
            </li>
          )
        })}
      </ul>
    </div>
  )
}
