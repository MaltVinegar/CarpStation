/datum/surgery/custom_replacement
	name = "Custom Replacement"

	// For testing
	//steps = list(/datum/surgery_step/add_custom)

	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/add_custom)

	// Why is monkey on this?
	// target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	target_mobtypes = list(/mob/living/carbon/human)

	// For now
	possible_locs = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_HEAD)
	requires_bodypart = FALSE //need a missing limb
	requires_bodypart_type = 0

/datum/surgery/custom_replacement/can_start(mob/user, mob/living/carbon/target)
	if(!iscarbon(target))
		return FALSE
	var/mob/living/carbon/C = target
	if(!C.get_bodypart(user.zone_selected)) //can only start if limb is missing
		return TRUE
	return FALSE


// Here where we doing the thing
// needs to be revamped?
// Implements seems not to matter
/datum/surgery_step/add_custom
	name = "add custom"

	// Think maybe this?
	// So it will accept it now hm.
	implements = list(/obj/item = 100)
	time = 32
	var/organ_rejection_dam = 0

/datum/surgery_step/add_custom/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)


	// robot shit so they can do it
	// if(istype(tool, /obj/item/organ_storage))
	// 	if(!tool.contents.len)
	// 		to_chat(user, "<span class='warning'>There is nothing inside [tool]!</span>")
	// 		return -1
	// 	var/obj/item/I = tool.contents[1]
	// 	if(!isbodypart(I))
	// 		to_chat(user, "<span class='warning'>[I] cannot be attached!</span>")
	// 		return -1
	// 	tool = I


	// Where we checking
	// tool here is the item we are placing onto the user

	// Might want to make sure it's not an actual limb
	if(istype(tool, /obj/item))
		// var/obj/item/BP = tool



		// if(target_zone == BP.body_zone) //so we can't replace a leg with an arm, or a human arm with a monkey arm.

		display_results(user, target, "<span class='notice'>You begin to replace [target]'s [parse_zone(target_zone)] with [tool]...</span>",
			"<span class='notice'>[user] begins to replace [target]'s [parse_zone(target_zone)] with [tool].</span>",
			"<span class='notice'>[user] begins to replace [target]'s [parse_zone(target_zone)].</span>")


		// else
		// 	to_chat(user, "<span class='warning'>[tool] isn't the right type for [parse_zone(target_zone)].</span>")
		// 	return -1
	// else if(target_zone == BODY_ZONE_L_ARM || target_zone == BODY_ZONE_R_ARM)
	// 	display_results(user, target, "<span class='notice'>You begin to attach [tool] onto [target]...</span>",
	// 		"<span class='notice'>[user] begins to attach [tool] onto [target]'s [parse_zone(target_zone)].</span>",
	// 		"<span class='notice'>[user] begins to attach something onto [target]'s [parse_zone(target_zone)].</span>")
	// else
	// 	to_chat(user, "<span class='warning'>[tool] must be installed onto an arm.</span>")
	// 	return -1

