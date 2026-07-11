import Foundation

enum SymptomUrgency: Int, Codable, CaseIterable, Comparable {
    case mild = 0
    case concerning = 1
    case urgent = 2

    static func < (lhs: SymptomUrgency, rhs: SymptomUrgency) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var badge: String {
        switch self {
        case .mild: return "Mild"
        case .concerning: return "Concerning"
        case .urgent: return "Urgent"
        }
    }

    var label: String {
        switch self {
        case .mild: return "Keep a gentle eye on it"
        case .concerning: return "Book a vet visit soon"
        case .urgent: return "Contact a vet now"
        }
    }

    var symbolName: String {
        switch self {
        case .mild: return "eye.fill"
        case .concerning: return "exclamationmark.triangle.fill"
        case .urgent: return "cross.case.fill"
        }
    }
}

struct PetSymptom: Identifiable {
    let id: String
    let name: String
    let urgency: SymptomUrgency
    let possibleCauses: [String]
    let guidance: String
}

enum VetDisclaimer {
    static let short = "Pet Monitor never diagnoses — always confirm with your veterinarian."
    static let full = "Pet Monitor offers general guidance to help you notice changes early. It is not a medical device and never replaces professional care. If you are worried about your pet — even a little — contact your veterinarian. When in doubt, call: vets would always rather hear from you early."
}

enum SymptomLibrary {

    static func symptoms(for species: PetSpecies) -> [PetSymptom] {
        switch species {
        case .dog: return dogSymptoms
        case .cat: return catSymptoms
        case .rabbit: return rabbitSymptoms
        case .hamster: return hamsterSymptoms
        case .parrot: return parrotSymptoms
        }
    }

    static func symptom(id: String, for species: PetSpecies) -> PetSymptom? {
        symptoms(for: species).first { $0.id == id }
    }

    // MARK: - Dog

    private static let dogSymptoms: [PetSymptom] = [
        PetSymptom(
            id: "dog.lowappetite", name: "Not eating well", urgency: .concerning,
            possibleCauses: ["Stress or routine change", "Dental pain", "Stomach upset", "Early sign of many illnesses"],
            guidance: "Offer a bland favorite and remove uneaten food after 20 minutes. If meals are skipped for more than 24 hours, book a vet visit."
        ),
        PetSymptom(
            id: "dog.vomiting", name: "Vomiting", urgency: .concerning,
            possibleCauses: ["Ate something unsuitable", "Infection", "Obstruction (if repeated)"],
            guidance: "Rest the stomach for a few hours, then offer small sips of water. Repeated vomiting, blood, or a bloated belly means go to the vet now."
        ),
        PetSymptom(
            id: "dog.diarrhea", name: "Diarrhea", urgency: .concerning,
            possibleCauses: ["Diet change", "Parasites", "Infection"],
            guidance: "Keep water available and feed small bland meals. See a vet if it lasts beyond 24–48 hours, contains blood, or your dog seems weak."
        ),
        PetSymptom(
            id: "dog.lethargy", name: "Low energy, withdrawn", urgency: .concerning,
            possibleCauses: ["Pain", "Fever or infection", "Heart or metabolic issues"],
            guidance: "A quiet day happens; a flat, uninterested dog does not. If it lasts more than a day or comes with other signs, call your vet."
        ),
        PetSymptom(
            id: "dog.limping", name: "Limping", urgency: .concerning,
            possibleCauses: ["Strain or sprain", "Something stuck in the paw", "Joint disease"],
            guidance: "Check the paw for thorns or cracked pads and rest your dog. A limp that persists past 24–48 hours deserves an exam."
        ),
        PetSymptom(
            id: "dog.scratching", name: "Scratching or licking a lot", urgency: .mild,
            possibleCauses: ["Fleas or mites", "Allergies", "Dry skin"],
            guidance: "Part the fur and look for flea dirt or redness. Persistent scratching or hot spots are worth a vet conversation."
        ),
        PetSymptom(
            id: "dog.coughing", name: "Coughing", urgency: .concerning,
            possibleCauses: ["Kennel cough", "Heart disease", "Airway irritation"],
            guidance: "An occasional cough can be nothing; a honking, frequent, or nighttime cough should be checked, especially in older dogs."
        ),
        PetSymptom(
            id: "dog.thirst", name: "Drinking much more than usual", urgency: .concerning,
            possibleCauses: ["Diabetes", "Kidney issues", "Hormonal disease"],
            guidance: "Track roughly how much water disappears per day for two or three days and share the numbers with your vet."
        ),
        PetSymptom(
            id: "dog.badbreath", name: "Bad breath", urgency: .mild,
            possibleCauses: ["Dental disease", "Something chewed", "Digestive issues"],
            guidance: "Lift the lip and look for red gums or brown tartar. Dental pain is common and very treatable — mention it at the next visit."
        ),
        PetSymptom(
            id: "dog.bloat", name: "Swollen, hard belly with retching", urgency: .urgent,
            possibleCauses: ["Gastric dilatation-volvulus (bloat)"],
            guidance: "This is a life-threatening emergency, most common in deep-chested dogs. Go to a vet or emergency clinic immediately."
        ),
        PetSymptom(
            id: "dog.breathing", name: "Struggling to breathe", urgency: .urgent,
            possibleCauses: ["Airway obstruction", "Heart failure", "Heatstroke"],
            guidance: "Labored breathing at rest is always an emergency. Keep your dog calm and cool and head to a vet now."
        ),
        PetSymptom(
            id: "dog.collapse", name: "Collapse, fainting, or seizure", urgency: .urgent,
            possibleCauses: ["Heart rhythm problems", "Epilepsy", "Poisoning", "Internal bleeding"],
            guidance: "Note the time and what happened, clear the area so your dog can't be hurt, and contact a vet immediately."
        ),
    ]

