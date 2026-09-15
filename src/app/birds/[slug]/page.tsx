import Link from 'next/link'
import { notFound } from 'next/navigation'
import { ArrowLeft, MessagesSquare } from 'lucide-react'
import { BIRDS, getBird } from '@/lib/birds/data'
import { AUDIENCE_LABEL, CONSERVATION_LABEL } from '@/lib/birds/types'
import { listQuestions } from '@/lib/birds/qa'
import { ConservationBadge } from '../species-card'

export function generateStaticParams() {
  return BIRDS.map((bird) => ({ slug: bird.slug }))
}

export async function generateMetadata(props: PageProps<'/birds/[slug]'>) {
  const { slug } = await props.params
  const bird = getBird(slug)
  if (!bird) return { title: 'Species not found' }

  return { title: bird.commonName, description: bird.summary }
}

function Section({
  title,
  children,
}: {
  title: string
  children: React.ReactNode
}) {
  return (
    <section className="rounded-2xl border border-white/10 bg-white/5 p-4">
      <h2 className="text-sm font-semibold uppercase tracking-wide text-[var(--bird-primary)]">
        {title}
      </h2>
      <div className="mt-3 space-y-3 text-sm leading-relaxed">{children}</div>
    </section>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-[11px] uppercase tracking-wide text-muted-foreground">{label}</dt>
      <dd className="mt-0.5 text-sm font-medium">{value}</dd>
    </div>
  )
}

