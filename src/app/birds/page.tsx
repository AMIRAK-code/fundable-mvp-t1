import Link from 'next/link'
import { Search } from 'lucide-react'
import { allTags, searchBirds } from '@/lib/birds/data'
import { AUDIENCE_LABEL, type Audience } from '@/lib/birds/types'
import SpeciesCard from './species-card'

const AUDIENCES = Object.keys(AUDIENCE_LABEL) as Audience[]

function first(value: string | string[] | undefined): string {
  return (Array.isArray(value) ? value[0] : value) ?? ''
}

export default async function BirdsIndexPage(props: PageProps<'/birds'>) {
  const params = await props.searchParams
  const q = first(params.q)
  const audience = first(params.audience)
  const tag = first(params.tag)

  const results = searchBirds(q, { audience, tag })
  const tags = allTags()

  return (
    <div className="space-y-6">
      <section>
        <h1 className="text-2xl font-bold tracking-tight">Study the birds</h1>
        <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
          Identification, voice, behaviour and breeding notes for watchers in the
          field and keepers at home. Stuck on something?{' '}
          <Link href="/birds/ask" className="text-[var(--bird-primary)] hover:underline">
            Ask the community
          </Link>
          .
        </p>
      </section>

      {/* GET form so results stay shareable and work without JavaScript */}
      <form method="GET" className="space-y-3">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="search"
            name="q"
            defaultValue={q}
            placeholder="Search by name, family, habitat…"
            aria-label="Search species"
            className="w-full rounded-xl border border-white/10 bg-white/5 py-2.5 pl-9 pr-4 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--bird-primary)]"
          />
        </div>

        <div className="flex flex-wrap gap-1.5">
          {AUDIENCES.map((key) => {
            const active = audience === key
            return (
              <button
                key={key}
                type="submit"
                name="audience"
                value={active ? '' : key}
                className={[
                  'rounded-lg px-2.5 py-1 text-xs font-medium transition-colors',
                  active
                    ? 'bg-[var(--bird-primary)] text-black'
                    : 'border border-white/10 bg-white/5 text-muted-foreground hover:text-foreground',
                ].join(' ')}
              >
                {AUDIENCE_LABEL[key]}
              </button>
            )
          })}

          {tags.map((t) => {
            const active = tag === t
            return (
              <button
                key={t}
                type="submit"
                name="tag"
                value={active ? '' : t}
                className={[
                  'rounded-lg px-2.5 py-1 text-xs transition-colors',
                  active
                    ? 'bg-[var(--bird-accent)] font-medium text-black'
                    : 'border border-white/10 bg-white/5 text-muted-foreground hover:text-foreground',
                ].join(' ')}
              >
                {t}
              </button>
            )
          })}
        </div>

        {/* Preserve the filter that was not just clicked */}
        {audience && <input type="hidden" name="audience" value={audience} />}
        {tag && <input type="hidden" name="tag" value={tag} />}
      </form>

      <p className="text-xs text-muted-foreground">
        {results.length} {results.length === 1 ? 'species' : 'species'} shown
        {(q || audience || tag) && (
          <>
            {' · '}
            <Link href="/birds" className="text-[var(--bird-primary)] hover:underline">
              clear filters
            </Link>
          </>
        )}
      </p>

      {results.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-white/15 p-8 text-center">
          <p className="text-sm text-muted-foreground">
            Nothing in the guide matches that yet.
          </p>
          <Link
            href={`/birds/ask/new?title=${encodeURIComponent(q)}`}
            className="mt-3 inline-block rounded-xl bg-[var(--bird-primary)] px-4 py-2 text-sm font-semibold text-black hover:opacity-90"
          >
            Ask the community instead
          </Link>
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2">
          {results.map((bird) => (
            <SpeciesCard key={bird.slug} bird={bird} />
          ))}
        </div>
      )}
    </div>
  )
}