    // MARK: - Cat

    private static let catSymptoms: [PetSymptom] = [
        PetSymptom(
            id: "cat.lowappetite", name: "Not eating", urgency: .concerning,
            possibleCauses: ["Stress", "Dental pain", "Kidney or liver disease", "Nausea"],
            guidance: "Cats must not fast: more than 24 hours without food risks serious liver trouble. Tempt with strong-smelling food and call your vet if a full day passes."
        ),
        PetSymptom(
            id: "cat.straining", name: "Straining in the litter box, little urine", urgency: .urgent,
            possibleCauses: ["Urinary blockage", "Bladder inflammation", "Crystals or stones"],
            guidance: "In male cats a blocked urethra is fatal within a day or two untreated. Repeated unproductive trips to the box are an emergency — go now."
        ),
        PetSymptom(
            id: "cat.vomiting", name: "Vomiting repeatedly", urgency: .concerning,
            possibleCauses: ["Hairballs", "Dietary indiscretion", "Kidney disease", "Obstruction"],
            guidance: "The occasional hairball is normal. Several vomits in a day, or vomiting plus lethargy or hiding, deserves a prompt vet call."
        ),
        PetSymptom(
            id: "cat.hiding", name: "Hiding more than usual", urgency: .mild,
            possibleCauses: ["Stress or household change", "Pain", "Feeling unwell"],
            guidance: "Hiding is the main way cats show pain. Note when it started, and if it continues beyond a day or pairs with appetite loss, see a vet."
        ),
        PetSymptom(
            id: "cat.overgrooming", name: "Overgrooming or bald patches", urgency: .mild,
            possibleCauses: ["Stress", "Allergies", "Skin parasites", "Pain in the area being licked"],
            guidance: "Look at where the licking focuses — cats often overgroom directly over a sore spot. Persistent patches warrant a check-up."
        ),
        PetSymptom(
            id: "cat.openmouth", name: "Open-mouth or labored breathing", urgency: .urgent,
            possibleCauses: ["Asthma", "Heart disease", "Fluid around the lungs"],
            guidance: "Cats almost never pant. Open-mouth breathing or visible effort at rest is an emergency — keep your cat calm and go to a vet now."
        ),
        PetSymptom(
            id: "cat.hindlegs", name: "Sudden trouble walking or dragging back legs", urgency: .urgent,
            possibleCauses: ["Blood clot (aortic thromboembolism)", "Injury", "Neurological issues"],
            guidance: "Sudden hind-leg weakness, often with crying and cold paws, is an emergency. Handle gently and get to a vet immediately."
        ),
        PetSymptom(
            id: "cat.thirst", name: "Drinking or urinating much more", urgency: .concerning,
            possibleCauses: ["Kidney disease", "Diabetes", "Overactive thyroid"],
            guidance: "Very common and very testable in older cats. Book a routine vet visit and mention roughly how much the water intake changed."
        ),
        PetSymptom(
            id: "cat.weightloss", name: "Losing weight", urgency: .concerning,
            possibleCauses: ["Thyroid disease", "Kidney disease", "Dental pain", "Digestive disease"],
            guidance: "Gradual loss hides under fluff. If the spine or hips feel more prominent than before, schedule a check-up with a weight record."
        ),
        PetSymptom(
            id: "cat.sneezing", name: "Sneezing or runny eyes", urgency: .mild,
            possibleCauses: ["Viral flare-up", "Dust or irritants", "Upper respiratory infection"],
            guidance: "Clear discharge and occasional sneezes usually pass. Colored discharge, squinting, or a cat that stops eating needs a vet."
        ),
        PetSymptom(
            id: "cat.diarrhea", name: "Diarrhea", urgency: .mild,
            possibleCauses: ["Diet change", "Parasites", "Stress"],
            guidance: "Keep water available and simplify food for a day. If it lasts past 48 hours, contains blood, or the cat is young or elderly, call the vet."
        ),
        PetSymptom(
            id: "cat.vocal", name: "Yowling or sudden behavior change", urgency: .mild,
            possibleCauses: ["Stress", "Cognitive changes in older cats", "Pain", "Thyroid disease"],
            guidance: "Write down when it happens — night yowling in an older cat in particular is worth discussing with your vet."
        ),
    ]

