GLOBAL_LIST_INIT(possible_changeling_IDs, list("Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa","Lambda","Mu","Nu","Xi","Omicron","Pi","Rho","Sigma","Tau","Upsilon","Phi","Chi","Psi","Omega"))
GLOBAL_LIST_INIT(slots, list("head", "wear_mask", "back", "wear_suit", "w_uniform", "shoes", "belt", "gloves", "glasses", "ears", "wear_id", "s_store"))
GLOBAL_LIST_INIT(slot2slot, list("head" = ITEM_SLOT_HEAD, "wear_mask" = ITEM_SLOT_MASK, "neck" = ITEM_SLOT_NECK, "back" = ITEM_SLOT_BACK, "wear_suit" = ITEM_SLOT_OCLOTHING, "w_uniform" = ITEM_SLOT_ICLOTHING, "shoes" = ITEM_SLOT_FEET, "belt" = ITEM_SLOT_BELT, "gloves" = ITEM_SLOT_GLOVES, "glasses" = ITEM_SLOT_EYES, "ears" = ITEM_SLOT_EARS, "wear_id" = ITEM_SLOT_ID, "s_store" = ITEM_SLOT_SUITSTORE))
GLOBAL_LIST_INIT(slot2type, list("head" = /obj/item/clothing/head/changeling, "wear_mask" = /obj/item/clothing/mask/changeling, "back" = /obj/item/changeling, "wear_suit" = /obj/item/clothing/suit/changeling, "w_uniform" = /obj/item/clothing/under/changeling, "shoes" = /obj/item/clothing/shoes/changeling, "belt" = /obj/item/changeling, "gloves" = /obj/item/clothing/gloves/changeling, "glasses" = /obj/item/clothing/glasses/changeling, "ears" = /obj/item/changeling, "wear_id" = /obj/item/changeling, "s_store" = /obj/item/changeling))
GLOBAL_VAR(changeling_team_objective_type) //If this is not null, we hand our this objective to all lings


/datum/game_mode/changeling
	name = "changeling"
	config_tag = "changeling"
	report_type = "changeling"
	antag_flag = ROLE_CHANGELING
	false_report_weight = 10
	restricted_jobs = list("AI", "Cyborg")
	protected_jobs = list("Prisoner", "Security Officer", "Warden", "Detective", "Head of Security", "Captain")
	required_players = 5
	required_enemies = 1
	recommended_enemies = 4
	reroll_friendly = 1

	announce_span = "green"
	announce_text = "Alien changelings have infiltrated the crew!\n\
	<span class='green'>Changelings</span>: Accomplish the objectives assigned to you.\n\
	<span class='notice'>Crew</span>: Root out and eliminate the changeling menace."

	var/const/changeling_amount = 4 //hard limit on changelings if scaling is turned off
	var/list/changelings = list()

/datum/game_mode/changeling/pre_setup()

	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += "Assistant"

	var/num_changelings = 1

	var/csc = CONFIG_GET(number/changeling_scaling_coeff)
	if(csc)
		num_changelings = max(1, min(round(num_players() / (csc * 2)) + 2, round(num_players() / csc)))
	else
		num_changelings = max(1, min(num_players(), changeling_amount))

	if(antag_candidates.len>0)
		for(var/i = 0, i < num_changelings, i++)
			if(!antag_candidates.len)
				break
			var/datum/mind/changeling = antag_pick(antag_candidates)
			antag_candidates -= changeling
			changelings += changeling
			changeling.special_role = ROLE_CHANGELING
			changeling.restricted_roles = restricted_jobs
			GLOB.pre_setup_antags += changeling
		return TRUE
	else
		setup_error = "Not enough changeling candidates"
		return FALSE

/datum/game_mode/changeling/post_setup()
	//Decide if it's ok for the lings to have a team objective
	//And then set it up to be handed out in forge_changeling_objectives
	var/list/team_objectives = subtypesof(/datum/objective/changeling_team_objective)
	var/list/possible_team_objectives = list()
	for(var/T in team_objectives)
		var/datum/objective/changeling_team_objective/CTO = T

		if(changelings.len >= initial(CTO.min_lings))
			possible_team_objectives += T

	if(possible_team_objectives.len && prob(20*changelings.len))
		GLOB.changeling_team_objective_type = pick(possible_team_objectives)

	for(var/datum/mind/changeling in changelings)
		log_game("[key_name(changeling)] has been selected as a changeling")
		var/datum/antagonist/changeling/new_antag = new()
		new_antag.team_mode = TRUE
		changeling.add_antag_datum(new_antag)
		GLOB.pre_setup_antags -= changeling
	..()

