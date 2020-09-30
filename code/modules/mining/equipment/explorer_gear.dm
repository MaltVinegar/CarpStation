/****************Explorer's Suit and Mask****************/
/obj/item/clothing/suit/hooded/explorer
	name = "explorer suit"
	desc = "An armoured suit for exploring harsh environments."
	icon_state = "explorer"
	inhand_icon_state = "explorer"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	cold_protection = CHEST|GROIN|LEGS|ARMS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|ARMS
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	hoodtype = /obj/item/clothing/head/hooded/explorer
	armor = list(MELEE = 30, BULLET = 10, LASER = 10, ENERGY = 20, BOMB = 50, BIO = 100, RAD = 50, FIRE = 50, ACID = 50)
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe)
	resistance_flags = FIRE_PROOF

/obj/item/clothing/head/hooded/explorer
	name = "explorer hood"
	desc = "An armoured hood for exploring harsh environments."
	icon_state = "explorer"
	body_parts_covered = HEAD
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	armor = list(MELEE = 30, BULLET = 10, LASER = 10, ENERGY = 20, BOMB = 50, BIO = 100, RAD = 50, FIRE = 50, ACID = 50, WOUND = 10)
	resistance_flags = FIRE_PROOF

/obj/item/clothing/suit/hooded/explorer/Initialize()
	. = ..()
	AddComponent(/datum/component/armor_plate)

/obj/item/clothing/head/hooded/explorer/Initialize()
	. = ..()
	AddComponent(/datum/component/armor_plate)

/obj/item/clothing/mask/gas/explorer
	name = "explorer gas mask"
	desc = "A military-grade gas mask that can be connected to an air supply."
	icon_state = "gas_mining"
	visor_flags = BLOCK_GAS_SMOKE_EFFECT | MASKINTERNALS
	visor_flags_inv = HIDEFACIALHAIR
	visor_flags_cover = MASKCOVERSMOUTH
	actions_types = list(/datum/action/item_action/adjust)
	armor = list(MELEE = 10, BULLET = 5, LASER = 5, ENERGY = 5, BOMB = 0, BIO = 50, RAD = 0, FIRE = 20, ACID = 40, WOUND = 5)
	resistance_flags = FIRE_PROOF

/obj/item/clothing/mask/gas/explorer/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/gas/explorer/adjustmask(user)
	..()
	w_class = mask_adjusted ? WEIGHT_CLASS_NORMAL : WEIGHT_CLASS_SMALL

/obj/item/clothing/mask/gas/explorer/folded/Initialize()
	. = ..()
	adjustmask()

/obj/item/clothing/suit/space/hostile_environment
	name = "H.E.C.K. suit"
	desc = "Hostile Environment Cross-Kinetic Suit: A suit designed to withstand the wide variety of hazards from Lavaland. It wasn't enough for its last owner."
	icon_state = "hostile_env"
	inhand_icon_state = "hostile_env"
	clothing_flags = THICKMATERIAL //not spaceproof
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	slowdown = 0
	armor = list(MELEE = 70, BULLET = 40, LASER = 10, ENERGY = 20, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe)

