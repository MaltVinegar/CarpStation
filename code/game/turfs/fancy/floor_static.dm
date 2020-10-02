// This type of flooring cannot be altered short of being destroyed and rebuilt.
// Use this to bypass the flooring system entirely ie. event areas, holodeck, etc.

/turf/fancyturf/fancy/floor/fixed
	name = "floor"
	icon = 'icons/turf/fancyturf/flooring/tiles.dmi'
	icon_state = "steel"
	initial_flooring = null

/turf/fancyturf/fancy/floor/fixed/attackby(var/obj/item/C, var/mob/user)
	if(istype(C, /obj/item/stack) && !istype(C, /obj/item/stack/cable_coil))
		return
	return ..()

/turf/fancyturf/fancy/floor/fixed/update_icon()
	return

/turf/fancyturf/fancy/floor/fixed/is_plating()
	return FALSE

/turf/fancyturf/fancy/floor/fixed/set_flooring()
	return