/datum/game_mode/changeling/make_antag_chance(mob/living/carbon/human/character) //Assigns changeling to latejoiners
	var/csc = CONFIG_GET(number/changeling_scaling_coeff)
	var/changelingcap = min(round(GLOB.joined_player_list.len / (csc * 2)) + 2, round(GLOB.joined_player_list.len / csc))
	if(changelings.len >= changelingcap) //Caps number of latejoin antagonists
		return
	if(changelings.len <= (changelingcap - 2) || prob(100 - (csc * 2)))
		if(ROLE_CHANGELING in character.client.prefs.be_special)
			if(!is_banned_from(character.ckey, list(ROLE_CHANGELING, ROLE_SYNDICATE)) && !QDELETED(character))
				if(age_check(character.client))
					if(!(character.job in restricted_jobs))
						character.mind.make_Changeling()
						changelings += character.mind

/datum/game_mode/changeling/generate_report()
	return "The Gorlex Marauders have announced the successful raid and destruction of Central Command containment ship #S-[rand(1111, 9999)]. This ship housed only a single prisoner - \
			codenamed \"Thing\", and it was highly adaptive and extremely dangerous. We have reason to believe that the Thing has allied with the Syndicate, and you should note that likelihood \
			of the Thing being sent to a station in this sector is highly likely. It may be in the guise of any crew member. Trust nobody - suspect everybody. Do not announce this to the crew, \
			as paranoia may spread and inhibit workplace efficiency."

/proc/changeling_transform(mob/living/carbon/human/user, datum/changelingprofile/chosen_prof)
	var/datum/dna/chosen_dna = chosen_prof.dna
	user.real_name = chosen_prof.name
	user.underwear = chosen_prof.underwear
	user.undershirt = chosen_prof.undershirt
	user.socks = chosen_prof.socks

	chosen_dna.transfer_identity(user, 1)
	user.updateappearance(mutcolor_update=1)
	user.update_body()
	user.domutcheck()

	// Do skillchip code after DNA code.
	// There's a mutation that increases max chip complexity available, even though we force-implant skillchips.

	// Remove existing skillchips.
	user.destroy_all_skillchips(silent = FALSE)

	// Add new set of skillchips.
	for(var/chip in chosen_prof.skillchips)
		var/chip_type = chip["type"]
		var/obj/item/skillchip/skillchip = new chip_type(user)

		if(!istype(skillchip))
			stack_trace("Failure to implant changeling from [chosen_prof] with skillchip [skillchip]. Tried to implant with non-skillchip type [chip_type]")
			qdel(skillchip)
			continue

		// Try force-implanting and activating. If it doesn't work, there's nothing much we can do. There may be some
		// incompatibility out of our hands
		var/implant_msg = user.implant_skillchip(skillchip, TRUE)
		if(implant_msg)
			// Hopefully recording the error message will help debug it.
			stack_trace("Failure to implant changeling from [chosen_prof] with skillchip [skillchip]. Error msg: [implant_msg]")
			qdel(skillchip)
			continue

		// Time to set the metadata. This includes trying to activate the chip.
		var/set_meta_msg = skillchip.set_metadata(chip)

		if(set_meta_msg)
			// Hopefully recording the error message will help debug it.
			stack_trace("Failure to activate changeling skillchip from [chosen_prof] with skillchip [skillchip] using [chip] metadata. Error msg: [set_meta_msg]")
			continue

	//vars hackery. not pretty, but better than the alternative.
	for(var/slot in GLOB.slots)
		if(istype(user.vars[slot], GLOB.slot2type[slot]) && !(chosen_prof.exists_list[slot])) //remove unnecessary flesh items
			qdel(user.vars[slot])
			continue

		if((user.vars[slot] && !istype(user.vars[slot], GLOB.slot2type[slot])) || !(chosen_prof.exists_list[slot]))
			continue

		var/obj/item/C
		var/equip = 0
		if(!user.vars[slot])
			var/thetype = GLOB.slot2type[slot]
			equip = 1
			C = new thetype(user)

		else if(istype(user.vars[slot], GLOB.slot2type[slot]))
			C = user.vars[slot]

		C.appearance = chosen_prof.appearance_list[slot]
		C.name = chosen_prof.name_list[slot]
		C.flags_cover = chosen_prof.flags_cover_list[slot]
		C.lefthand_file = chosen_prof.lefthand_file_list[slot]
		C.righthand_file = chosen_prof.righthand_file_list[slot]
		C.inhand_icon_state = chosen_prof.inhand_icon_state_list[slot]
		C.worn_icon = chosen_prof.worn_icon_list[slot]
		C.worn_icon_state = chosen_prof.worn_icon_state_list[slot]
		if(equip)
			user.equip_to_slot_or_del(C, GLOB.slot2slot[slot])

	user.regenerate_icons()
