export type Audience = 'birder' | 'breeder'

/** IUCN Red List category. */
export type Conservation = 'LC' | 'NT' | 'VU' | 'EN' | 'CR'

export type Range = readonly [min: number, max: number]

export type IdPoint = {
  field: string
  detail: string
}

export type BreedingNotes = {
  season: string
  nest: string
  clutch: Range
  incubationDays: Range
  fledgeDays: Range
  notes: string
}

/** Extra husbandry detail, present only for species kept in aviculture. */
export type Aviculture = {
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  lifespanYears: Range
  minEnclosureCm: readonly [w: number, d: number, h: number]
  diet: string
  social: string
  sexing: string
  notes: string
}

export type Bird = {
  slug: string
  commonName: string
  scientificName: string
  family: string
  summary: string
  audiences: readonly Audience[]
  lengthCm: Range
  wingspanCm?: Range
  conservation: Conservation
  distribution: string
  habitat: readonly string[]
  diet: readonly string[]
  identification: readonly IdPoint[]
  voice: string
  behaviour: string
  breeding: BreedingNotes
  aviculture?: Aviculture
  fieldNotes: readonly string[]
  similarSpecies: readonly { name: string; howToTell: string }[]
  tags: readonly string[]
}

export const CONSERVATION_LABEL: Record<Conservation, string> = {
  LC: 'Least concern',
  NT: 'Near threatened',
  VU: 'Vulnerable',
  EN: 'Endangered',
  CR: 'Critically endangered',
}

export const AUDIENCE_LABEL: Record<Audience, string> = {
  birder: 'Birders & watchers',
  breeder: 'Breeders & keepers',
}
