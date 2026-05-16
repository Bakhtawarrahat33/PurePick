"""
PurePick Ingredient Intelligence Layer — Stage 3.5
Scientific Name Resolver + Allergy Scoring Engine
"""

# ── PART 1 — SCIENTIFIC NAME MASTER MAP ──────────────────────────────
INGREDIENT_MASTER_MAP = {
    # VITAMINS
    "vitamin c": [
        "ascorbic acid", "l-ascorbic acid", "ascorbyl glucoside",
        "sodium ascorbyl phosphate", "magnesium ascorbyl phosphate",
        "ascorbyl palmitate", "ascorbyl tetraisopalmitate",
        "3-o-ethyl ascorbic acid", "ethyl ascorbic acid",
        "ascorbate", "ascorbyl", "ascorbic acid 2-glucoside"
    ],
    "vitamin e": [
        "tocopherol", "alpha-tocopherol", "tocopheryl acetate",
        "tocopheryl linoleate", "tocopheryl nicotinate",
        "dl-alpha tocopherol", "mixed tocopherols", "tocophersolan"
    ],
    "vitamin a": [
        "retinol", "retinyl palmitate", "retinyl acetate",
        "retinaldehyde", "retinal", "retinoic acid", "tretinoin",
        "adapalene", "hydroxypinacolone retinoate",
        "granactive retinoid", "bakuchiol"
    ],
    "vitamin b3": ["niacinamide", "nicotinamide", "niacin", "nicotinic acid", "vitamin pp"],
    "vitamin b5": ["panthenol", "d-panthenol", "dl-panthenol", "pantothenic acid", "dexpanthenol"],
    "vitamin k": ["phylloquinone", "menaquinone", "phytonadione", "vitamin k1", "vitamin k2"],

    # ACIDS & EXFOLIANTS
    "salicylic acid": [
        "bha", "beta hydroxy acid", "beta-hydroxy acid",
        "2-hydroxybenzoic acid", "willow bark extract",
        "salix alba", "salicylate"
    ],
    "glycolic acid": ["aha", "alpha hydroxy acid", "alpha-hydroxy acid", "hydroacetic acid", "2-hydroxyacetic acid"],
    "lactic acid": ["2-hydroxypropanoic acid", "lactate", "sodium lactate", "ammonium lactate"],
    "hyaluronic acid": [
        "sodium hyaluronate", "ha", "hyaluronan",
        "hydrolyzed hyaluronic acid", "hyaluronic acid crosspolymer",
        "sodium hyaluronate crosspolymer", "potassium hyaluronate"
    ],
    "kojic acid": ["5-hydroxy-2-(hydroxymethyl)-4h-pyran-4-one", "kojic acid dipalmitate"],
    "azelaic acid": ["nonanedioic acid", "1,7-heptanedicarboxylic acid"],
    "ferulic acid": ["4-hydroxy-3-methoxycinnamic acid", "trans-ferulic acid"],
    "citric acid": ["2-hydroxypropane-1,2,3-tricarboxylic acid", "citrate", "sodium citrate", "trisodium citrate"],

    # PRESERVATIVES
    "paraben": [
        "methylparaben", "ethylparaben", "propylparaben",
        "butylparaben", "isobutylparaben", "isopropylparaben",
        "benzylparaben", "methyl 4-hydroxybenzoate",
        "ethyl 4-hydroxybenzoate", "propyl 4-hydroxybenzoate"
    ],
    "formaldehyde": [
        "quaternium-15", "dmdm hydantoin", "imidazolidinyl urea",
        "diazolidinyl urea", "bronopol", "2-bromo-2-nitropropane-1,3-diol",
        "5-bromo-5-nitro-1,3-dioxane", "sodium hydroxymethylglycinate", "methenamine"
    ],
    "methylisothiazolinone": ["mi", "mit", "methylchloroisothiazolinone", "mci", "kathon cg", "neolone", "isothiazolinone"],
    "phenoxyethanol": ["2-phenoxyethanol", "ethylene glycol monophenyl ether", "phenoxetol", "rose ether"],

    # SURFACTANTS
    "sodium lauryl sulfate": ["sls", "sodium dodecyl sulfate", "sds", "lauryl sodium sulfate"],
    "sodium laureth sulfate": ["sles", "sodium lauryl ether sulfate", "sodium lauryl ether sulphate"],

    # FRAGRANCES
    "fragrance": [
        "parfum", "aroma", "linalool", "limonene", "citronellol", "geraniol", "eugenol", "cinnamal",
        "cinnamyl alcohol", "benzyl alcohol", "benzyl salicylate", "benzyl benzoate", "amyl cinnamal", "coumarin",
        "farnesol", "hexyl cinnamal", "hydroxycitronellal", "isoeugenol", "lilial", "alpha-isomethyl ionone",
        "evernia prunastri", "evernia furfuracea"
    ],

    # OILS & EMOLLIENTS
    "peanut oil": ["arachis oil", "arachis hypogaea seed oil", "groundnut oil", "arachidic oil"],
    "coconut oil": ["cocos nucifera oil", "cocos nucifera", "fractionated coconut oil", "caprylic/capric triglyceride"],
    "almond oil": ["prunus amygdalus dulcis oil", "sweet almond oil", "prunus dulcis", "amygdalus communis"],
    "argan oil": ["argania spinosa kernel oil", "moroccan oil"],
    "shea butter": ["butyrospermum parkii butter", "vitellaria paradoxa", "karite butter", "shea oil"],
    "lanolin": ["wool wax", "wool fat", "adeps lanae", "lanolin alcohol", "acetylated lanolin", "hydroxylated lanolin", "lanolin cera"],

    # SILICONES
    "silicone": [
        "dimethicone", "cyclomethicone", "cyclopentasiloxane", "cyclohexasiloxane",
        "phenyl trimethicone", "amomodimethicone", "siloxane", "methicone", "dimethiconol"
    ],

    # ALCOHOLS
    "alcohol": ["ethanol", "denatured alcohol", "alcohol denat", "sd alcohol", "isopropyl alcohol", "isopropanol", "ethyl alcohol", "benzyl alcohol"],
    "fatty alcohol": ["cetyl alcohol", "stearyl alcohol", "cetearyl alcohol", "behenyl alcohol", "myristyl alcohol", "lauryl alcohol"],

    # SUNSCREEN ACTIVES
    "oxybenzone": ["benzophenone-3", "2-hydroxy-4-methoxybenzophenone"],
    "avobenzone": ["butyl methoxydibenzoylmethane", "parsol 1789"],
    "octinoxate": ["ethylhexyl methoxycinnamate", "octyl methoxycinnamate"],
    "zinc oxide": ["zno", "zinc white", "ci 77947"],
    "titanium dioxide": ["tio2", "titanium white", "ci 77891"],

    # COLORANTS
    "carmine": ["cochineal", "carminic acid", "crimson lake", "natural red 4", "ci 75470", "e120"],
}