/obj/item/clothing/suit/space/hostile_environment/process(delta_time)
	. = ..()
	var/mob/living/carbon/C = loc
	if(istype(C) && DT_PROB(1, delta_time)) //cursed by bubblegum
		if(DT_PROB(7.5, delta_time))
			new /datum/hallucination/oh_yeah(C)
			to_chat(C, "<span class='colossus'><b>[pick("I AM IMMORTAL.","I SHALL TAKE BACK WHAT'S MINE.","I SEE YOU.","YOU CANNOT ESCAPE ME FOREVER.","DEATH CANNOT HOLD ME.")]</b></span>")
		else
			to_chat(C, "<span class='warning'>[pick("You hear faint whispers.","You smell ash.","You feel hot.","You hear a roar in the distance.")]</span>")

/obj/item/clothing/head/helmet/space/hostile_environment
	name = "H.E.C.K. helmet"
	desc = "Hostile Environiment Cross-Kinetic Helmet: A helmet designed to withstand the wide variety of hazards from Lavaland. It wasn't enough for its last owner."
	icon_state = "hostile_env"
	inhand_icon_state = "hostile_env"
	w_class = WEIGHT_CLASS_NORMAL
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	clothing_flags = THICKMATERIAL // no space protection
	armor = list(MELEE = 70, BULLET = 40, LASER = 10, ENERGY = 20, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | LAVA_PROOF

/obj/item/clothing/head/helmet/space/hostile_environment/Initialize()
	. = ..()
	update_icon()

/obj/item/clothing/head/helmet/space/hostile_environment/update_overlays()
	. = ..()
	var/mutable_appearance/glass_overlay = mutable_appearance(icon, "hostile_env_glass")
	glass_overlay.appearance_flags = RESET_COLOR
	. += glass_overlay

/obj/item/clothing/head/helmet/space/hostile_environment/worn_overlays(isinhands)
	. = ..()
	if(!isinhands)
		var/mutable_appearance/M = mutable_appearance('icons/mob/clothing/head.dmi', "hostile_env_glass")
		M.appearance_flags = RESET_COLOR
		. += M

/****************SEVA Suit and Mask****************/
/obj/item/clothing/suit/hooded/explorer/seva
	name = "SEVA Suit"
	desc = "A fire-proof suit for exploring hot environments. Its design and material make it easier for a Goliath to keep their grip on the wearer."
	icon_state = "seva"
	w_class = WEIGHT_CLASS_BULKY
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	hoodtype = /obj/item/clothing/head/hooded/explorer/seva
	armor = list("melee" = 5, "bullet" = 5, "laser" = 5, "energy" = 5, "bomb" = 15, "bio" = 50, "rad" = 25, "fire" = 100, "acid" = 25)
	resistance_flags = FIRE_PROOF | GOLIATH_WEAKNESS

/obj/item/clothing/head/hooded/explorer/seva
	name = "SEVA Hood"
	desc = "A fire-proof hood for exploring hot environments. Its design and material make it easier for a Goliath to keep their grip on the wearer."
	icon_state = "seva"
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	armor = list("melee" = 5, "bullet" = 5, "laser" = 5, "energy" = 5, "bomb" = 15, "bio" = 50, "rad" = 25, "fire" = 100, "acid" = 25)
	resistance_flags = FIRE_PROOF | GOLIATH_WEAKNESS

/obj/item/clothing/mask/gas/seva
	name = "SEVA Mask"
	desc = "A face-covering plate that can be connected to an air supply. Intended for use with the SEVA Suit."
	icon_state = "seva"
	resistance_flags = FIRE_PROOF

/****************Exo-Suit and Mask****************/

/obj/item/clothing/suit/hooded/explorer/exo
	name = "Exo-suit"
	desc = "A robust suit for fighting dangerous animals. Its design and material make it harder for a Goliath to keep their grip on the wearer."
	icon_state = "exo"
	w_class = WEIGHT_CLASS_BULKY
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	hoodtype = /obj/item/clothing/head/hooded/explorer/exo
	armor = list("melee" = 55, "bullet" = 5, "laser" = 5, "energy" = 5, "bomb" = 40, "bio" = 25, "rad" = 10, "fire" = 0, "acid" = 0)
	resistance_flags = FIRE_PROOF | GOLIATH_RESISTANCE
	slowdown = 1

/obj/item/clothing/head/hooded/explorer/exo
	name = "Exo-hood"
	desc = "A robust helmet for fighting dangerous animals. Its design and material make it harder for a Goliath to keep their grip on the wearer."
	icon_state = "exo"
	armor = list("melee" = 55, "bullet" = 5, "laser" = 5, "energy" = 5, "bomb" = 40, "bio" = 25, "rad" = 10, "fire" = 0, "acid" = 0)
	resistance_flags = FIRE_PROOF | GOLIATH_RESISTANCE

/obj/item/clothing/mask/gas/exo
	name = "Exosuit Mask"
	desc = "A face-covering mask that can be connected to an air supply. Intended for use with the Exosuit."
	icon_state = "exo"
	resistance_flags = FIRE_PROOF

/obj/item/clothing/suit/space/heavy_miner
	name = "H.M.S. suit"
	desc = "Heavy Mining Space Suit is a very armored suit intended for mining and space exploration."
	icon_state = "mining_heavy"
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF | GOLIATH_RESISTANCE
	slowdown = 1.5
	armor = list("melee" = 70, "bullet" = 40, "laser" = 30, "energy" = 30, "bomb" = 50, "bio" = 100, "rad" = 75, "fire" = 100, "acid" = 100)
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/mining_scanner, /obj/item/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe)

/obj/item/clothing/suit/space/heavy_miner/process()
	var/mob/living/carbon/C = loc
	if(istype(C) && prob(2)) //cursed by bubblegum
		if(prob(15))
			new /datum/hallucination/oh_yeah(C)
			to_chat(C, "<span class='colossus'><b>[pick("I AM IMMORTAL.","I SHALL TAKE BACK WHAT'S MINE.","I SEE YOU.","YOU CANNOT ESCAPE ME FOREVER.","DEATH CANNOT HOLD ME.")]</b></span>")
		else
			to_chat(C, "<span class='warning'>[pick("You hear faint whispers.","You smell ash.","You feel hot.","You hear a roar in the distance.")]</span>")

/obj/item/clothing/head/helmet/space/heavy_miner
	name = "H.M.S. helmet"
	desc = "Heavy Mining Space Helmet is a pretty heavy suit reinforced with plasteel sheets."
	icon_state = "mining_heavy"
	w_class = WEIGHT_CLASS_NORMAL
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	armor = list("melee" = 70, "bullet" = 40, "laser" = 30, "energy" = 30, "bomb" = 50, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 100)
	resistance_flags = FIRE_PROOF | LAVA_PROOF
