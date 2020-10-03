
/datum/species/carp
	name = "Carp Mutants"
	id = "carp"
	limbs_id = "carp"
	say_mod = "gnashes"
	sexes = 1
	meat = /obj/item/food/carpmeat
	species_traits = list(NOEYESPRITES, NO_UNDERWEAR)
	inherent_traits = list(TRAIT_CHUNKYFINGERS, TRAIT_RESISTCOLD, TRAIT_NOBREATH, TRAIT_RESISTLOWPRESSURE, TRAIT_PRIMITIVE) //Spess is their religion. Also, no mechs or guns
	inherent_factions = list("carp")
	disliked_food = GROSS | GRAIN
	toxic_food = FRUIT
	liked_food = MEAT | RAW
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT
	payday_modifier = 0.75
	attack_verb = "bite"
	attack_sound = 'sound/weapons/bite.ogg'

/datum/species/carp/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	if(chem.type == /datum/reagent/toxin/carpotoxin)
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
		return
	. = ..()

/datum/species/carp/space_move(mob/living/carbon/human/H)
	. = ..()
	if(H.loc)
		var/datum/gas_mixture/current = H.loc.return_air()
		if((current && (current.return_pressure() <= ONE_ATMOSPHERE * 0.25)) || isspaceturf(H.loc)) //as long as there's reasonable pressure and no gravity, flight is possible
			return TRUE