# ── PART 2 — RESOLVER FUNCTION ─────────────────────────────────────
def resolve_ingredient(raw_ingredient: str) -> dict:
    raw_lower = raw_ingredient.lower().strip()
    for common_name, aliases in INGREDIENT_MASTER_MAP.items():
        if raw_lower == common_name:
            return {"raw": raw_ingredient, "common_name": common_name.title(), "all_aliases": aliases, "match_method": "common_name_exact", "resolved": True}
        if raw_lower in common_name or common_name in raw_lower:
            return {"raw": raw_ingredient, "common_name": common_name.title(), "all_aliases": aliases, "match_method": "common_name_partial", "resolved": True}
        for alias in aliases:
            if raw_lower == alias or raw_lower in alias or alias in raw_lower:
                return {"raw": raw_ingredient, "common_name": common_name.title(), "all_aliases": aliases, "match_method": "alias_match", "matched_alias": alias, "resolved": True}
    return {"raw": raw_ingredient, "common_name": raw_ingredient, "all_aliases": [], "match_method": "unresolved", "resolved": False}

# ── PART 3 — ALLERGY MATCH LOGIC ───────────────────────────────────
PRESET_ALLERGY_MAP = {
    "Nut Allergy": ["peanut oil", "arachis oil", "almond oil", "prunus amygdalus dulcis oil", "walnut", "hazelnut", "tree nut"],
    "Fragrance": ["fragrance", "parfum", "linalool", "limonene", "citronellol", "geraniol", "eugenol", "coumarin", "farnesol"],
    "Parabens": ["methylparaben", "ethylparaben", "propylparaben", "butylparaben", "isobutylparaben"],
    "Sulphates": ["sodium lauryl sulfate", "sls", "sodium laureth sulfate", "sles"],
    "Alcohol": ["ethanol", "denatured alcohol", "alcohol denat", "isopropyl alcohol", "sd alcohol"],
    "Silicone": ["dimethicone", "cyclomethicone", "cyclopentasiloxane", "siloxane"],
    "Lanolin": ["lanolin", "wool wax", "wool fat", "adeps lanae"],
    "Formaldehyde": ["quaternium-15", "dmdm hydantoin", "imidazolidinyl urea", "bronopol", "sodium hydroxymethylglycinate"],
    "Oxybenzone": ["oxybenzone", "benzophenone-3"],
    "Carmine": ["carmine", "cochineal", "ci 75470", "e120"],
}

