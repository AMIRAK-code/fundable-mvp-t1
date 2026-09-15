import Link from 'next/link'
import type { Bird } from '@/lib/birds/types'
import { CONSERVATION_LABEL } from '@/lib/birds/types'

export function ConservationBadge({ bird }: { bird: Bird }) {
  const atRisk = bird.conservation !== 'LC' && bird.conservation !== 'NT'

  return (
    <span
      title={CONSERVATION_LABEL[bird.conservation]}
      className={[
        'rounded-md px-1.5 py-0.5 text-[10px] font-semibold tracking-wide',
        atRisk
          ? 'bg-destructive/20 text-destructive'
          : 'bg-[var(--bird-primary)]/15 text-[var(--bird-primary)]',
      ].join(' ')}
    >
      {bird.conservation}
    </span>
  )
}

export default function SpeciesCard({ bird }: { bird: Bird }) {
  return (
    <Link
      href={`/birds/${bird.slug}`}
      className="block rounded-2xl border border-white/10 bg-white/5 p-4 transition-colors hover:border-[var(--bird-primary)]/40 hover:bg-white/[0.07]"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h2 className="truncate font-semibold">{bird.commonName}</h2>
          <p className="truncate text-xs italic text-muted-foreground">
            {bird.scientificName}
          </p>
        </div>
        <ConservationBadge bird={bird} />
      </div>

      <p className="mt-2 line-clamp-2 text-sm leading-relaxed text-muted-foreground">
        {bird.summary}
      </p>

      <div className="mt-3 flex flex-wrap items-center gap-1.5">
        <span className="rounded-md bg-white/5 px-1.5 py-0.5 text-[10px] text-muted-foreground">
          {bird.lengthCm[0]}–{bird.lengthCm[1]} cm
        </span>
        {bird.aviculture && (
          <span className="rounded-md bg-[var(--bird-accent)]/15 px-1.5 py-0.5 text-[10px] font-medium text-[var(--bird-accent)]">
            kept in aviculture
          </span>
        )}
        {bird.tags.slice(0, 3).map((tag) => (
          <span
            key={tag}
            className="rounded-md bg-white/5 px-1.5 py-0.5 text-[10px] text-muted-foreground"
          >
            {tag}
          </span>
        ))}
      </div>
    </Link>
  )
}