    // MARK: - Rabbit

    private static let rabbitSymptoms: [PetSymptom] = [
        PetSymptom(
            id: "rabbit.noteating", name: "Not eating for 8–12 hours", urgency: .urgent,
            possibleCauses: ["GI stasis", "Dental pain", "Stress or pain elsewhere"],
            guidance: "Rabbit digestion must never stop. A rabbit refusing hay and treats for half a day is an emergency — call a rabbit-savvy vet now."
        ),
        PetSymptom(
            id: "rabbit.nodroppings", name: "Few or no droppings", urgency: .urgent,
            possibleCauses: ["GI stasis", "Blockage", "Dehydration"],
            guidance: "Droppings stopping is the clearest stasis signal there is. Treat it with the same urgency as not eating: vet, today."
        ),
        PetSymptom(
            id: "rabbit.smalldroppings", name: "Smaller or misshapen droppings", urgency: .concerning,
            possibleCauses: ["Gut slowing down", "Not enough hay", "Swallowed fur"],
            guidance: "Push hay and leafy greens, encourage movement, and watch closely for a few hours. If droppings shrink further or stop, treat as urgent."
        ),
        PetSymptom(
            id: "rabbit.hunched", name: "Sitting hunched, unwilling to move", urgency: .urgent,
            possibleCauses: ["Abdominal pain", "GI stasis", "Injury"],
            guidance: "A hunched posture with grinding teeth signals real pain. Keep the rabbit warm and quiet and contact a vet immediately."
        ),
        PetSymptom(
            id: "rabbit.headtilt", name: "Head tilt or rolling", urgency: .urgent,
            possibleCauses: ["E. cuniculi infection", "Inner ear infection", "Stroke"],
            guidance: "Frightening to see but often treatable if caught early. Pad the enclosure so the rabbit can't injure itself and see a vet promptly."
        ),
        PetSymptom(
            id: "rabbit.flystrike", name: "Maggots or a soiled rear end", urgency: .urgent,
            possibleCauses: ["Flystrike", "Urine scald", "Soft stool sticking to fur"],
            guidance: "Flystrike progresses within hours in warm weather. Any maggots at all mean an immediate emergency vet visit."
        ),
        PetSymptom(
            id: "rabbit.sneezing", name: "Sneezing or a runny nose", urgency: .concerning,
            possibleCauses: ["'Snuffles' (bacterial infection)", "Dusty hay or bedding", "Dental root problems"],
            guidance: "Check front paws for crusting from face-wiping. Persistent sneezing or any colored discharge needs antibiotics chosen by a vet."
        ),
        PetSymptom(
            id: "rabbit.drooling", name: "Wet chin or drooling", urgency: .concerning,
            possibleCauses: ["Overgrown molar spurs", "Dental abscess", "Mouth injury"],
            guidance: "Dental trouble stops rabbits eating fast. Book a vet check soon and watch hay intake closely in the meantime."
        ),
        PetSymptom(
            id: "rabbit.furloss", name: "Fur loss or flaky skin", urgency: .mild,
            possibleCauses: ["Mites", "Moulting", "Barbering by a companion"],
            guidance: "A 'dandruff' line down the back often means fur mites — easily treated, but with vet-prescribed products only."
        ),
        PetSymptom(
            id: "rabbit.breathing", name: "Fast or labored breathing", urgency: .urgent,
            possibleCauses: ["Heat stress", "Pneumonia", "Heart problems"],
            guidance: "Move the rabbit somewhere cool and calm, and contact a vet immediately. Rabbits decompensate quickly."
        ),
        PetSymptom(
            id: "rabbit.softstool", name: "Sticky soft stool stuck to fur", urgency: .concerning,
            possibleCauses: ["Too many pellets or treats", "Gut flora imbalance", "Obesity preventing cecotrophy"],
            guidance: "Usually a diet issue: increase hay, cut treats. Clean the rear daily (flystrike risk) and consult your vet if it persists a week."
        ),
    ]

