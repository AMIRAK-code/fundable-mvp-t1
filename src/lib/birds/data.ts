import type { Bird } from './types'

/**
 * A curated study set. Figures are typical published ranges for the species —
 * treat them as a starting point for field notes, not as absolutes.
 */
export const BIRDS: readonly Bird[] = [
  {
    slug: 'barn-swallow',
    commonName: 'Barn Swallow',
    scientificName: 'Hirundo rustica',
    family: 'Hirundinidae (swallows and martins)',
    summary:
      'A long-winged aerial insectivore with deeply forked tail streamers, nesting on beams and ledges inside farm buildings across the northern hemisphere.',
    audiences: ['birder'],
    lengthCm: [17, 19],
    wingspanCm: [32, 35],
    conservation: 'LC',
    distribution:
      'Breeds across Europe, Asia and North America; winters in sub-Saharan Africa, South America and southern Asia.',
    habitat: ['Farmland', 'Open country near water', 'Villages and outbuildings'],
    diet: ['Flying insects', 'Aphids and small flies', 'Hoverflies and beetles'],
    identification: [
      { field: 'Upperparts', detail: 'Glossy blue-black, catching an oily sheen in good light.' },
      { field: 'Face', detail: 'Deep chestnut-red forehead and throat, edged by a dark blue breast band.' },
      { field: 'Tail', detail: 'Deeply forked with thin outer streamers; longest in adult males.' },
      { field: 'Underparts', detail: 'Off-white to buff, never streaked.' },
      { field: 'In flight', detail: 'Low, fast and fluid with sudden banking turns — rarely glides for long.' },
    ],
    voice:
      'A cheerful twittering warble ending in a dry mechanical rattle, usually delivered from a wire or in flight.',
    behaviour:
      'Feeds low over pasture and water, often following livestock for disturbed insects. Gathers on wires in large pre-migration flocks in late summer.',
    breeding: {
      season: 'April to August, frequently two broods',
      nest: 'Open cup of mud pellets and straw, cemented to a beam, rafter or wall ledge under cover',
      clutch: [4, 5],
      incubationDays: [14, 16],
      fledgeDays: [18, 23],
      notes:
        'Pairs reuse and repair old nests. Fledglings return to the nest to roost and are fed on the wing for another week.',
    },
    fieldNotes: [
      'Check wires and fence lines on still, warm evenings — feeding birds drop to head height over grass.',
      'Listen for the rattle at the end of the song; it separates a swallow from a distant warbler instantly.',
      'Streamer length is a rough age and sex cue: short-streamered birds in autumn are usually juveniles.',
    ],
    similarSpecies: [
      { name: 'House Martin', howToTell: 'Bold white rump and shallow tail fork; no red throat.' },
      { name: 'Sand Martin', howToTell: 'Brown above with a clean brown breast band; smaller and more fluttery.' },
      { name: 'Common Swift', howToTell: 'All-dark scythe-shaped wings, no fork streamers, never perches on wires.' },
    ],
    tags: ['migrant', 'aerial-feeder', 'farmland', 'summer-visitor'],
  },

  {
    slug: 'european-robin',
    commonName: 'European Robin',
    scientificName: 'Erithacus rubecula',
    family: 'Muscicapidae (chats and flycatchers)',
    summary:
      'A round, long-legged chat with an orange-red breast, fiercely territorial year-round and famously confiding around gardeners.',
    audiences: ['birder'],
    lengthCm: [12.5, 14],
    wingspanCm: [20, 22],
    conservation: 'LC',
    distribution: 'Resident across most of Europe; northern and eastern populations move south and west in winter.',
    habitat: ['Woodland understorey', 'Hedgerows', 'Gardens and parks'],
    diet: ['Beetles and larvae', 'Earthworms', 'Berries in autumn', 'Seeds and fat at feeders'],
    identification: [
      { field: 'Breast', detail: 'Orange-red face and breast bordered by a soft blue-grey band.' },
      { field: 'Upperparts', detail: 'Plain olive-brown, unmarked.' },
      { field: 'Structure', detail: 'Rounded body, thin dark legs, large dark eye giving a gentle expression.' },
      { field: 'Juvenile', detail: 'No red at all — heavily gold-spotted brown, easily mistaken for another species.' },
      { field: 'Sexes', detail: 'Alike; males and females cannot be reliably separated in the field.' },
    ],
    voice:
      'A wistful, silvery warble of loose phrases, sung through winter as well as spring. Alarm is a hard repeated "tic".',
    behaviour:
      'Perches low, drops to the ground for prey, then flicks back up. Holds a winter territory — including females, which is unusual among European songbirds.',
    breeding: {
      season: 'March to July, usually two broods',
      nest: 'Cup of leaves and moss lined with hair, tucked into a bank, ivy, log pile or open-fronted box',
      clutch: [4, 6],
      incubationDays: [13, 14],
      fledgeDays: [13, 15],
      notes:
        'The female alone incubates and is fed on the nest by the male. Young leave before they can fly well and hide in cover.',
    },
    fieldNotes: [
      'Winter song from a lamp-lit garden at night is normal robin behaviour, not a nightingale.',
      'Turn over a border with a fork and a local robin will usually appear within a minute.',
      'Spotted juveniles in midsummer confuse more beginners than any other garden bird — look at the shape, not the colour.',
    ],
    similarSpecies: [
      { name: 'Common Redstart', howToTell: 'Constantly quivering rusty tail; male has a black face and white forehead.' },
      { name: 'Nightingale', howToTell: 'Larger, plain warm brown with a rufous tail and no orange breast.' },
    ],
    tags: ['garden', 'resident', 'songbird', 'territorial'],
  },

  {
    slug: 'common-kingfisher',
    commonName: 'Common Kingfisher',
    scientificName: 'Alcedo atthis',
    family: 'Alcedinidae (kingfishers)',
    summary:
      'A tiny, dagger-billed fish hunter, usually seen as an electric-blue streak low over a river before it is seen perched.',
    audiences: ['birder'],
    lengthCm: [16, 17],
    wingspanCm: [24, 26],
    conservation: 'LC',
    distribution: 'Widespread across Europe, Asia and North Africa; northern birds move south when waters freeze.',
    habitat: ['Slow clear rivers and streams', 'Canals', 'Lake margins', 'Coastal creeks in winter'],
    diet: ['Small fish such as minnows and sticklebacks', 'Aquatic insects', 'Freshwater shrimp', 'Tadpoles'],
    identification: [
      { field: 'Upperparts', detail: 'Cobalt back with a brilliant cyan stripe down the spine, obvious as it flies away.' },
      { field: 'Underparts', detail: 'Deep orange, with orange ear coverts and a white throat and neck patch.' },
      { field: 'Bill', detail: 'Long, heavy and dagger-like — all black in males; females show orange-red at the base of the lower mandible.' },
      { field: 'Structure', detail: 'Stumpy tail, very short red legs, oversized head for the body.' },
      { field: 'In flight', detail: 'Direct, whirring and low over the water surface, rarely rising above the bank.' },
    ],
    voice: 'A thin, piercing "zeee" or "chi-keee" whistle, usually the first sign the bird is present.',
    behaviour:
      'Hunts from a low overhanging perch, plunge-diving and returning to beat the fish against the branch before swallowing it head-first.',
    breeding: {
      season: 'April to July, often two broods',
      nest: 'Unlined chamber at the end of a horizontal tunnel up to a metre long, excavated in a vertical earth bank',
      clutch: [6, 7],
      incubationDays: [19, 21],
      fledgeDays: [23, 27],
      notes:
        'Both sexes dig and incubate. The chamber accumulates fish bones and is notoriously foul by fledging time.',
    },
    fieldNotes: [
      'Learn the call first — most kingfishers are heard passing before anyone sees the colour.',
      'Scan low branches, reed stems and moored ropes, not the open water.',
      'Bright blue is structural, not pigment: in flat light the bird can look surprisingly dull green-brown.',
    ],
    similarSpecies: [
      { name: 'Grey Wagtail', howToTell: 'Also a riverside bird with yellow underparts, but long-tailed and no blue.' },
    ],
    tags: ['wetland', 'resident', 'fish-eater', 'riverside'],
  },

  {
    slug: 'northern-cardinal',
    commonName: 'Northern Cardinal',
    scientificName: 'Cardinalis cardinalis',
    family: 'Cardinalidae (cardinals and allies)',
    summary:
      'A crested, heavy-billed songbird of eastern North America — the male vivid red, the female warm buff with red highlights.',
    audiences: ['birder'],
    lengthCm: [21, 23],
    wingspanCm: [25, 31],
    conservation: 'LC',
    distribution: 'Resident from southeastern Canada through the eastern and central United States to Mexico and Belize.',
    habitat: ['Woodland edge', 'Dense shrubs and thickets', 'Suburban gardens'],
    diet: ['Seeds and grain', 'Berries and fruit', 'Insects, especially when feeding young'],
    identification: [
      { field: 'Male', detail: 'Uniform bright red with a black face mask running from the eye around the bill.' },
      { field: 'Female', detail: 'Warm grey-buff with red wash on crest, wings and tail; mask reduced to grey.' },
      { field: 'Bill', detail: 'Massive, conical and coral-red — a seed-cracking bill visible at distance.' },
      { field: 'Crest', detail: 'Pointed and raised when alert, flattened when relaxed.' },
      { field: 'Juvenile', detail: 'Like the female but with a dark grey-black bill.' },
    ],
    voice:
      'Loud clear slurred whistles — "birdy-birdy-birdy" or "cheer-cheer-cheer". Both sexes sing, which is uncommon in North American songbirds.',
    behaviour:
      'Non-migratory and strongly paired; the male feeds the female beak-to-beak during courtship. Attacks its own reflection in windows and mirrors during the breeding season.',
    breeding: {
      season: 'March to September, two to three broods',
      nest: 'Loose cup of twigs, bark strips and grass, hidden 1–3 m up in dense shrubs or tangles',
      clutch: [2, 5],
      incubationDays: [11, 13],
      fledgeDays: [7, 13],
      notes:
        'Young leave the nest barely able to fly; the male takes over feeding them while the female starts the next clutch.',
    },
    fieldNotes: [
      'Feeders with black oil sunflower seed at dawn and dusk are the most reliable way to see them.',
      'Listen for the sharp metallic "chip" contact note in dense cover.',
      'A window-attacking cardinal in spring is not injured or ill — it is fighting its reflection.',
    ],
    similarSpecies: [
      { name: 'Summer Tanager', howToTell: 'Male is red but crestless with a pale bill and no black mask.' },
      { name: 'Pyrrhuloxia', howToTell: 'Grey body with red trim and a stubby, strongly curved yellowish bill.' },
    ],
    tags: ['garden', 'resident', 'songbird', 'north-america'],
  },

  {
    slug: 'peregrine-falcon',
    commonName: 'Peregrine Falcon',
    scientificName: 'Falco peregrinus',
    family: 'Falconidae (falcons)',
    summary:
      'A powerful, anchor-shaped raptor that kills birds in mid-air after a stoop — the fastest recorded animal, and now a common city nester.',
    audiences: ['birder'],
    lengthCm: [34, 58],
    wingspanCm: [74, 120],
    conservation: 'LC',
    distribution: 'Near-cosmopolitan — every continent except Antarctica, on sea cliffs, mountains and increasingly city buildings.',
    habitat: ['Sea cliffs and crags', 'Open uplands and estuaries', 'City centres with tall buildings'],
    diet: ['Pigeons and doves', 'Waders and wildfowl', 'Starlings and other flocking birds'],
    identification: [
      { field: 'Head', detail: 'Dark hood with a broad, blunt black moustachial stripe against a white cheek and throat.' },
      { field: 'Upperparts', detail: 'Slate blue-grey, paler on the rump.' },
      { field: 'Underparts', detail: 'Whitish, finely barred grey across the belly, flanks and underwing.' },
      { field: 'Structure', detail: 'Broad-based pointed wings and a short tail — a thickset anchor shape, not slim.' },
      { field: 'Juvenile', detail: 'Brown above with heavy vertical streaking below, rather than barring.' },
    ],
    voice: 'A harsh, ringing "kek-kek-kek" alarm near the nest, carrying a long way off a cliff face.',
    behaviour:
      'Hunts by climbing high and stooping with wings closed, striking prey with a clenched foot; stoop speeds above 300 km/h have been measured. Females are markedly larger than males.',
    breeding: {
      season: 'February to June, single brood',
      nest: 'No material — a scrape on a cliff ledge, quarry face, building parapet or nest platform',
      clutch: [3, 4],
      incubationDays: [29, 33],
      fledgeDays: [35, 42],
      notes:
        'Pairs are faithful to traditional ledges for decades. Populations collapsed under organochlorine pesticides mid-century and recovered after those were banned.',
    },
    fieldNotes: [
      'In cities, scan cathedral towers, chimneys and bridge girders — look for whitewash and plucked pigeon feathers below.',
      'Panic in a pigeon or wader flock often reveals a peregrine before you find the bird itself.',
      'Size alone separates the sexes when a pair is perched together: the female is roughly a third larger.',
    ],
    similarSpecies: [
      { name: 'Eurasian Hobby', howToTell: 'Slimmer with long scythe wings, streaked underparts and rusty trousers.' },
      { name: 'Merlin', howToTell: 'Much smaller and dashing, with a weak moustache and low hunting flight.' },
    ],
    tags: ['raptor', 'resident', 'urban', 'cliff-nester'],
  },

  {
    slug: 'barn-owl',
    commonName: 'Barn Owl',
    scientificName: 'Tyto alba',
    family: 'Tytonidae (barn owls)',
    summary:
      'A pale, heart-faced owl that hunts small mammals by sound on silent wings, quartering rough grassland at dusk.',
    audiences: ['birder'],
    lengthCm: [33, 39],
    wingspanCm: [80, 95],
    conservation: 'LC',
    distribution: 'One of the most widespread land birds in the world, absent mainly from the far north and central Asia.',
    habitat: ['Rough grassland and field margins', 'Farmland with old buildings', 'Marsh edge'],
    diet: ['Voles', 'Mice and shrews', 'Rats and young rabbits occasionally'],
    identification: [
      { field: 'Face', detail: 'White heart-shaped facial disc with small dark eyes set forward.' },
      { field: 'Upperparts', detail: 'Warm golden-buff, delicately marbled grey and speckled white.' },
      { field: 'Underparts', detail: 'White to buff — looks ghostly white in headlights or low sun.' },
      { field: 'Structure', detail: 'Long-winged and long-legged, with a short tail and big rounded head.' },
      { field: 'In flight', detail: 'Slow, buoyant and wavering, with frequent hovers and sudden drops.' },
    ],
    voice:
      'No hoot — a long, harsh, drawn-out shriek, plus hissing and bill-snapping from young at the nest.',
    behaviour:
      'Locates prey by asymmetric ear placement, allowing a strike in complete darkness. Fringed flight feathers muffle sound so effectively that the bird is silent to its prey.',
    breeding: {
      season: 'March to August, sometimes a second brood in vole-rich years',
      nest: 'No nest built — a pile of pellets in a barn loft, tree cavity, ruin or purpose-built box',
      clutch: [4, 7],
      incubationDays: [29, 34],
      fledgeDays: [50, 70],
      notes:
        'Eggs are laid at two-day intervals and incubated from the first, so chicks hatch staggered. In poor vole years the youngest rarely survive.',
    },
    fieldNotes: [
      'Best watched in the last hour of daylight in still weather; owls hunt in daylight most often when feeding large broods.',
      'Wet and windy nights ground them — their hearing and un-waterproofed plumage both suffer.',
      'Pellets beneath a beam are the cleanest way to confirm a roost without disturbing it.',
    ],
    similarSpecies: [
      { name: 'Short-eared Owl', howToTell: 'Also quarters open ground by day, but boldly streaked buff-brown with fierce yellow eyes.' },
      { name: 'Tawny Owl', howToTell: 'Round-faced, dark-eyed and rufous-brown; the classic hooter of woodland.' },
    ],
    tags: ['raptor', 'nocturnal', 'farmland', 'resident'],
  },

  {
    slug: 'great-spotted-woodpecker',
    commonName: 'Great Spotted Woodpecker',
    scientificName: 'Dendrocopos major',
    family: 'Picidae (woodpeckers)',
    summary:
      'A starling-sized pied woodpecker with bold white shoulder ovals and crimson vent, best known for its far-carrying spring drumming.',
    audiences: ['birder'],
    lengthCm: [20, 24],
    wingspanCm: [34, 39],
    conservation: 'LC',
    distribution: 'Resident across Europe, North Africa and temperate Asia to Japan.',
    habitat: ['Broadleaf and mixed woodland', 'Parks with mature trees', 'Gardens with feeders'],
    diet: ['Wood-boring beetle larvae', 'Conifer seeds prised from cones', 'Nestlings of small birds', 'Peanuts and fat at feeders'],
    identification: [
      { field: 'Pattern', detail: 'Black above with a large white oval on each shoulder and barred white wings.' },
      { field: 'Vent', detail: 'Bright crimson under the tail on all ages and sexes.' },
      { field: 'Male', detail: 'Small red patch on the nape; the female has none.' },
      { field: 'Juvenile', detail: 'Full red crown — brighter-headed than either adult, which misleads many observers.' },
      { field: 'In flight', detail: 'Deeply undulating — several fast beats, then wings closed.' },
    ],
    voice:
      'A sharp explosive "kik!", often repeated when agitated. Drumming is a rapid burst of roughly 10–16 strikes lasting under a second, used instead of song.',
    behaviour:
      'Climbs trunks in short jerks, propped on stiff tail feathers. Wedges cones and nuts into a bark crevice — an "anvil" — to hammer them open.',
    breeding: {
      season: 'April to June, single brood',
      nest: 'Fresh hole chiselled in a trunk or limb each year, with unlined wood chips at the bottom',
      clutch: [4, 6],
      incubationDays: [10, 13],
      fledgeDays: [20, 24],
      notes:
        'Both sexes excavate and feed. Older nestlings call loudly and continuously from inside the hole, making occupied nests easy to locate.',
    },
    fieldNotes: [
      'Drumming peaks from January to April; pitch and length help separate it from the slower, longer roll of a Lesser Spotted.',
      'Follow the "kik" call — the bird usually moves to the far side of the trunk as you approach.',
      'Check the crown on any summer bird at a feeder: an all-red cap means a juvenile, not a rarity.',
    ],
    similarSpecies: [
      { name: 'Lesser Spotted Woodpecker', howToTell: 'Sparrow-sized, ladder-barred back with no white shoulder ovals and no red vent.' },
      { name: 'Middle Spotted Woodpecker', howToTell: 'Pale face, red crown on both sexes and streaked pink-washed flanks.' },
    ],
    tags: ['woodland', 'resident', 'garden', 'cavity-nester'],
  },

  {
    slug: 'mallard',
    commonName: 'Mallard',
    scientificName: 'Anas platyrhynchos',
    family: 'Anatidae (ducks, geese and swans)',
    summary:
      'The familiar dabbling duck of ponds and rivers, and the ancestor of almost all domestic duck breeds.',
    audiences: ['birder', 'breeder'],
    lengthCm: [50, 65],
    wingspanCm: [81, 98],
    conservation: 'LC',
    distribution: 'Native across the northern hemisphere and introduced widely elsewhere; among the most numerous ducks on earth.',
    habitat: ['Ponds and lakes', 'Slow rivers and canals', 'Coastal marsh in winter'],
    diet: ['Seeds and aquatic plants', 'Invertebrates and snails', 'Grain and waste crops'],
    identification: [
      { field: 'Male (breeding)', detail: 'Bottle-green head, thin white collar, purple-brown breast and grey body with a curled black tail feather.' },
      { field: 'Female', detail: 'Mottled brown throughout with a dark eye-stripe and an orange-and-dark bill.' },
      { field: 'Both sexes', detail: 'Blue-purple speculum on the wing bordered front and back by white — the key mark at any age.' },
      { field: 'Eclipse male', detail: 'Mid-summer males resemble females but keep a plain yellow bill.' },
      { field: 'Legs', detail: 'Orange, set well forward for walking on land.' },
    ],
    voice: 'The loud descending "quack" quack is the female; males give a quieter, rasping "raeb".',
    behaviour:
      'Dabbles and up-ends rather than diving. Moults all flight feathers at once in mid-summer and is flightless for around three to four weeks.',
    breeding: {
      season: 'March to July, single brood, replacement clutches if lost',
      nest: 'Down-lined scrape in dense ground vegetation, occasionally well away from water',
      clutch: [9, 13],
      incubationDays: [27, 28],
      fledgeDays: [50, 60],
      notes:
        'Ducklings are precocial — down-covered, mobile and self-feeding within a day of hatching, but still brooded by the female.',
    },
    aviculture: {
      difficulty: 'beginner',
      lifespanYears: [5, 10],
      minEnclosureCm: [400, 400, 200],
      diet:
        'Waterfowl pellets or mixed grain, supplemented with greens and aquatic invertebrates. Breeders need higher-protein pellets before laying.',
      social:
        'Keep in groups but watch the sex ratio — several drakes to one duck causes injury and drowning during mating. Aim for one drake per three or more ducks.',
      sexing:
        'Easy from plumage outside the eclipse moult; bill colour and the drake\'s curled tail feather work year-round.',
      notes:
        'Needs clean open water deep enough to bathe and a dry, predator-proof night shelter. Keeping and releasing waterfowl is regulated in many countries — check local rules before acquiring stock.',
    },
    fieldNotes: [
      'Scan mixed duck flocks for the speculum on stretching birds — it identifies awkward juveniles and eclipse males.',
      'Park ducks often show odd white patches from domestic ancestry; these are hybrids, not rare species.',
      'A female with a large brood in early spring may be pooling ducklings from other broods.',
    ],
    similarSpecies: [
      { name: 'Gadwall', howToTell: 'Finely vermiculated grey with a black stern and a clean white speculum.' },
      { name: 'Northern Pintail', howToTell: 'Slimmer and longer-necked, with a chocolate head and white neck stripe.' },
    ],
    tags: ['wetland', 'resident', 'waterfowl', 'domesticated'],
  },

  {
    slug: 'budgerigar',
    commonName: 'Budgerigar',
    scientificName: 'Melopsittacus undulatus',
    family: 'Psittaculidae (Old World parrots)',
    summary:
      'A small nomadic Australian grass parakeet, and after centuries of selective breeding the most widely kept pet bird in the world.',
    audiences: ['birder', 'breeder'],
    lengthCm: [18, 20],
    wingspanCm: [25, 30],
    conservation: 'LC',
    distribution: 'Wild birds are nomadic across arid and semi-arid inland Australia, following rainfall and seeding grasses.',
    habitat: ['Open scrub and spinifex', 'Dry grassland', 'Timbered watercourses'],
    diet: ['Grass and herb seeds', 'Ripening grain', 'Green shoots after rain'],
    identification: [
      { field: 'Wild type', detail: 'Green below, yellow head with fine black barring across the nape, back and wings.' },
      { field: 'Face', detail: 'Yellow mask with three to six small black throat spots and violet-blue cheek patches.' },
      { field: 'Cere', detail: 'Blue in mature males, brown or tan in breeding-condition females, pale in immatures.' },
      { field: 'Tail', detail: 'Long, narrow and blue-green, giving the slim silhouette in flight.' },
      { field: 'Captive colours', detail: 'Blue, grey, albino, lutino, pied, spangle and opaline varieties are common; none occur in the wild.' },
    ],
    voice: 'A constant, cheerful chatter of warbles and chirrups; skilled individuals mimic speech and household sounds.',
    behaviour:
      'Highly social, feeding on the ground in flocks that can number thousands in wild irruption years. Captive birds are active climbers and chewers and need daily flight time.',
    breeding: {
      season: 'Opportunistic in the wild, after rain; in aviculture usually set up in spring',
      nest: 'Unlined hollow in a eucalypt limb or fence post; in captivity a wooden nest box with a concave base',
      clutch: [4, 6],
      incubationDays: [18, 21],
      fledgeDays: [30, 35],
      notes:
        'Eggs are laid every other day and incubated from the first, so a clutch hatches over a week and chick sizes differ markedly.',
    },
    aviculture: {
      difficulty: 'beginner',
      lifespanYears: [5, 10],
      minEnclosureCm: [60, 40, 50],
      diet:
        'Quality budgerigar seed mix or pellets, fresh greens such as spinach and broccoli, millet spray as a treat, plus cuttlefish bone and a mineral block. Avoid avocado, chocolate and salt.',
      social:
        'Flock birds — keep at least a pair unless you can give a single bird several hours of attention daily.',
      sexing:
        'Cere colour from about four months: royal blue in cocks, tan to dark brown in hens. Unreliable in lutino, albino and recessive pied birds, which need DNA sexing.',
      notes:
        'The concave nest-box base stops eggs rolling and splayed legs in chicks. Limit hens to two clutches a year — continuous breeding causes calcium depletion and egg binding. Cage length matters far more than height because budgerigars fly horizontally.',
    },
    fieldNotes: [
      'Wild flocks in Australia are best found at waterholes at dawn during dry spells.',
      'Escaped pet birds turn up worldwide but rarely establish — a lone blue budgerigar on a feeder is someone\'s lost pet.',
      'Barring on the forehead means a bird under about four months old; it clears at the first moult.',
    ],
    similarSpecies: [
      { name: 'Bourke\'s Parrot', howToTell: 'Pink-bellied, brown-backed and crepuscular; no black barring.' },
      { name: 'Rose-ringed Parakeet', howToTell: 'Much larger and all green with a heavy red bill and very long tail.' },
    ],
    tags: ['parrot', 'aviculture', 'australia', 'flock'],
  },

  {
    slug: 'cockatiel',
    commonName: 'Cockatiel',
    scientificName: 'Nymphicus hollandicus',
    family: 'Cacatuidae (cockatoos)',
    summary:
      'A slim, crested Australian cockatoo — the smallest of its family and a gentle, long-lived companion bird.',
    audiences: ['birder', 'breeder'],
    lengthCm: [30, 33],
    wingspanCm: [30, 35],
    conservation: 'LC',
    distribution: 'Widespread across inland Australia, nomadic in response to rainfall; absent from Tasmania and coastal forest.',
    habitat: ['Open woodland and scrub', 'Grassland with scattered trees', 'Watercourses in arid country'],
    diet: ['Grass and acacia seeds', 'Grain crops', 'Fruit and berries occasionally'],
    identification: [
      { field: 'Crest', detail: 'Long mobile crest — held upright when alert, swept back in flight, flattened when threatened.' },
      { field: 'Male (wild type)', detail: 'Grey body, clean bright yellow face and crest, deep orange cheek patch.' },
      { field: 'Female (wild type)', detail: 'Duller grey-yellow face, muted cheek patch, and yellow barring under the tail.' },
      { field: 'Wing', detail: 'Bold white shoulder panel, conspicuous in flight on both sexes.' },
      { field: 'Captive colours', detail: 'Lutino, pied, pearl, cinnamon and whiteface mutations are widespread.' },
    ],
    voice:
      'A rolling, querulous "queel-queel" whistle. Males whistle elaborate learned tunes; females are markedly quieter.',
    behaviour:
      'Feeds mostly on the ground, perches lengthwise along dead branches. Prone to sudden "night frights" in the dark — a dim night light in the bird room prevents injury.',
    breeding: {
      season: 'Rain-dependent in the wild; spring and early summer in aviculture',
      nest: 'Tree hollow near water; in captivity a vertical nest box roughly 30 cm tall with a concave base',
      clutch: [4, 7],
      incubationDays: [18, 22],
      fledgeDays: [28, 35],
      notes:
        'Unusually, the male incubates through the day and the female overnight. Young are weaned about two to three weeks after fledging.',
    },
    aviculture: {
      difficulty: 'beginner',
      lifespanYears: [15, 25],
      minEnclosureCm: [60, 60, 90],
      diet:
        'Pelleted base diet with a modest seed mix, daily fresh vegetables and leafy greens, and cuttlefish bone. Seed-only diets cause obesity and fatty liver disease.',
      social:
        'Very tolerant of company and of people. A single hand-reared bird bonds strongly to its keeper but needs several hours out of the cage daily.',
      sexing:
        'Wild-type adults sex easily on face colour and tail barring after the first moult at six to nine months. Lutino, pied and whiteface birds usually need DNA sexing.',
      notes:
        'Cockatiels produce heavy feather dust — good ventilation matters for both bird and keeper. Chronic egg-laying in lone hens is common; shorten daylight to about ten hours and remove nest-like cavities to stop it. This is a 20-year commitment, not a starter pet.',
    },
    fieldNotes: [
      'In Australia look for flocks flying fast and direct to water in the early morning, calling constantly.',
      'The white wing panel is the best flight mark against a similar-sized parrot.',
      'A hissing, rocking bird with a flattened crest in an aviary is frightened, not aggressive — back off rather than reaching in.',
    ],
    similarSpecies: [
      { name: 'Galah', howToTell: 'Much bulkier, pink and grey with a short white crest.' },
      { name: 'Princess Parrot', howToTell: 'Slim and long-tailed but pastel green and blue, with no crest.' },
    ],
    tags: ['parrot', 'aviculture', 'australia', 'companion-bird'],
  },

  {
    slug: 'zebra-finch',
    commonName: 'Zebra Finch',
    scientificName: 'Taeniopygia guttata',
    family: 'Estrildidae (estrildid finches)',
    summary:
      'A tiny, ceaselessly active Australian grassfinch, easy to breed and the most studied songbird in laboratory science.',
    audiences: ['birder', 'breeder'],
    lengthCm: [10, 11],
    wingspanCm: [12, 15],
    conservation: 'LC',
    distribution: 'Across most of mainland Australia, plus Timor and the Lesser Sundas; introduced to Portugal and Puerto Rico.',
    habitat: ['Dry grassland and scrub', 'Open woodland near water', 'Farmland and settlements'],
    diet: ['Small grass seeds', 'Ripening seed heads', 'Insects when rearing chicks'],
    identification: [
      { field: 'Male', detail: 'Orange cheek patch, black-and-white barred throat, chestnut flanks spotted white.' },
      { field: 'Female', detail: 'Plain grey-buff with no cheek patch, barring or flank spots.' },
      { field: 'Both sexes', detail: 'Black-and-white "tear" stripe below the eye, black-and-white barred tail, red-orange bill.' },
      { field: 'Bill', detail: 'Deep coral-red in males, paler orange in females — visible from fledging.' },
      { field: 'Captive colours', detail: 'Fawn, pied, white, black-cheeked and crested varieties are all established.' },
    ],
    voice:
      'A nasal toy-trumpet "meep" contact call given constantly. Only the male sings — a short, buzzy, rhythmic phrase learned from a tutor as a juvenile.',
    behaviour:
      'Never still; feeds in tight flocks on the ground and drinks by sucking rather than tipping the head back, an adaptation to arid country.',
    breeding: {
      season: 'Opportunistic after rain in the wild; year-round in captivity if allowed',
      nest: 'Domed grass nest with a side entrance, in a shrub, hollow or wicker nest basket',
      clutch: [4, 6],
      incubationDays: [12, 16],
      fledgeDays: [17, 21],
      notes:
        'Both sexes incubate and both feed the young. Juveniles are independent about two to three weeks after fledging and can breed at three months — far too young to be safe.',
    },
    aviculture: {
      difficulty: 'beginner',
      lifespanYears: [5, 7],
      minEnclosureCm: [80, 40, 40],
      diet:
        'Foreign finch or millet-based seed mix, soaked and sprouted seed while rearing, egg food during breeding, plus grit, cuttlefish bone and daily greens.',
      social:
        'Colony birds — keep several pairs together rather than a single pair, but give each pair more nest sites than it needs to prevent squabbling.',
      sexing: 'Trivial in wild-type birds from about six weeks: only males have the orange cheek and barred throat.',
      notes:
        'The commonest beginner mistake is leaving nest baskets up permanently — pairs will breed themselves into exhaustion. Remove nests after two or three clutches a year. Do not pair birds under nine months old. Zebra finches are poor foster parents to handle, so plan for the pair to rear their own.',
    },
    fieldNotes: [
      'In the wild, watch stock troughs and dams in the heat of the day — flocks come in to drink repeatedly.',
      'The barred tail is a good mark on birds flushed from long grass.',
      'Song learning is sensitive to the tutor present in the first months, so aviary-bred males inherit their father\'s phrase.',
    ],
    similarSpecies: [
      { name: 'Double-barred Finch', howToTell: 'Owl-faced with two black breast bars and no orange cheek.' },
      { name: 'Bengalese Finch', howToTell: 'Domesticated only; brown-and-white pied with a stubby grey bill and no cheek patch.' },
    ],
    tags: ['finch', 'aviculture', 'australia', 'colony'],
  },

  {
    slug: 'atlantic-canary',
    commonName: 'Atlantic Canary',
    scientificName: 'Serinus canaria',
    family: 'Fringillidae (true finches)',
    summary:
      'A streaky green-yellow island finch from Macaronesia, bred in captivity for five centuries for song, colour and form.',
    audiences: ['birder', 'breeder'],
    lengthCm: [12, 13.5],
    wingspanCm: [20, 23],
    conservation: 'LC',
    distribution: 'Native to the Canary Islands, Madeira and the Azores; feral populations elsewhere derive from escaped cage birds.',
    habitat: ['Laurel forest edge', 'Orchards and cultivation', 'Scrub and gardens'],
    diet: ['Small seeds', 'Fresh greens and buds', 'Soft fruit', 'Insects while rearing young'],
    identification: [
      { field: 'Wild type', detail: 'Grey-green above with dark streaking, yellow-green face and breast, whitish belly — not the plain yellow of cage birds.' },
      { field: 'Female', detail: 'Duller and greyer than the male, with heavier streaking.' },
      { field: 'Rump', detail: 'Yellowish-green, noticeable as the bird flies away.' },
      { field: 'Domestic forms', detail: 'Selectively bred into yellow, white, red-factor, cinnamon and crested varieties, and into song breeds such as the Roller and Waterslager.' },
      { field: 'Bill', detail: 'Short, conical and pale — a typical finch seed bill.' },
    ],
    voice:
      'A sustained, silvery rolling warble of trills and bell notes. Only males sing in full; song breeds are judged on specific tour and roll structure.',
    behaviour:
      'Feeds in loose flocks outside the breeding season, often on the ground. Captive males sing most strongly under lengthening daylight in late winter and spring.',
    breeding: {
      season: 'January to July in the wild; triggered in captivity by increasing day length',
      nest: 'Neat cup of grass, moss and hair high in a shrub or tree; in captivity an open wire or plastic nest pan with felt lining',
      clutch: [3, 5],
      incubationDays: [13, 14],
      fledgeDays: [14, 21],
      notes:
        'The hen alone incubates. Many breeders swap eggs for dummies as they are laid and return the full clutch on the day the last is laid, so that all chicks hatch together.',
    },
    aviculture: {
      difficulty: 'intermediate',
      lifespanYears: [10, 15],
      minEnclosureCm: [60, 30, 40],
      diet:
        'Canary seed mix based on canary grass seed and rape, daily greens such as chickweed and broccoli, egg food and soaked seed through the breeding season, plus grit and cuttlefish bone. Red-factor birds need a colour-feeding supplement during the moult for full colour.',
      social:
        'Unlike most finches, canaries are territorial and cocks fight — house males singly or in well-spaced flights, and pair them only for breeding.',
      sexing:
        'No reliable plumage difference in most varieties. Singing indicates a cock; in breeding condition the hen shows a broad flat vent and the cock a protruding one. DNA sexing is the certain method.',
      notes:
        'Pair the birds only when the hen is carrying nest material and the cock is in full song, and separate them if fighting starts. The annual moult in late summer is demanding — stop breeding, keep protein up and expect the song to stop until it finishes. Air quality matters: canaries are famously sensitive to fumes from non-stick cookware, smoke and aerosols.',
    },
    fieldNotes: [
      'On Tenerife and Madeira listen along forest tracks and terraced gardens — the song carries further than the bird is visible.',
      'A plain yellow "canary" seen outdoors in Europe is an escaped cage bird, not the wild species.',
      'Wild birds look far more streaked and dowdy than beginners expect from the cage-bird image.',
    ],
    similarSpecies: [
      { name: 'European Serin', howToTell: 'Smaller and stubbier-billed with a bright yellow rump and buzzy jangling song.' },
      { name: 'European Greenfinch', howToTell: 'Bulkier and unstreaked with bright yellow wing and tail flashes.' },
    ],
    tags: ['finch', 'aviculture', 'songbird', 'island'],
  },
] as const

const BY_SLUG = new Map(BIRDS.map((b) => [b.slug, b]))

export function getBird(slug: string): Bird | undefined {
  return BY_SLUG.get(slug)
}

export function allTags(): string[] {
  return [...new Set(BIRDS.flatMap((b) => b.tags))].sort()
}

/** Case-insensitive match across the fields a birder would actually type. */
export function searchBirds(
  query: string,
  filters: { audience?: string; tag?: string } = {}
): Bird[] {
  const q = query.trim().toLowerCase()

  return BIRDS.filter((bird) => {
    if (filters.audience && !bird.audiences.includes(filters.audience as never)) {
      return false
    }
    if (filters.tag && !bird.tags.includes(filters.tag)) {
      return false
    }
    if (!q) return true

    const haystack = [
      bird.commonName,
      bird.scientificName,
      bird.family,
      bird.summary,
      ...bird.habitat,
      ...bird.tags,
    ]
      .join(' ')
      .toLowerCase()

    return haystack.includes(q)
  })
}