export default async function SpeciesPage(props: PageProps<'/birds/[slug]'>) {
  const { slug } = await props.params
  const bird = getBird(slug)
  if (!bird) notFound()

  const { questions } = await listQuestions({ speciesSlug: slug, limit: 5 })
  const { breeding, aviculture } = bird

  return (
    <div className="space-y-5">
      <Link
        href="/birds"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" />
        All species
      </Link>

      <header>
        <div className="flex items-start justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">{bird.commonName}</h1>
            <p className="text-sm italic text-muted-foreground">{bird.scientificName}</p>
          </div>
          <ConservationBadge bird={bird} />
        </div>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground">{bird.summary}</p>

        <div className="mt-3 flex flex-wrap gap-1.5">
          {bird.audiences.map((a) => (
            <span
              key={a}
              className="rounded-md bg-[var(--bird-primary)]/15 px-2 py-0.5 text-[11px] font-medium text-[var(--bird-primary)]"
            >
              {AUDIENCE_LABEL[a]}
            </span>
          ))}
        </div>
      </header>

      <dl className="grid grid-cols-2 gap-4 rounded-2xl border border-white/10 bg-white/5 p-4 sm:grid-cols-4">
        <Stat label="Family" value={bird.family.split(' (')[0]} />
        <Stat label="Length" value={`${bird.lengthCm[0]}–${bird.lengthCm[1]} cm`} />
        <Stat
          label="Wingspan"
          value={
            bird.wingspanCm ? `${bird.wingspanCm[0]}–${bird.wingspanCm[1]} cm` : 'Not recorded'
          }
        />
        <Stat label="Red List" value={CONSERVATION_LABEL[bird.conservation]} />
      </dl>

      <Section title="Identification">
        <dl className="space-y-2.5">
          {bird.identification.map((point) => (
            <div key={point.field} className="grid gap-0.5 sm:grid-cols-[8rem_1fr] sm:gap-3">
              <dt className="font-medium text-muted-foreground">{point.field}</dt>
              <dd>{point.detail}</dd>
            </div>
          ))}
        </dl>
      </Section>

      <Section title="Voice">
        <p>{bird.voice}</p>
      </Section>

      <Section title="Behaviour">
        <p>{bird.behaviour}</p>
      </Section>

      <Section title="Where it lives">
        <p>{bird.distribution}</p>
        <div>
          <p className="text-muted-foreground">Habitat</p>
          <ul className="mt-1 list-inside list-disc">
            {bird.habitat.map((h) => (
              <li key={h}>{h}</li>
            ))}
          </ul>
        </div>
        <div>
          <p className="text-muted-foreground">Diet</p>
          <ul className="mt-1 list-inside list-disc">
            {bird.diet.map((d) => (
              <li key={d}>{d}</li>
            ))}
          </ul>
        </div>
      </Section>

      <Section title="Breeding">
        <dl className="grid grid-cols-2 gap-4 sm:grid-cols-3">
          <Stat label="Clutch" value={`${breeding.clutch[0]}–${breeding.clutch[1]} eggs`} />
          <Stat
            label="Incubation"
            value={`${breeding.incubationDays[0]}–${breeding.incubationDays[1]} days`}
          />
          <Stat
            label="Fledging"
            value={`${breeding.fledgeDays[0]}–${breeding.fledgeDays[1]} days`}
          />
        </dl>
        <p>
          <span className="text-muted-foreground">Season. </span>
          {breeding.season}
        </p>
        <p>
          <span className="text-muted-foreground">Nest. </span>
          {breeding.nest}
        </p>
        <p>{breeding.notes}</p>
      </Section>

      {aviculture && (
        <Section title="Keeping and breeding">
          <dl className="grid grid-cols-2 gap-4 sm:grid-cols-3">
            <Stat label="Difficulty" value={aviculture.difficulty} />
            <Stat
              label="Lifespan"
              value={`${aviculture.lifespanYears[0]}–${aviculture.lifespanYears[1]} yrs`}
            />
            <Stat
              label="Min. enclosure"
              value={`${aviculture.minEnclosureCm[0]} × ${aviculture.minEnclosureCm[1]} × ${aviculture.minEnclosureCm[2]} cm`}
            />
          </dl>
          <p>
            <span className="text-muted-foreground">Diet. </span>
            {aviculture.diet}
          </p>
          <p>
            <span className="text-muted-foreground">Company. </span>
            {aviculture.social}
          </p>
          <p>
            <span className="text-muted-foreground">Sexing. </span>
            {aviculture.sexing}
          </p>
          <p>{aviculture.notes}</p>
        </Section>
      )}

      <Section title="Field notes">
        <ul className="list-inside list-disc space-y-1.5">
          {bird.fieldNotes.map((note) => (
            <li key={note}>{note}</li>
          ))}
        </ul>
      </Section>

      {bird.similarSpecies.length > 0 && (
        <Section title="Easily confused with">
          <dl className="space-y-2.5">
            {bird.similarSpecies.map((s) => (
              <div key={s.name} className="grid gap-0.5 sm:grid-cols-[10rem_1fr] sm:gap-3">
                <dt className="font-medium text-muted-foreground">{s.name}</dt>
                <dd>{s.howToTell}</dd>
              </div>
            ))}
          </dl>
        </Section>
      )}

      <Section title={`Questions about the ${bird.commonName}`}>
        {questions.length === 0 ? (
          <p className="text-muted-foreground">
            No one has asked about this species yet.
          </p>
        ) : (
          <ul className="space-y-2">
            {questions.map((q) => (
              <li key={q.id}>
                <Link
                  href={`/birds/ask/${q.id}`}
                  className="flex items-start justify-between gap-3 rounded-xl border border-white/10 p-3 hover:border-[var(--bird-primary)]/40"
                >
                  <span className="min-w-0 flex-1">{q.title}</span>
                  <span className="flex shrink-0 items-center gap-1 text-xs text-muted-foreground">
                    <MessagesSquare className="h-3.5 w-3.5" />
                    {q.answer_count}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}

        <Link
          href={`/birds/ask/new?species=${bird.slug}`}
          className="inline-block rounded-xl bg-[var(--bird-primary)] px-4 py-2 text-sm font-semibold text-black hover:opacity-90"
        >
          Ask about this species
        </Link>
      </Section>
    </div>
  )
}