    // MARK: - Hamster

    private static let hamsterSymptoms: [PetSymptom] = [
        PetSymptom(
            id: "hamster.wettail", name: "Wet tail (soaked rear end)", urgency: .urgent,
            possibleCauses: ["Proliferative ileitis ('wet tail')", "Severe diarrhea"],
            guidance: "Wet tail can be fatal within 48–72 hours, especially in young Syrians. Keep the hamster warm and hydrated and see a vet today."
        ),
        PetSymptom(
            id: "hamster.inactive", name: "No activity in the evening", urgency: .concerning,
            possibleCauses: ["Illness", "Low temperature (torpor)", "Pain", "Old age"],
            guidance: "Check the room isn't below about 18°C — cold hamsters go torpid. A warm but flat hamster needs a vet check soon."
        ),
        PetSymptom(
            id: "hamster.weightloss", name: "Weight loss", urgency: .concerning,
            possibleCauses: ["Dental problems", "Internal illness", "Tumors"],
            guidance: "Weekly weigh-ins catch this early. Losing more than a few grams week over week merits an exotics vet visit."
        ),
        PetSymptom(
            id: "hamster.breathing", name: "Clicking or labored breathing", urgency: .urgent,
            possibleCauses: ["Respiratory infection", "Pneumonia", "Heart trouble"],
            guidance: "Clicking sounds mean the infection is already advanced. Keep the hamster warm and get veterinary help quickly."
        ),
        PetSymptom(
            id: "hamster.lump", name: "A new lump or swelling", urgency: .concerning,
            possibleCauses: ["Abscess", "Tumor", "Full cheek pouch that never empties"],
            guidance: "Note the size (compare to a seed or pea) and whether it grows. A pouch that stays full may be impacted — have a vet look."
        ),
        PetSymptom(
            id: "hamster.furloss", name: "Fur loss or flaky skin", urgency: .mild,
            possibleCauses: ["Mites", "Normal aging", "Bedding allergy"],
            guidance: "Some thinning is normal in older hamsters. Intense scratching or scabs point to mites — treatable with vet-prescribed drops."
        ),
        PetSymptom(
            id: "hamster.teeth", name: "Overgrown teeth or trouble eating", urgency: .concerning,
            possibleCauses: ["Misaligned incisors", "Not enough gnawing material"],
            guidance: "Offer safe wooden chews. If food is dropped mid-bite or the teeth look long or crooked, a vet can trim them safely."
        ),
        PetSymptom(
            id: "hamster.eye", name: "Sticky, closed, or bulging eye", urgency: .concerning,
            possibleCauses: ["Eye infection", "Injury from bedding", "Abscess behind the eye"],
            guidance: "Don't bathe the eye with anything but plain lukewarm water, and book a vet promptly — hamster eyes deteriorate fast."
        ),
        PetSymptom(
            id: "hamster.diarrhea", name: "Diarrhea (tail area dry)", urgency: .concerning,
            possibleCauses: ["Too much fresh food", "Sudden diet change", "Stress"],
            guidance: "Withdraw fresh food and offer plain dry mix and water. If it continues beyond a day or the rear becomes wet, treat as urgent."
        ),
        PetSymptom(
            id: "hamster.circling", name: "Falling over, rolling, or circling", urgency: .urgent,
            possibleCauses: ["Inner ear infection", "Stroke", "Head injury"],
            guidance: "Remove climbing hazards immediately so falls can't cause injury, and contact a vet the same day."
        ),
    ]