/datum/surgery_step/add_custom/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	. = ..()


	// if(istype(tool, /obj/item/organ_storage))
	// 	tool.icon_state = initial(tool.icon_state)
	// 	tool.desc = initial(tool.desc)
	// 	tool.cut_overlays()
	// 	tool = tool.contents[1]


	// if(istype(tool, /obj/item) && user.temporarilyRemoveItemFromInventory(tool))
	// 	var/obj/item/L = tool

	// 	// uhhh
	// 	if(!L.attach_limb(target))
	// 		display_results(user, target, "<span class='warning'>You fail in replacing [target]'s [parse_zone(target_zone)]! Their body has rejected [L]!</span>",
	// 			"<span class='warning'>[user] fails to replace [target]'s [parse_zone(target_zone)]!</span>",
	// 			"<span class='warning'>[user] fails to replaces [target]'s [parse_zone(target_zone)]!</span>")
	// 		return
	// 	if(organ_rejection_dam)
	// 		target.adjustToxLoss(organ_rejection_dam)
	// 	display_results(user, target, "<span class='notice'>You succeed in replacing [target]'s [parse_zone(target_zone)].</span>",
	// 		"<span class='notice'>[user] successfully replaces [target]'s [parse_zone(target_zone)] with [tool]!</span>",
	// 		"<span class='notice'>[user] successfully replaces [target]'s [parse_zone(target_zone)]!</span>")
	// 	return

	// tool.drop
	user.temporarilyRemoveItemFromInventory(tool)
	//user.drop(tool)
	// else
	// tool.drop()

	// Really good but no..
	//tool.orbit(target, radius = 0, rotation_speed = 0, rotation_segments = 0)

	tool.forceMove(target.loc)
	// tool.set_anchored(TRUE)


	var/obj/item/bodypart/L

	switch(target_zone)
		if(BODY_ZONE_L_ARM)
			L = new /obj/item/bodypart/l_arm()
		if(BODY_ZONE_R_ARM)
			L = new /obj/item/bodypart/r_arm()
		if(BODY_ZONE_HEAD)
			L = new /obj/item/bodypart/head()
		if(BODY_ZONE_L_LEG)
			L = new /obj/item/bodypart/l_leg()
		if(BODY_ZONE_R_LEG)
			L = new /obj/item/bodypart/r_leg()
		if(BODY_ZONE_CHEST)
			L = new /obj/item/bodypart/chest()

	L.is_pseudopart = TRUE
	L.status = BODYPART_CUSTOM
	L.icon = tool.icon
	L.icon_state = tool.icon_state
	L.customitem = tool




	if(!L.attach_limb(target))
		display_results(user, target, "<span class='warning'>You fail in attaching [target]'s [parse_zone(target_zone)]! Their body has rejected [L]!</span>",
			"<span class='warning'>[user] fails to attach [target]'s [parse_zone(target_zone)]!</span>",
			"<span class='warning'>[user] fails to attach [target]'s [parse_zone(target_zone)]!</span>")
		L.forceMove(target.loc)
		return
	user.visible_message("<span class='notice'>[user] finishes attaching [tool]!</span>", "<span class='notice'>You attach [tool].</span>")
	display_results(user, target, "<span class='notice'>You attach [tool].</span>",
		"<span class='notice'>[user] finishes attaching [tool]!</span>",
		"<span class='notice'>[user] finishes the attachment procedure!</span>")


	L.status = BODYPART_CUSTOM
	L.icon = tool.icon
	L.icon_state = tool.icon_state

	// tool.can_drop = FALSE

	// L.update_limb(L, target)
	// qdel(tool)

	ADD_TRAIT(tool, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)

	if(istype(tool, /obj/item))
		if(target_zone == BODY_ZONE_R_ARM || target_zone == BODY_ZONE_L_ARM)
			target.put_in_r_hand(tool)
		if(target_zone == BODY_ZONE_L_ARM)
			target.put_in_l_hand(tool)


	var/mob/living/carbon/C = target
	C.update_body()
	tool.lefthand_file = null
	tool.righthand_file = null

	if(istype(tool, /obj/item/gun))
		var/obj/item/gun/guntool = tool
		guntool.weapon_weight = WEAPON_LIGHT

		if(target_zone == BODY_ZONE_R_ARM || target_zone == BODY_ZONE_L_ARM)
			target_zone == BODY_ZONE_R_ARM ? target.put_in_r_hand(tool) : target.put_in_l_hand(tool)

	if(target_zone != BODY_ZONE_R_ARM && target_zone != BODY_ZONE_L_ARM)
		tool.forceMove(target.loc)
		tool.orbit(target, radius = 0, rotation_speed = 0, rotation_segments = 0)
		var/matrix/M = matrix()
		M.Scale(0.01, 0.01)
		tool.transform = M
		tool.icon_state = null
		tool.icon = null

	L.customitem = tool
	C.update_body()




	// tool.forceMove(L.loc)

	// Ok here's a trick that'd work
	// Put the item in hand but then move it to player and anchor it?
	// err then people might be able to pick it up

	// tbh I should just fucking redo the character shit maybe?

	// The problem I see with this is that

		// if(istype(tool, /obj/item/chainsaw))
		// 	var/obj/item/mounted_chainsaw/new_arm = new(target)
		// 	target_zone == BODY_ZONE_R_ARM ? target.put_in_r_hand(new_arm) : target.put_in_l_hand(new_arm)
		// 	return
		// else if(istype(tool, /obj/item/melee/synthetic_arm_blade))
		// 	var/obj/item/melee/arm_blade/new_arm = new(target,TRUE,TRUE)
		// 	target_zone == BODY_ZONE_R_ARM ? target.put_in_r_hand(new_arm) : target.put_in_l_hand(new_arm)
		// 	return



	return ..() //if for some reason we fail everything we'll print out some text okay?