SKIN_CONDITION_MAP = {
    "Psoriasis": ["sodium lauryl sulfate", "sls", "alcohol denat", "parfum", "fragrance", "retinol", "salicylic acid"],
    "Eczema": ["formaldehyde", "quaternium-15", "methylisothiazolinone", "propylene glycol", "lanolin", "wool wax", "fragrance", "neomycin"],
    "Rosacea": ["ethanol", "alcohol", "witch hazel", "hamamelis virginiana", "menthol", "peppermint oil", "camphor", "sodium lauryl sulfate", "fragrance"],
    "Acne": ["coconut oil", "cocos nucifera", "isopropyl myristate", "isopropyl palmitate", "sodium chloride", "acetylated lanolin"],
}

SEVERITY_RULES = {
    "CRITICAL": ["Nut Allergy", "Formaldehyde", "Oxybenzone", "Carmine"],
    "MODERATE": ["Fragrance", "Sulphates", "Parabens", "Alcohol", "Lanolin", "Psoriasis", "Eczema", "Rosacea", "Methylisothiazolinone"],
    "LOW": ["Silicone", "Acne"],
}

SCORE_TABLE = {
    ("CRITICAL", "Strong"): ("R10", 2.0, 30, True),
    ("CRITICAL", "Mild"):   ("R8",  1.6, 20, True),
    ("MODERATE", "Strong"): ("R8",  1.6, 20, True),
    ("MODERATE", "Mild"):   ("R7",  1.3, 15, True),
    ("LOW",      "Strong"): ("R5",  1.0, 10, False),
    ("LOW",      "Mild"):   ("R4",  0.8,  8, False),
    ("SAFE",     "None"):   ("R1",  0.0,  0, False),
}

def _score_rule(severity: str, match_strength: str) -> dict:
    key = (severity, match_strength)
    rule, weight, pts, trig = SCORE_TABLE.get(key, ("R1", 0.0, 0, False))
    return {"rule": rule, "contribution_weight": weight, "risk_points": pts, "band_trigger": trig}

