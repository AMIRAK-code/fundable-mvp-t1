import Foundation

enum TipCategory: String, Codable, CaseIterable, Identifiable {
    case nutrition = "Nutrition"
    case enrichment = "Enrichment"
    case health = "Health"
    case grooming = "Grooming"
    case bonding = "Bonding"
    case habitat = "Habitat"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .nutrition: return "fork.knife"
        case .enrichment: return "puzzlepiece.fill"
        case .health: return "heart.fill"
        case .grooming: return "comb.fill"
        case .bonding: return "person.2.fill"
        case .habitat: return "house.fill"
        }
    }
}

struct PetTip: Identifiable {
    let id: String
    let category: TipCategory
    let text: String
}

struct SpeciesCareGuide {
    let dailyBasics: [String]
    let redFlags: [String]
}

enum TipsLibrary {

    /// Deterministic tip of the day: same tip all day, new tip tomorrow.
    static func dailyTip(for species: PetSpecies, on date: Date = Date()) -> PetTip {
        let list = tips(for: species)
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return list[day % list.count]
    }

    static func tips(for species: PetSpecies) -> [PetTip] {
        switch species {
        case .dog: return dogTips
        case .cat: return catTips
        case .rabbit: return rabbitTips
        case .hamster: return hamsterTips
        case .parrot: return parrotTips
        }
    }

    static func careGuide(for species: PetSpecies) -> SpeciesCareGuide {
        switch species {
        case .dog:
            return SpeciesCareGuide(
                dailyBasics: [
                    "Fresh water and measured meals",
                    "A walk with unhurried sniffing time",
                    "A slow hands-on body check for lumps or soreness",
                    "A predictable routine — dogs relax into rhythm",
                ],
                redFlags: [
                    "Swollen, hard belly with unproductive retching (possible bloat)",
                    "Collapse, fainting, or a seizure",
                    "Struggling to breathe",
                    "Repeated vomiting, or vomit with blood",
                ]
            )
        case .cat:
            return SpeciesCareGuide(
                dailyBasics: [
                    "Check litter box habits — frequency and effort",
                    "A short play session that mimics hunting",
                    "Fresh water placed away from food",
                    "Notice hiding or grooming changes",
                ],
                redFlags: [
                    "Straining in the litter box with little or no urine — emergency in male cats",
                    "Open-mouth or labored breathing",
                    "Not eating for more than 24 hours",
                    "Sudden inability to use the back legs",
                ]
            )
        case .rabbit:
            return SpeciesCareGuide(
                dailyBasics: [
                    "Unlimited fresh hay, topped up morning and evening",
                    "Check droppings — number, size, and shape",
                    "Several hours of space to run and stretch",
                    "Keep the room comfortably cool",
                ],
                redFlags: [
                    "Not eating or no droppings for 8–12 hours (GI stasis)",
                    "Head tilt or rolling",
                    "Maggots or a soiled rear end (flystrike)",
                    "Labored breathing, screaming, or collapse",
                ]
            )
        case .hamster:
            return SpeciesCareGuide(
                dailyBasics: [
                    "Check the water bottle actually flows",
                    "Scatter a little food for foraging",
                    "Spot-clean the toilet corner",
                    "Confirm normal evening activity",
                ],
                redFlags: [
                    "A wet, soiled tail area ('wet tail')",
                    "No activity at all during the evening",
                    "Clicking or labored breathing",
                    "Falling over, rolling, or circling",
                ]
            )
        case .parrot:
            return SpeciesCareGuide(
                dailyBasics: [
                    "Fresh water, pellets, and a vegetable or two",
                    "Check droppings for color and consistency",
                    "Calm social time out of the cage",
                    "A consistent 10–12 hour dark sleep window",
                ],
                redFlags: [
                    "Fluffed up and sleepy during the day, or sitting on the cage floor",
                    "Tail bobbing with each breath (labored breathing)",
                    "Blood on feathers, or a bleeding blood feather",
                    "Not eating, or unable to perch",
                ]
            )
        }
    }

    // MARK: - Dog

