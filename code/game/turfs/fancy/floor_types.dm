/turf/fancyturf/fancy/shuttle
	name = "shuttle"
	icon = 'icons/turf/fancyturf/shuttle.dmi'
	thermal_conductivity = 0.05
	heat_capacity = 0
	layer = 2

/turf/fancyturf/fancy/shuttle/floor
	name = "floor"
	icon_state = "floor"
	plane = FLOOR_PLANE

/turf/fancyturf/fancy/shuttle/floor/mining
	icon_state = "6,19"
	icon = 'icons/turf/fancyturf/shuttlemining.dmi'

/turf/fancyturf/fancy/shuttle/floor/science
	icon_state = "8,15"
	icon = 'icons/turf/fancyturf/shuttlescience.dmi'

/turf/fancyturf/fancy/shuttle/plating
	name = "plating"
	icon = 'icons/turf/fancyturf/floors.dmi'
	icon_state = "plating"
	level = BELOW_PLATING_LEVEL

/turf/fancyturf/fancy/shuttle/plating/is_plating()
	return TRUE


/turf/fancyturf/fancy/floor/plating
	icon = 'icons/turf/fancyturf/flooring/plating.dmi'
	name = "plating"
	icon_state = "plating"
	initial_flooring = /decl/flooring/reinforced/plating

/turf/fancyturf/fancy/floor/plating/under
	name = "underplating"
	icon_state = "under"
	icon = 'icons/turf/fancyturf/flooring/plating.dmi'
	initial_flooring = /decl/flooring/reinforced/plating/under


/turf/fancyturf/fancy/floor/grass
	name = "grass patch"
	icon = 'icons/turf/fancyturf/flooring/grass.dmi'
	icon_state = "grass0"
	initial_flooring = /decl/flooring/grass

/turf/fancyturf/fancy/floor/dirt
	name = "dirt"
	icon = 'icons/turf/fancyturf/flooring/dirt.dmi'
	icon_state = "dirt"
	initial_flooring = /decl/flooring/dirt

/turf/fancyturf/fancy/floor/hull
	name = "hull"
	icon = 'icons/turf/fancyturf/flooring/hull.dmi'
	icon_state = "hullcenter0"
	initial_flooring = /decl/flooring/reinforced/plating/hull


/turf/fancyturf/fancy/floor/hull/New()
	if(icon_state != "hullcenter0")
		overrided_icon_state = icon_state
	..()

/turf/fancyturf/fancy/shuttle/plating/vox //Skipjack plating
	oxygen = 0
	nitrogen = MOLES_N2STANDARD + MOLES_O2STANDARD

/turf/fancyturf/fancy/shuttle/floor4 // Added this floor tile so that I have a seperate turf to check in the shuttle -- Polymorph
	name = "Brig floor"        // Also added it into the 2x3 brig area of the shuttle.
	icon_state = "floor4"

/turf/fancyturf/fancy/shuttle/floor4/vox //skipjack floors
	name = "skipjack floor"
	oxygen = 0
	nitrogen = MOLES_N2STANDARD + MOLES_O2STANDARD