def match_ingredient_to_profile(resolved: dict, user_profile: dict) -> dict:
    raw_lower = resolved["raw"].lower(); common_lower = resolved["common_name"].lower()
    alias_list = [a.lower() for a in resolved.get("all_aliases", [])]
    all_forms = list(set([raw_lower, common_lower] + alias_list))

    def overlaps(trigger: str) -> bool:
        t = trigger.lower()
        return any(t in form or form in t for form in all_forms)

    # Check 1: Preset Allergies
    for allergy in user_profile.get("allergies", []):
        for trigger in PRESET_ALLERGY_MAP.get(allergy, []):
            if overlaps(trigger):
                severity = "MODERATE"
                for level, items in SEVERITY_RULES.items():
                    if allergy in items: severity = level; break
                return {"flagged": True, "match_source": "preset_allergy", "matched_concern": allergy, "severity": severity, "matched_via": trigger, "display_name": resolved["common_name"],
                        "explanation": f"'{resolved['raw']}' (also known as '{resolved['common_name']}') was detected. Your profile includes '{allergy}'.", "score_rule": _score_rule(severity, "Strong")}

    # Check 2: Skin Conditions
    for condition in user_profile.get("skin_conditions", []):
        for trigger in SKIN_CONDITION_MAP.get(condition, []):
            if overlaps(trigger):
                severity = "MODERATE"
                for level, items in SEVERITY_RULES.items():
                    if condition in items: severity = level; break
                return {"flagged": True, "match_source": "skin_condition", "matched_concern": condition, "severity": severity, "matched_via": trigger, "display_name": resolved["common_name"],
                        "explanation": f"'{resolved['raw']}' (also known as '{resolved['common_name']}') was detected. Your profile includes '{condition}'.", "score_rule": _score_rule(severity, "Mild")}

    # Check 3: Custom Allergens
    for custom in user_profile.get("custom_allergens", []):
        custom_lower = custom.lower()
        if any(custom_lower in form or form in custom_lower for form in all_forms):
            return {"flagged": True, "match_source": "custom_allergen_direct", "matched_concern": f"Custom: {custom}", "severity": "MODERATE", "matched_via": custom, "display_name": resolved["common_name"],
                    "explanation": f"'{resolved['raw']}' matches your custom allergen '{custom}'.", "score_rule": _score_rule("MODERATE", "Strong")}
        custom_resolved = resolve_ingredient(custom)
        if custom_resolved["resolved"] and custom_resolved["common_name"].lower() == common_lower:
             return {"flagged": True, "match_source": "custom_allergen_alias", "matched_concern": f"Custom: {custom}", "severity": "MODERATE", "matched_via": custom_resolved["common_name"], "display_name": resolved["common_name"],
                    "explanation": f"'{resolved['raw']}' matches your custom allergen '{custom}' (both are '{resolved['common_name']}').", "score_rule": _score_rule("MODERATE", "Strong")}

    return {"flagged": False, "match_source": "none", "matched_concern": None, "severity": None, "display_name": resolved["common_name"], "explanation": None, "score_rule": None}

def run_ingredient_intelligence(ingredients: list, user_profile: dict) -> dict:
    results = []; flagged_items = []; safe_items = []; total_score = 0; triggered = False
    
    for raw in ingredients:
        resolved = resolve_ingredient(raw)
        match = match_ingredient_to_profile(resolved, user_profile)
        score_info = match.get("score_rule") or _score_rule("SAFE", "None")
        total_score += score_info["risk_points"]
        if score_info["band_trigger"]: triggered = True
        
        entry = {
            "raw_ingredient": raw, "common_name": resolved["common_name"], "resolved": resolved["resolved"], "flagged": match["flagged"],
            "matched_concern": match.get("matched_concern"), "severity": match.get("severity"), "explanation": match.get("explanation"),
            "risk_points": score_info["risk_points"], "rule": score_info["rule"]
        }
        results.append(entry)
        if match["flagged"]: flagged_items.append(entry)
        else: safe_items.append(raw)

    risk_band = "High Risk" if (total_score >= 51 or triggered) else "Moderate" if total_score >= 21 else "Safe"
    return {
        "all_ingredients": results, "flagged_ingredients": flagged_items, "safe_ingredients": safe_items,
        "total_risk_score": total_score, "risk_band": risk_band, "total_flagged": len(flagged_items)
    }