    private static let dogTips: [PetTip] = [
        PetTip(id: "dog.tip.01", category: .nutrition, text: "Measure meals with a cup rather than eyeballing — steady portions make weight drift visible early."),
        PetTip(id: "dog.tip.02", category: .nutrition, text: "Refresh water twice a day and wash the bowl daily; the slippery film that builds up harbors bacteria."),
        PetTip(id: "dog.tip.03", category: .enrichment, text: "Ten minutes of slow, sniff-led walking tires a dog as much as a brisk one. Let the nose set the route today."),
        PetTip(id: "dog.tip.04", category: .enrichment, text: "Rotate toys weekly. A toy that disappears and returns feels new again and keeps play calm but engaging."),
        PetTip(id: "dog.tip.05", category: .health, text: "Run your hands slowly over your dog once a day. You'll find ticks, lumps, or sore spots long before they show."),
        PetTip(id: "dog.tip.06", category: .health, text: "Sniff-check the ears weekly: a sweet or yeasty smell is one of the earliest signs of an ear infection."),
        PetTip(id: "dog.tip.07", category: .health, text: "Drinking noticeably more water for several days in a row is always worth mentioning to your vet."),
        PetTip(id: "dog.tip.08", category: .grooming, text: "Brush before baths, not after — mats tighten when they get wet."),
        PetTip(id: "dog.tip.09", category: .grooming, text: "If you can hear nails clicking on a hard floor, it's time for a trim."),
        PetTip(id: "dog.tip.10", category: .bonding, text: "End every training session on a success, even a tiny one. Short and confident beats long and frustrated."),
        PetTip(id: "dog.tip.11", category: .bonding, text: "A soft yawn and a slow blink are canine calm signals. Answer with quiet praise, not excitement."),
        PetTip(id: "dog.tip.12", category: .habitat, text: "Give your dog a den-like resting spot away from foot traffic. Deep sleep lowers reactivity all day."),
    ]

    // MARK: - Cat

    private static let catTips: [PetTip] = [
        PetTip(id: "cat.tip.01", category: .nutrition, text: "Cats prefer to drink away from where they eat. Try a water bowl in another room and watch intake rise."),
        PetTip(id: "cat.tip.02", category: .nutrition, text: "Serve part of the daily kibble in a puzzle feeder — working for food mirrors natural foraging."),
        PetTip(id: "cat.tip.03", category: .enrichment, text: "Five minutes of wand-toy play before a meal mimics hunt-then-eat and can quiet the night zoomies."),
        PetTip(id: "cat.tip.04", category: .enrichment, text: "A plain cardboard box in a new spot is real enrichment. Cheap novelty, calm cat."),
        PetTip(id: "cat.tip.05", category: .health, text: "Glance at the litter box every day. Changes in frequency or effort are the earliest illness signal cats give."),
        PetTip(id: "cat.tip.06", category: .health, text: "Hiding more than usual is how cats show pain. If it lasts a full day, take it seriously."),
        PetTip(id: "cat.tip.07", category: .health, text: "Weigh your cat monthly — a half-kilo drift on a small body is significant and easy to miss by eye."),
        PetTip(id: "cat.tip.08", category: .grooming, text: "Two gentle minutes of brushing daily beats a weekly marathon most cats will only tolerate once."),
        PetTip(id: "cat.tip.09", category: .grooming, text: "Check claws monthly on indoor cats. Overgrown claws can curl back into the paw pads."),
        PetTip(id: "cat.tip.10", category: .bonding, text: "Slow-blink at your cat, then look away. It's feline for 'we're good' — many cats blink back."),
        PetTip(id: "cat.tip.11", category: .habitat, text: "Vertical space calms cats. A cleared shelf by a window is a five-star perch."),
        PetTip(id: "cat.tip.12", category: .habitat, text: "One litter box per cat plus one spare, in quiet spots, keeps stress and accidents down."),
    ]

    // MARK: - Rabbit

    private static let rabbitTips: [PetTip] = [
        PetTip(id: "rabbit.tip.01", category: .nutrition, text: "Unlimited hay is non-negotiable: it should be about 80% of the diet and keeps both teeth and gut moving."),
        PetTip(id: "rabbit.tip.02", category: .nutrition, text: "Introduce any new leafy green over a week, one at a time. Rabbit digestion dislikes surprises."),
        PetTip(id: "rabbit.tip.03", category: .health, text: "A rabbit that skips two meals is an emergency, not a mood — GI stasis develops within hours."),
        PetTip(id: "rabbit.tip.04", category: .health, text: "Count droppings daily, roughly. Smaller, fewer, or absent droppings are the earliest stasis warning."),
        PetTip(id: "rabbit.tip.05", category: .health, text: "In warm months, check the tail area every day. Flystrike moves fast and is genuinely dangerous."),
        PetTip(id: "rabbit.tip.06", category: .enrichment, text: "Cardboard tunnels and untreated willow balls satisfy the need to chew — safely."),
        PetTip(id: "rabbit.tip.07", category: .enrichment, text: "Scatter pellets in a snuffle mat instead of a bowl. Foraging time is calming time."),
        PetTip(id: "rabbit.tip.08", category: .grooming, text: "During a moult, brush daily. Swallowed fur can slow a rabbit's gut — and they can't cough up hairballs."),
        PetTip(id: "rabbit.tip.09", category: .bonding, text: "Sit on the floor and let the rabbit come to you. Hands descending from above read as hawks."),
        PetTip(id: "rabbit.tip.10", category: .bonding, text: "A rabbit flopping onto its side near you is deep trust. A quiet tooth-purr while petting means keep going."),
        PetTip(id: "rabbit.tip.11", category: .habitat, text: "A hutch is a bedroom, not a home. Rabbits need hours of run-around space daily — a puppy pen works well."),
        PetTip(id: "rabbit.tip.12", category: .habitat, text: "Rabbits struggle above 26°C. On hot days, offer a frozen water bottle to stretch out against."),
    ]

