import Link from 'next/link'
import { ArrowLeft } from 'lucide-react'
import { BIRDS, getBird } from '@/lib/birds/data'
import { getViewerId } from '@/lib/birds/qa'
import { isSupabaseConfigured } from '@/lib/supabase/config'
import BackendNotice from '../backend-notice'
import AskForm from './ask-form'

export const metadata = { title: 'Ask a question' }

function first(value: string | string[] | undefined): string {
  return (Array.isArray(value) ? value[0] : value) ?? ''
}

export default async function NewQuestionPage(props: PageProps<'/birds/ask/new'>) {
  const params = await props.searchParams
  const speciesParam = first(params.species)
  const species = getBird(speciesParam) ? speciesParam : ''
  const defaultTitle = first(params.title)

  const configured = isSupabaseConfigured()
  const viewerId = await getViewerId()

  const speciesOptions = BIRDS.map((b) => ({ slug: b.slug, name: b.commonName }))

  return (
    <div className="space-y-5">
      <Link
        href="/birds/ask"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" />
        All questions
      </Link>

      <div>
        <h1 className="text-2xl font-bold tracking-tight">Ask a question</h1>
        <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
          The more you can say about size, location, date and behaviour, the better the
          answers you will get.
        </p>
      </div>

      {!configured ? (
        <BackendNotice />
      ) : !viewerId ? (
        <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-center">
          <p className="text-sm text-muted-foreground">
            You need an account to post a question.
          </p>
          <Link
            href="/login"
            className="mt-3 inline-block rounded-xl bg-[var(--bird-primary)] px-4 py-2 text-sm font-semibold text-black hover:opacity-90"
          >
            Sign in
          </Link>
        </div>
      ) : (
        <AskForm
          species={species}
          defaultTitle={defaultTitle}
          speciesOptions={speciesOptions}
        />
      )}
    </div>
  )
}
