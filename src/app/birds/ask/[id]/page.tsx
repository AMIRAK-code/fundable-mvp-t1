import Link from 'next/link'
import { notFound } from 'next/navigation'
import { ArrowLeft } from 'lucide-react'
import { getQuestion, getViewerId } from '@/lib/birds/qa'
import { getBird } from '@/lib/birds/data'
import BackendNotice from '../backend-notice'
import AnswerForm from './answer-form'

export async function generateMetadata(props: PageProps<'/birds/ask/[id]'>) {
  const { id } = await props.params
  const { question } = await getQuestion(id)

  return { title: question?.title ?? 'Question' }
}

export default async function QuestionPage(props: PageProps<'/birds/ask/[id]'>) {
  const { id } = await props.params
  const { configured, question, answers } = await getQuestion(id)

  if (!configured) {
    return (
      <div className="space-y-5">
        <Link
          href="/birds/ask"
          className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="h-4 w-4" />
          All questions
        </Link>
        <BackendNotice />
      </div>
    )
  }

  if (!question) notFound()

  const viewerId = await getViewerId()
  const bird = question.species_slug ? getBird(question.species_slug) : undefined

  return (
    <div className="space-y-6">
      <Link
        href="/birds/ask"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" />
        All questions
      </Link>

      <article className="space-y-3">
        <h1 className="text-2xl font-bold tracking-tight">{question.title}</h1>

        <div className="flex flex-wrap items-center gap-2 text-[11px] text-muted-foreground">
          {bird && (
            <Link
              href={`/birds/${bird.slug}`}
              className="rounded-md bg-[var(--bird-primary)]/15 px-1.5 py-0.5 font-medium text-[var(--bird-primary)] hover:underline"
            >
              {bird.commonName}
            </Link>
          )}
          <span>Asked by {question.profiles?.full_name ?? 'a birder'}</span>
          <span>·</span>
          <time dateTime={question.created_at}>
            {new Date(question.created_at).toLocaleDateString('en-GB', {
              day: 'numeric',
              month: 'short',
              year: 'numeric',
            })}
          </time>
        </div>

        <p className="whitespace-pre-wrap text-sm leading-relaxed">{question.body}</p>
      </article>

      <section className="space-y-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-[var(--bird-primary)]">
          {answers.length} {answers.length === 1 ? 'answer' : 'answers'}
        </h2>

        {answers.length === 0 && (
          <p className="text-sm text-muted-foreground">
            No answers yet — if you know this one, help out.
          </p>
        )}

        <ul className="space-y-3">
          {answers.map((answer) => (
            <li
              key={answer.id}
              className="rounded-2xl border border-white/10 bg-white/5 p-4"
            >
              <p className="whitespace-pre-wrap text-sm leading-relaxed">{answer.body}</p>
              <p className="mt-2.5 text-[11px] text-muted-foreground">
                {answer.profiles?.full_name ?? 'A birder'} ·{' '}
                <time dateTime={answer.created_at}>
                  {new Date(answer.created_at).toLocaleDateString('en-GB', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                  })}
                </time>
              </p>
            </li>
          ))}
        </ul>
      </section>

      {viewerId ? (
        <AnswerForm questionId={question.id} />
      ) : (
        <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-center">
          <p className="text-sm text-muted-foreground">Sign in to answer this question.</p>
          <Link
            href="/login"
            className="mt-3 inline-block rounded-xl bg-[var(--bird-primary)] px-4 py-2 text-sm font-semibold text-black hover:opacity-90"
          >
            Sign in
          </Link>
        </div>
      )}
    </div>
  )
}