    // MARK: - Parrot

    private static let parrotSymptoms: [PetSymptom] = [
        PetSymptom(
            id: "parrot.fluffed", name: "Fluffed up and sleepy in the daytime", urgency: .urgent,
            possibleCauses: ["Generalized illness", "Infection", "Being too cold"],
            guidance: "Birds hide illness until they can't. A parrot fluffed and dozing through the day is already quite sick — see an avian vet promptly."
        ),
        PetSymptom(
            id: "parrot.tailbob", name: "Tail bobbing while breathing", urgency: .urgent,
            possibleCauses: ["Respiratory distress", "Air sac infection", "Aspergillosis"],
            guidance: "A rhythmic tail bob with each breath means real effort to breathe. Keep the bird calm and warm and go to an avian vet now."
        ),
        PetSymptom(
            id: "parrot.droppings", name: "Changed droppings", urgency: .concerning,
            possibleCauses: ["Diet change", "Liver or kidney issues", "Infection"],
            guidance: "Judge against what's normal for your bird. Changes that persist beyond a day — especially color changes — need a vet's eye."
        ),
        PetSymptom(
            id: "parrot.noteating", name: "Not eating", urgency: .urgent,
            possibleCauses: ["Illness", "Crop problems", "Stress"],
            guidance: "Small birds burn energy fast and can't skip meals safely. A day without eating is an emergency for most parrots."
        ),
        PetSymptom(
            id: "parrot.plucking", name: "Feather plucking", urgency: .concerning,
            possibleCauses: ["Boredom or stress", "Skin infection", "Hormonal triggers", "Pain"],
            guidance: "Rule out medical causes first with an avian vet, then work on enrichment, foraging, and sleep routine."
        ),
        PetSymptom(
            id: "parrot.sneezing", name: "Sneezing or nasal discharge", urgency: .concerning,
            possibleCauses: ["Upper respiratory infection", "Vitamin A deficiency", "Dusty environment"],
            guidance: "An occasional dry sneeze is normal. Wet sneezes, stained feathers above the nares, or swelling need a vet visit."
        ),
        PetSymptom(
            id: "parrot.floor", name: "On the cage floor, unable to perch", urgency: .urgent,
            possibleCauses: ["Severe weakness", "Injury", "Egg binding in hens"],
            guidance: "A bird that can't or won't perch is critically unwell. Provide warmth, remove high perches, and get to an avian vet immediately."
        ),
        PetSymptom(
            id: "parrot.wing", name: "Drooping wing", urgency: .concerning,
            possibleCauses: ["Injury or fracture", "Nerve problems", "Fatigue from illness"],
            guidance: "Don't try to extend the wing yourself. Limit climbing and flying and have a vet examine it soon."
        ),
        PetSymptom(
            id: "parrot.voice", name: "Voice change or unusually silent", urgency: .concerning,
            possibleCauses: ["Air sac or syrinx issues", "Respiratory infection"],
            guidance: "A hoarse, squeaky, or absent voice often points at the airways. Book an avian vet visit rather than waiting it out."
        ),
        PetSymptom(
            id: "parrot.regurgitating", name: "Regurgitating repeatedly", urgency: .concerning,
            possibleCauses: ["Courtship behavior", "Crop infection", "Blockage"],
            guidance: "Directed at a favorite person or toy, it's usually hormonal. Undirected, frequent, or with fluff and lethargy — see a vet."
        ),
        PetSymptom(
            id: "parrot.blood", name: "Blood on feathers or a bleeding blood feather", urgency: .urgent,
            possibleCauses: ["Broken blood feather", "Wound", "Night fright injury"],
            guidance: "Birds have little blood to spare. Apply gentle pressure with clean gauze and contact an avian vet immediately."
        ),
    ]
}
