/turf/fancyturf/fancy/wall/r_wall
	icon_state = "rgeneric"
/turf/fancyturf/fancy/wall/r_wall/New(var/newloc)
	..(newloc, MATERIAL_PLASTEEL, MATERIAL_PLASTEEL) //3strong

/turf/fancyturf/fancy/wall/cult
	icon_state = "cult"
/turf/fancyturf/fancy/wall/cult/New(var/newloc)
	..(newloc,"cult","cult2")
/turf/fancyturf/unsimulated/wall/cult
	name = "cult wall"
	desc = "Hideous images dance beneath the surface."
	icon = 'icons/turf/fancyturf/wall_masks.dmi'
	icon_state = "cult"

/turf/fancyturf/fancy/shuttle/wall
	name = "wall"
	icon_state = "wall1"
	opacity = 1
	density = TRUE
	blocks_air = 1

/turf/fancyturf/fancy/shuttle/wall/cargo
	name = "Cargo Transport Shuttle (A5)"
	icon = 'icons/turf/fancyturf/shuttlecargo.dmi'
	icon_state = "cargoshwall1"

/turf/fancyturf/fancy/shuttle/wall/escpod
	name = "Escape Pod"
	icon = 'icons/turf/fancyturf/shuttleescpod.dmi'
	icon_state = "escpodwall1"

/turf/fancyturf/fancy/shuttle/wall/mining
	name = "Mining Barge"
	icon = 'icons/turf/fancyturf/shuttlemining.dmi'
	icon_state = "11,23"

/turf/fancyturf/fancy/shuttle/wall/science
	name = "Science Shuttle"
	icon = 'icons/turf/fancyturf/shuttlescience.dmi'
	icon_state = "6,18"

/obj/structure/shuttle_part //For placing them over space, if sprite covers not whole tile.
	name = "shuttle"
	icon = 'icons/turf/fancyturf/shuttle.dmi'
	anchored = TRUE
	density = TRUE

/obj/structure/shuttle_part/cargo
	name = "Cargo Transport Shuttle (A5)"
	icon = 'icons/turf/fancyturf/shuttlecargo.dmi'
	icon_state = "cargoshwall1"

/obj/structure/shuttle_part/escpod
	name = "Escape Pod"
	icon = 'icons/turf/fancyturf/shuttleescpod.dmi'
	icon_state = "escpodwall1"

/obj/structure/shuttle_part/mining
	name = "Mining Barge"
	icon = 'icons/turf/fancyturf/shuttlemining.dmi'
	icon_state = "11,23"

/obj/structure/shuttle_part/science
	name = "Science Shuttle"
	icon = 'icons/turf/fancyturf/shuttlescience.dmi'
	icon_state = "6,18"

/obj/structure/shuttle_part/ex_act(severity) //Making them indestructible, like shuttle walls
    return 0

/turf/fancyturf/fancy/wall/iron/New(var/newloc)
	..(newloc,MATERIAL_IRON)
/turf/fancyturf/fancy/wall/uranium/New(var/newloc)
	..(newloc,MATERIAL_URANIUM)
/turf/fancyturf/fancy/wall/diamond/New(var/newloc)
	..(newloc,MATERIAL_DIAMOND)
/turf/fancyturf/fancy/wall/gold/New(var/newloc)
	..(newloc,MATERIAL_GOLD)
/turf/fancyturf/fancy/wall/silver/New(var/newloc)
	..(newloc,MATERIAL_SILVER)
/turf/fancyturf/fancy/wall/plasma/New(var/newloc)
	..(newloc,MATERIAL_PLASMA)
/turf/fancyturf/fancy/wall/sandstone/New(var/newloc)
	..(newloc,MATERIAL_SANDSTONE)
/turf/fancyturf/fancy/wall/ironplasma/New(var/newloc)
	..(newloc,MATERIAL_IRON,MATERIAL_PLASMA)
/turf/fancyturf/fancy/wall/golddiamond/New(var/newloc)
	..(newloc,MATERIAL_GOLD,MATERIAL_DIAMOND)
/turf/fancyturf/fancy/wall/silvergold/New(var/newloc)
	..(newloc,MATERIAL_SILVER,MATERIAL_GOLD)
/turf/fancyturf/fancy/wall/sandstonediamond/New(var/newloc)
	..(newloc,MATERIAL_SANDSTONE,MATERIAL_DIAMOND)

// Kind of wondering if this is going to bite me in the butt.
/turf/fancyturf/fancy/wall/voxshuttle/New(var/newloc)
	..(newloc,"voxalloy")
/turf/fancyturf/fancy/wall/voxshuttle/attackby()
	return
/turf/fancyturf/fancy/wall/titanium/New(var/newloc)
	..(newloc,"titanium")


//Untinted walls have white color, all their coloring is built into their sprite and they should really not be given a tint, it'd look awful
/turf/fancyturf/fancy/wall/untinted
	base_color_override = "#FFFFFF"
	reinf_color_override = "#FFFFFF"

/*
	One Star/Alliance walls, for use on derelict stuff
*/
/turf/fancyturf/fancy/wall/untinted/onestar
	icon_state = "onestar_standard"
	icon_base_override = "onestar_standard"


/turf/fancyturf/fancy/wall/untinted/onestar/New(var/newloc)
	..(newloc, MATERIAL_STEEL)


/turf/fancyturf/fancy/wall/untinted/onestar_reinforced
	icon_state = "onestar_reinforced"
	icon_base_override = "onestar_standard"
	icon_base_reinf_override = "onestar_reinforced"

/turf/fancyturf/fancy/wall/untinted/onestar_reinforced/New(var/newloc)
	..(newloc, MATERIAL_STEEL,MATERIAL_STEEL)