    // MARK: - Hamster

    private static let hamsterTips: [PetTip] = [
        PetTip(id: "hamster.tip.01", category: .habitat, text: "Floor space beats levels: aim for at least 80×50 cm of unbroken floor with 20+ cm of bedding to burrow."),
        PetTip(id: "hamster.tip.02", category: .habitat, text: "Keep the cage out of direct sun and drafts. Hamsters are surprisingly sensitive to temperature swings."),
        PetTip(id: "hamster.tip.03", category: .nutrition, text: "Scatter the seed mix through the bedding instead of using a bowl — foraging is a hamster's main hobby."),
        PetTip(id: "hamster.tip.04", category: .nutrition, text: "Fresh food in tiny amounts: a fingernail-sized piece of vegetable is a full serving."),
        PetTip(id: "hamster.tip.05", category: .health, text: "Weigh weekly in a mug on kitchen scales. Steady weight loss is often the only visible sign of illness."),
        PetTip(id: "hamster.tip.06", category: .health, text: "A wet or soiled tail area is urgent — 'wet tail' can become fatal within days. See a vet promptly."),
        PetTip(id: "hamster.tip.07", category: .health, text: "Check food stashes weekly and quietly remove fresh food before it molds."),
        PetTip(id: "hamster.tip.08", category: .enrichment, text: "The wheel should be at least 25 cm across with a solid surface — a curved spine while running causes pain."),
        PetTip(id: "hamster.tip.09", category: .enrichment, text: "Offer a weekly sand bath (sand, never dust). It keeps the coat clean and is wonderful to watch."),
        PetTip(id: "hamster.tip.10", category: .bonding, text: "Speak before you touch. A startled sleepy hamster bites; a warned one climbs aboard."),
        PetTip(id: "hamster.tip.11", category: .bonding, text: "Handle in the evening when they're naturally awake. Daytime wake-ups are stressful."),
        PetTip(id: "hamster.tip.12", category: .grooming, text: "Long-haired Syrians appreciate a gentle brush with a soft toothbrush during moults."),
    ]

    // MARK: - Parrot

    private static let parrotTips: [PetTip] = [
        PetTip(id: "parrot.tip.01", category: .nutrition, text: "Pellets plus fresh vegetables should be the base of the diet. All-seed diets are the top cause of parrot illness."),
        PetTip(id: "parrot.tip.02", category: .nutrition, text: "Never share avocado, chocolate, caffeine, or alcohol — all four are toxic to birds."),
        PetTip(id: "parrot.tip.03", category: .health, text: "Birds hide illness. A parrot fluffed up with half-closed eyes during the day needs a vet promptly."),
        PetTip(id: "parrot.tip.04", category: .health, text: "Glance at droppings daily. A color or consistency change that lasts a day is an early warning."),
        PetTip(id: "parrot.tip.05", category: .health, text: "Fumes from an overheated non-stick pan can kill a bird in minutes. Keep the cage far from the kitchen."),
        PetTip(id: "parrot.tip.06", category: .enrichment, text: "Foraging beats bowls: wrap some food in paper cups or cardboard so meals take effort and thought."),
        PetTip(id: "parrot.tip.07", category: .enrichment, text: "Rotate perches and toys monthly. A static cage breeds the boredom behind feather-plucking."),
        PetTip(id: "parrot.tip.08", category: .bonding, text: "Two calm ten-minute sessions of talking or training beat an hour of intense attention."),
        PetTip(id: "parrot.tip.09", category: .bonding, text: "Learn your bird's 'yes' body language — leaning in, relaxed feathers — and stop before it becomes 'no'."),
        PetTip(id: "parrot.tip.10", category: .habitat, text: "Place the cage against a wall rather than floating by a window. A protected back means better rest."),
        PetTip(id: "parrot.tip.11", category: .habitat, text: "Parrots need 10–12 hours of dark, quiet sleep. A cover and a consistent bedtime prevent crankiness."),
        PetTip(id: "parrot.tip.12", category: .grooming, text: "Offer a shallow bath or a gentle mist a few times a week — good feather condition starts with water."),
    ]
}
