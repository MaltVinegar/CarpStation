//All defines used in reactions are located in ..\__DEFINES\reactions.dm
/*priority so far, check this list to see what are the numbers used. Please use a different priority for each reaction(higher number are done first)
miaster = -10 (this should always be under all other fires)
freonfire = -5
plasmafire = -4
h2fire = -3
tritfire = -2
halon_o2removal = -1
nitrous_decomp = 0
water_vapor = 1
pluox_formation = 2
nitrylformation = 3
bzformation = 4
freonformation = 5
stimformation = 5
nobiliumformation = 6
stimball = 7
ammoniacrystals = 8
hexane_plasma_filtering = 9
hexane_n2o_filtering = 10
zauker_decomp = 11
healium_production = 12
proto_nitrate_production = 13
zauker_production = 14
halon_formation = 15
hexane_formation = 16
healium_crystal_production = 17
proto_nitrate_crystal_production = 18
zauker_crystal_production = 19
proto_nitrate_response = 20 - 25
fusion = 26
metallic_hydrogen = 27
nobiliumsuppression = INFINITY
*/

/proc/init_gas_reactions()
	. = list()

	for(var/r in subtypesof(/datum/gas_reaction))
		var/datum/gas_reaction/reaction = r
		if(initial(reaction.exclude))
			continue
		reaction = new r
		var/datum/gas/reaction_key
		for (var/req in reaction.min_requirements)
			if (ispath(req))
				var/datum/gas/req_gas = req
				if (!reaction_key || initial(reaction_key.rarity) > initial(req_gas.rarity))
					reaction_key = req_gas
		reaction.major_gas = reaction_key
		. += reaction
	sortTim(., /proc/cmp_gas_reaction)

/proc/cmp_gas_reaction(datum/gas_reaction/a, datum/gas_reaction/b) // compares lists of reactions by the maximum priority contained within the list
	return b.priority - a.priority

/datum/gas_reaction
	//regarding the requirements lists: the minimum or maximum requirements must be non-zero.
	//when in doubt, use MINIMUM_MOLE_COUNT.
	var/list/min_requirements
	var/major_gas //the highest rarity gas used in the reaction.
	var/exclude = FALSE //do it this way to allow for addition/removal of reactions midmatch in the future
	var/priority = 100 //lower numbers are checked/react later than higher numbers. if two reactions have the same priority they may happen in either order
	var/name = "reaction"
	var/id = "r"

/datum/gas_reaction/New()
	init_reqs()

/datum/gas_reaction/proc/init_reqs()

/datum/gas_reaction/proc/react(datum/gas_mixture/air, atom/location)
	return NO_REACTION

/datum/gas_reaction/nobliumsupression
	priority = INFINITY
	name = "Hyper-Noblium Reaction Suppression"
	id = "nobstop"

/datum/gas_reaction/nobliumsupression/init_reqs()
	min_requirements = list(/datum/gas/hypernoblium = REACTION_OPPRESSION_THRESHOLD)

/datum/gas_reaction/nobliumsupression/react()
	return STOP_REACTIONS

//water vapor: puts out fires?
/datum/gas_reaction/water_vapor
	priority = 1
	name = "Water Vapor"
	id = "vapor"

/datum/gas_reaction/water_vapor/init_reqs()
	min_requirements = list(/datum/gas/water_vapor = MOLES_GAS_VISIBLE)

/datum/gas_reaction/water_vapor/react(datum/gas_mixture/air, datum/holder)
	var/turf/open/location = isturf(holder) ? holder : null
	. = NO_REACTION
	if (air.temperature <= WATER_VAPOR_FREEZE)
		if(location && location.freon_gas_act())
			. = REACTING
	else if(air.temperature <= T20C + 10)
		if(location && location.water_vapor_gas_act())
			air.gases[/datum/gas/water_vapor][MOLES] -= MOLES_GAS_VISIBLE
			. = REACTING

//tritium combustion: combustion of oxygen and tritium (treated as hydrocarbons). creates hotspots. exothermic
/datum/gas_reaction/nitrous_decomp
	priority = 0
	name = "Nitrous Oxide Decomposition"
	id = "nitrous_decomp"

/datum/gas_reaction/nitrous_decomp/init_reqs()
	min_requirements = list(
		"TEMP" = N2O_DECOMPOSITION_MIN_ENERGY,
		/datum/gas/nitrous_oxide = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/nitrous_decomp/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases //this speeds things up because accessing datum vars is slow
	var/temperature = air.temperature
	var/burned_fuel = 0


	burned_fuel = max(0,0.00002 * (temperature - (0.00001 * (temperature**2)))) * cached_gases[/datum/gas/nitrous_oxide][MOLES]
	if(cached_gases[/datum/gas/nitrous_oxide][MOLES] - burned_fuel < 0)
		return NO_REACTION
	cached_gases[/datum/gas/nitrous_oxide][MOLES] -= burned_fuel

	if(burned_fuel)
		energy_released += (N2O_DECOMPOSITION_ENERGY_RELEASED * burned_fuel)

		ASSERT_GAS(/datum/gas/oxygen, air)
		cached_gases[/datum/gas/oxygen][MOLES] += burned_fuel * 0.5
		ASSERT_GAS(/datum/gas/nitrogen, air)
		cached_gases[/datum/gas/nitrogen][MOLES] += burned_fuel

		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
		return REACTING
	return NO_REACTION

//tritium combustion: combustion of oxygen and tritium (treated as hydrocarbons). creates hotspots. exothermic
/datum/gas_reaction/tritfire
	priority = -2 //fire should ALWAYS be last, but tritium fires happen before plasma fires
	name = "Tritium Combustion"
	id = "tritfire"

/datum/gas_reaction/tritfire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		/datum/gas/tritium = MINIMUM_MOLE_COUNT,
		/datum/gas/oxygen = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/tritfire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases //this speeds things up because accessing datum vars is slow
	var/temperature = air.temperature
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = 0
	var/turf/open/location = isturf(holder) ? holder : null
	var/burned_fuel = 0
	if(cached_gases[/datum/gas/oxygen][MOLES] < cached_gases[/datum/gas/tritium][MOLES] || MINIMUM_TRIT_OXYBURN_ENERGY > air.thermal_energy())
		burned_fuel = cached_gases[/datum/gas/oxygen][MOLES] / TRITIUM_BURN_OXY_FACTOR
		cached_gases[/datum/gas/tritium][MOLES] -= burned_fuel
	else
		burned_fuel = cached_gases[/datum/gas/tritium][MOLES] * TRITIUM_BURN_TRIT_FACTOR
		cached_gases[/datum/gas/tritium][MOLES] -= cached_gases[/datum/gas/tritium][MOLES] / TRITIUM_BURN_TRIT_FACTOR
		cached_gases[/datum/gas/oxygen][MOLES] -= cached_gases[/datum/gas/tritium][MOLES]

	if(burned_fuel)
		energy_released += (FIRE_HYDROGEN_ENERGY_RELEASED * burned_fuel)
		if(location && prob(10) && burned_fuel > TRITIUM_MINIMUM_RADIATION_ENERGY) //woah there let's not crash the server
			radiation_pulse(location, energy_released / TRITIUM_BURN_RADIOACTIVITY_FACTOR)

		ASSERT_GAS(/datum/gas/water_vapor, air) //oxygen+more-or-less hydrogen=H2O
		cached_gases[/datum/gas/water_vapor][MOLES] += burned_fuel / TRITIUM_BURN_OXY_FACTOR

		cached_results["fire"] += burned_fuel

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity

	//let the floor know a fire is happening
	if(istype(location))
		temperature = air.temperature
		if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
			location.hotspot_expose(temperature, CELL_VOLUME)
			for(var/I in location)
				var/atom/movable/item = I
				item.temperature_expose(air, temperature, CELL_VOLUME)
			location.temperature_expose(air, temperature, CELL_VOLUME)

	return cached_results["fire"] ? REACTING : NO_REACTION

//plasma combustion: combustion of oxygen and plasma (treated as hydrocarbons). creates hotspots. exothermic
/datum/gas_reaction/plasmafire
	priority = -4 //fire should ALWAYS be last, but plasma fires happen after tritium fires
	name = "Plasma Combustion"
	id = "plasmafire"

/datum/gas_reaction/plasmafire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		/datum/gas/plasma = MINIMUM_MOLE_COUNT,
		/datum/gas/oxygen = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/plasmafire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases //this speeds things up because accessing datum vars is slow
	var/temperature = air.temperature
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = 0
	var/turf/open/location = isturf(holder) ? holder : null

	//Handle plasma burning
	var/plasma_burn_rate = 0
	var/oxygen_burn_rate = 0
	//more plasma released at higher temperatures
	var/temperature_scale = 0
	//to make tritium
	var/super_saturation = FALSE

	if(temperature > PLASMA_UPPER_TEMPERATURE)
		temperature_scale = 1
	else
		temperature_scale = (temperature - PLASMA_MINIMUM_BURN_TEMPERATURE) / (PLASMA_UPPER_TEMPERATURE-PLASMA_MINIMUM_BURN_TEMPERATURE)
	if(temperature_scale > 0)
		oxygen_burn_rate = OXYGEN_BURN_RATE_BASE - temperature_scale
		if(cached_gases[/datum/gas/oxygen][MOLES] / cached_gases[/datum/gas/plasma][MOLES] > SUPER_SATURATION_THRESHOLD) //supersaturation. Form Tritium.
			super_saturation = TRUE
		if(cached_gases[/datum/gas/oxygen][MOLES] > cached_gases[/datum/gas/plasma][MOLES] * PLASMA_OXYGEN_FULLBURN)
			plasma_burn_rate = (cached_gases[/datum/gas/plasma][MOLES] * temperature_scale) / PLASMA_BURN_RATE_DELTA
		else
			plasma_burn_rate = (temperature_scale * (cached_gases[/datum/gas/oxygen][MOLES] / PLASMA_OXYGEN_FULLBURN)) / PLASMA_BURN_RATE_DELTA

		if(plasma_burn_rate > MINIMUM_HEAT_CAPACITY)
			plasma_burn_rate = min(plasma_burn_rate, cached_gases[/datum/gas/plasma][MOLES], cached_gases[/datum/gas/oxygen][MOLES]/oxygen_burn_rate) //Ensures matter is conserved properly
			cached_gases[/datum/gas/plasma][MOLES] = QUANTIZE(cached_gases[/datum/gas/plasma][MOLES] - plasma_burn_rate)
			cached_gases[/datum/gas/oxygen][MOLES] = QUANTIZE(cached_gases[/datum/gas/oxygen][MOLES] - (plasma_burn_rate * oxygen_burn_rate))
			if (super_saturation)
				ASSERT_GAS(/datum/gas/tritium, air)
				cached_gases[/datum/gas/tritium][MOLES] += plasma_burn_rate
			else
				ASSERT_GAS(/datum/gas/carbon_dioxide,air)
				ASSERT_GAS(/datum/gas/water_vapor,air)
				cached_gases[/datum/gas/carbon_dioxide][MOLES] += plasma_burn_rate * 0.75
				cached_gases[/datum/gas/water_vapor][MOLES] += plasma_burn_rate * 0.25

			energy_released += FIRE_PLASMA_ENERGY_RELEASED * (plasma_burn_rate)

			cached_results["fire"] += (plasma_burn_rate) * (1 + oxygen_burn_rate)

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature*old_heat_capacity + energy_released)/new_heat_capacity

	//let the floor know a fire is happening
	if(istype(location))
		temperature = air.temperature
		if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
			location.hotspot_expose(temperature, CELL_VOLUME)
			for(var/I in location)
				var/atom/movable/item = I
				item.temperature_expose(air, temperature, CELL_VOLUME)
			location.temperature_expose(air, temperature, CELL_VOLUME)

	return cached_results["fire"] ? REACTING : NO_REACTION

//freon reaction (is not a fire yet)
/datum/gas_reaction/freonfire
	priority = -5
	name = "Freon combustion"
	id = "freonfire"

/datum/gas_reaction/freonfire/init_reqs()
	min_requirements = list(
		/datum/gas/oxygen = MINIMUM_MOLE_COUNT,
		/datum/gas/freon = MINIMUM_MOLE_COUNT,
		"TEMP" = FREON_LOWER_TEMPERATURE,
		"MAX_TEMP" = FREON_MAXIMUM_BURN_TEMPERATURE
		)

/datum/gas_reaction/freonfire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases //this speeds things up because accessing datum vars is slow
	var/temperature = air.temperature
	if(!isturf(holder))
		return NO_REACTION
	var/turf/open/location = holder

	//Handle freon burning (only reaction now)
	var/freon_burn_rate = 0
	var/oxygen_burn_rate = 0
	//more freon released at lower temperatures
	var/temperature_scale = 1

	if(temperature < FREON_LOWER_TEMPERATURE) //stop the reaction when too cold
		temperature_scale = 0
	else
		temperature_scale = (FREON_MAXIMUM_BURN_TEMPERATURE - temperature) / (FREON_MAXIMUM_BURN_TEMPERATURE - FREON_LOWER_TEMPERATURE) //calculate the scale based on the temperature
	if(temperature_scale >= 0)
		oxygen_burn_rate = OXYGEN_BURN_RATE_BASE - temperature_scale
		if(cached_gases[/datum/gas/oxygen][MOLES] > cached_gases[/datum/gas/freon][MOLES] * FREON_OXYGEN_FULLBURN)
			freon_burn_rate = (cached_gases[/datum/gas/freon][MOLES] * temperature_scale) / FREON_BURN_RATE_DELTA
		else
			freon_burn_rate = (temperature_scale * (cached_gases[/datum/gas/oxygen][MOLES] / FREON_OXYGEN_FULLBURN)) / FREON_BURN_RATE_DELTA

		if(freon_burn_rate > MINIMUM_HEAT_CAPACITY)
			freon_burn_rate = min(freon_burn_rate, cached_gases[/datum/gas/freon][MOLES], cached_gases[/datum/gas/oxygen][MOLES] / oxygen_burn_rate) //Ensures matter is conserved properly
			cached_gases[/datum/gas/freon][MOLES] = QUANTIZE(cached_gases[/datum/gas/freon][MOLES] - freon_burn_rate)
			cached_gases[/datum/gas/oxygen][MOLES] = QUANTIZE(cached_gases[/datum/gas/oxygen][MOLES] - (freon_burn_rate * oxygen_burn_rate))
			ASSERT_GAS(/datum/gas/carbon_dioxide, air)
			cached_gases[/datum/gas/carbon_dioxide][MOLES] += freon_burn_rate

			if(temperature < 160 && temperature > 120 && prob(2))
				new /obj/item/stack/sheet/hot_ice(location)

			energy_released += FIRE_FREON_ENERGY_RELEASED * (freon_burn_rate)

	if(energy_released < 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity

/datum/gas_reaction/h2fire
	priority = -3 //fire should ALWAYS be last, but tritium fires happen before plasma fires
	name = "Hydrogen Combustion"
	id = "h2fire"

/datum/gas_reaction/h2fire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		/datum/gas/hydrogen = MINIMUM_MOLE_COUNT,
		/datum/gas/oxygen = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/h2fire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases //this speeds things up because accessing datum vars is slow
	var/temperature = air.temperature
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = 0
	var/turf/open/location = isturf(holder) ? holder : null
	var/burned_fuel = 0
	if(cached_gases[/datum/gas/oxygen][MOLES] < cached_gases[/datum/gas/hydrogen][MOLES] || MINIMUM_H2_OXYBURN_ENERGY > air.thermal_energy())
		burned_fuel = cached_gases[/datum/gas/oxygen][MOLES]/HYDROGEN_BURN_OXY_FACTOR
		cached_gases[/datum/gas/hydrogen][MOLES] -= burned_fuel
	else
		burned_fuel = cached_gases[/datum/gas/hydrogen][MOLES] * HYDROGEN_BURN_H2_FACTOR
		cached_gases[/datum/gas/hydrogen][MOLES] -= cached_gases[/datum/gas/hydrogen][MOLES] / HYDROGEN_BURN_H2_FACTOR
		cached_gases[/datum/gas/oxygen][MOLES] -= cached_gases[/datum/gas/hydrogen][MOLES]

	if(burned_fuel)
		energy_released += (FIRE_HYDROGEN_ENERGY_RELEASED * burned_fuel)

		ASSERT_GAS(/datum/gas/water_vapor, air) //oxygen+more-or-less hydrogen=H2O
		cached_gases[/datum/gas/water_vapor][MOLES] += burned_fuel / HYDROGEN_BURN_OXY_FACTOR

		cached_results["fire"] += burned_fuel

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature*old_heat_capacity + energy_released) / new_heat_capacity

	//let the floor know a fire is happening
	if(istype(location))
		temperature = air.temperature
		if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
			location.hotspot_expose(temperature, CELL_VOLUME)
			for(var/I in location)
				var/atom/movable/item = I
				item.temperature_expose(air, temperature, CELL_VOLUME)
			location.temperature_expose(air, temperature, CELL_VOLUME)

	return cached_results["fire"] ? REACTING : NO_REACTION

/datum/gas_reaction/ammoniacrystals
	priority = 8
	name = "Ammonia crystals formation"
	id = "nh4crystals"

/datum/gas_reaction/ammoniacrystals/init_reqs()
	min_requirements = list(
		/datum/gas/hydrogen = MINIMUM_MOLE_COUNT,
		/datum/gas/nitrogen = MINIMUM_MOLE_COUNT,
		"TEMP" = 150,
		"MAX_TEMP" = 273
	)

/datum/gas_reaction/ammoniacrystals/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	if(!isturf(holder))
		return NO_REACTION
	var/turf/open/location = holder
	var/consumed_fuel = 0
	if(cached_gases[/datum/gas/nitrogen][MOLES] > cached_gases[/datum/gas/hydrogen][MOLES])
		consumed_fuel = (cached_gases[/datum/gas/hydrogen][MOLES] / AMMONIA_FORMATION_FACTOR)
		if(cached_gases[/datum/gas/nitrogen][MOLES] - consumed_fuel < 0 || cached_gases[/datum/gas/hydrogen][MOLES] - consumed_fuel * 4 < 0)
			return NO_REACTION
		cached_gases[/datum/gas/nitrogen][MOLES] -= consumed_fuel
		cached_gases[/datum/gas/hydrogen][MOLES] -= consumed_fuel * 4
		if(prob(30 * consumed_fuel))
			new /obj/item/stack/ammonia_crystals(location)
		energy_released += consumed_fuel * AMMONIA_FORMATION_ENERGY
	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released)/new_heat_capacity

//fusion: a terrible idea that was fun but broken. Now reworked to be less broken and more interesting. Again (and again, and again). Again!
//Fusion Rework Counter: Please increment this if you make a major overhaul to this system again.
//6 reworks

/datum/gas_reaction/fusion
	exclude = FALSE
	priority = 26
	name = "Plasmic Fusion"
	id = "fusion"

/datum/gas_reaction/fusion/init_reqs()
	min_requirements = list(
		"TEMP" = FUSION_TEMPERATURE_THRESHOLD,
		/datum/gas/tritium = FUSION_TRITIUM_MOLES_USED,
		/datum/gas/plasma = FUSION_MOLE_THRESHOLD,
		/datum/gas/hydrogen = FUSION_MOLE_THRESHOLD)

/datum/gas_reaction/fusion/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/turf/open/location
	if (istype(holder,/datum/pipeline)) //Find the tile the reaction is occuring on, or a random part of the network if it's a pipenet.
		var/datum/pipeline/fusion_pipenet = holder
		location = get_turf(pick(fusion_pipenet.members))
	else
		location = get_turf(holder)
	if(!air.analyzer_results)
		air.analyzer_results = new
	var/list/cached_scan_results = air.analyzer_results
	var/old_heat_capacity = air.heat_capacity()
	var/reaction_energy = 0 //Reaction energy can be negative or positive, for both exothermic and endothermic reactions.
	var/initial_plasma = cached_gases[/datum/gas/plasma][MOLES]
	var/initial_hydrogen = cached_gases[/datum/gas/hydrogen][MOLES]
	var/scale_factor = (air.volume)/(PI) //We scale it down by volume/Pi because for fusion conditions, moles roughly = 2*volume, but we want it to be based off something constant between reactions.
	var/toroidal_size = (2 * PI) //The size of the phase space hypertorus
	var/gas_power = 0
	for (var/gas_id in cached_gases)
		gas_power += (cached_gases[gas_id][GAS_META][META_GAS_FUSION_POWER] * cached_gases[gas_id][MOLES])
	var/instability = MODULUS((gas_power * INSTABILITY_GAS_POWER_FACTOR)**2, toroidal_size) //Instability effects how chaotic the behavior of the reaction is
	cached_scan_results[id] = instability//used for analyzer feedback

	var/plasma = (initial_plasma-FUSION_MOLE_THRESHOLD)/(scale_factor) //We have to scale the amounts of hydrogen and plasma down a significant amount in order to show the chaotic dynamics we want
	var/hydrogen = (initial_hydrogen-FUSION_MOLE_THRESHOLD)/(scale_factor) //We also subtract out the threshold amount to make it harder for fusion to burn itself out.

	//The reaction is a specific form of the Kicked Rotator system, which displays chaotic behavior and can be used to model particle interactions.
	plasma = MODULUS(plasma - (instability * sin(TODEGREES(hydrogen))), toroidal_size)
	hydrogen = MODULUS(hydrogen - plasma, toroidal_size)


	cached_gases[/datum/gas/plasma][MOLES] = plasma * scale_factor + FUSION_MOLE_THRESHOLD //Scales the gases back up
	cached_gases[/datum/gas/hydrogen][MOLES] = hydrogen * scale_factor + FUSION_MOLE_THRESHOLD
	var/delta_plasma = initial_plasma - cached_gases[/datum/gas/plasma][MOLES]

	reaction_energy += delta_plasma * PLASMA_BINDING_ENERGY //Energy is gained or lost corresponding to the creation or destruction of mass.
	if(instability < FUSION_INSTABILITY_ENDOTHERMALITY)
		reaction_energy = max(reaction_energy, 0) //Stable reactions don't end up endothermic.
	else if (reaction_energy < 0)
		reaction_energy *= (instability-FUSION_INSTABILITY_ENDOTHERMALITY)**0.5

	if(air.thermal_energy() + reaction_energy < 0) //No using energy that doesn't exist.
		cached_gases[/datum/gas/plasma][MOLES] = initial_plasma
		cached_gases[/datum/gas/hydrogen][MOLES] = initial_hydrogen
		return NO_REACTION
	cached_gases[/datum/gas/tritium][MOLES] -= FUSION_TRITIUM_MOLES_USED
	//The decay of the tritium and the reaction's energy produces waste gases, different ones depending on whether the reaction is endo or exothermic
	if(reaction_energy > 0)
		air.assert_gases(/datum/gas/carbon_dioxide, /datum/gas/water_vapor)
		cached_gases[/datum/gas/carbon_dioxide][MOLES] += FUSION_TRITIUM_MOLES_USED * (reaction_energy * FUSION_TRITIUM_CONVERSION_COEFFICIENT)
		cached_gases[/datum/gas/water_vapor][MOLES] += (FUSION_TRITIUM_MOLES_USED * (reaction_energy * FUSION_TRITIUM_CONVERSION_COEFFICIENT)) * 0.25
	else
		air.assert_gases(/datum/gas/carbon_dioxide)
		cached_gases[/datum/gas/carbon_dioxide][MOLES] += FUSION_TRITIUM_MOLES_USED * (reaction_energy * -FUSION_TRITIUM_CONVERSION_COEFFICIENT)

	if(reaction_energy)
		if(location)
			var/particle_chance = ((PARTICLE_CHANCE_CONSTANT) / (reaction_energy - PARTICLE_CHANCE_CONSTANT)) + 1//Asymptopically approaches 100% as the energy of the reaction goes up.
			if(prob(PERCENT(particle_chance)))
				location.fire_nuclear_particle()
			var/rad_power = max((FUSION_RAD_COEFFICIENT / instability) + FUSION_RAD_MAX, 0)
			radiation_pulse(location,rad_power)

		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY && (air.temperature <= FUSION_MAXIMUM_TEMPERATURE || reaction_energy <= 0))	//If above FUSION_MAXIMUM_TEMPERATURE, will only adjust temperature for endothermic reactions.
			air.temperature = clamp(((air.temperature * old_heat_capacity + reaction_energy) / new_heat_capacity), TCMB, INFINITY)
		return REACTING

/datum/gas_reaction/nitrousformation //formationn of n2o, esothermic, requires bz as catalyst
	priority = 3
	name = "Nitrous Oxide formation"
	id = "nitrousformation"

/datum/gas_reaction/nitrousformation/init_reqs()
	min_requirements = list(
		/datum/gas/oxygen = 10,
		/datum/gas/nitrogen = 20,
		/datum/gas/bz = 5,
		"TEMP" = 200,
		"MAX_TEMP" = 250
	)

/datum/gas_reaction/nitrousformation/react(datum/gas_mixture/air)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(cached_gases[/datum/gas/oxygen][MOLES], cached_gases[/datum/gas/nitrogen][MOLES])
	var/energy_used = heat_efficency * NITROUS_FORMATION_ENERGY
	ASSERT_GAS(/datum/gas/nitrous_oxide, air)
	if ((cached_gases[/datum/gas/oxygen][MOLES] - heat_efficency < 0 ) || (cached_gases[/datum/gas/nitrogen][MOLES] - heat_efficency * 2 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/oxygen][MOLES] -= heat_efficency
	cached_gases[/datum/gas/nitrogen][MOLES] -= heat_efficency * 2
	cached_gases[/datum/gas/nitrous_oxide][MOLES] += heat_efficency

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity), TCMB) //the air heats up when reacting
		return REACTING

/datum/gas_reaction/nitrylformation //The formation of nitryl. Endothermic. Requires bz.
	priority = 3
	name = "Nitryl formation"
	id = "nitrylformation"

/datum/gas_reaction/nitrylformation/init_reqs()
	min_requirements = list(
		/datum/gas/oxygen = 10,
		/datum/gas/nitrogen = 10,
		/datum/gas/bz = 5,
		"TEMP" = 1500,
		"MAX_TEMP" = 10000
	)

/datum/gas_reaction/nitrylformation/react(datum/gas_mixture/air)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature

	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature / (FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 8), cached_gases[/datum/gas/oxygen][MOLES], cached_gases[/datum/gas/nitrogen][MOLES])
	var/energy_used = heat_efficency * NITRYL_FORMATION_ENERGY
	ASSERT_GAS(/datum/gas/nitryl, air)
	if ((cached_gases[/datum/gas/oxygen][MOLES] - heat_efficency < 0 ) || (cached_gases[/datum/gas/nitrogen][MOLES] - heat_efficency < 0) || (cached_gases[/datum/gas/bz][MOLES] - heat_efficency * 0.05 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/oxygen][MOLES] -= heat_efficency
	cached_gases[/datum/gas/nitrogen][MOLES] -= heat_efficency
	cached_gases[/datum/gas/bz][MOLES] -= heat_efficency * 0.05 //bz gets consumed to balance the nitryl production and not make it too common and/or easy
	cached_gases[/datum/gas/nitryl][MOLES] += heat_efficency

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity - energy_used) / new_heat_capacity), TCMB) //the air cools down when reacting
		return REACTING

/datum/gas_reaction/bzformation //Formation of BZ by combining plasma and tritium at low pressures. Exothermic.
	priority = 4
	name = "BZ Gas formation"
	id = "bzformation"

/datum/gas_reaction/bzformation/init_reqs()
	min_requirements = list(
		/datum/gas/nitrous_oxide = 10,
		/datum/gas/plasma = 10
	)


/datum/gas_reaction/bzformation/react(datum/gas_mixture/air)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/pressure = air.return_pressure()
	var/old_heat_capacity = air.heat_capacity()
	var/reaction_efficency = min(1 / ((pressure / (0.1 * ONE_ATMOSPHERE)) * (max(cached_gases[/datum/gas/plasma][MOLES] / cached_gases[/datum/gas/nitrous_oxide][MOLES], 1))), cached_gases[/datum/gas/nitrous_oxide][MOLES], cached_gases[/datum/gas/plasma][MOLES] * 0.5)
	var/energy_released = 2 * reaction_efficency * FIRE_CARBON_ENERGY_RELEASED
	if ((cached_gases[/datum/gas/nitrous_oxide][MOLES] - reaction_efficency < 0 )|| (cached_gases[/datum/gas/plasma][MOLES] - (2 * reaction_efficency) < 0) || energy_released <= 0) //Shouldn't produce gas from nothing.
		return NO_REACTION
	ASSERT_GAS(/datum/gas/bz, air)
	cached_gases[/datum/gas/bz][MOLES] += reaction_efficency * 2.5
	if(reaction_efficency == cached_gases[/datum/gas/nitrous_oxide][MOLES])
		ASSERT_GAS(/datum/gas/oxygen, air)
		cached_gases[/datum/gas/bz][MOLES] -= min(pressure,0.5)
		cached_gases[/datum/gas/oxygen][MOLES] += min(pressure,0.5)
	cached_gases[/datum/gas/nitrous_oxide][MOLES] -= reaction_efficency
	cached_gases[/datum/gas/plasma][MOLES]  -= 2 * reaction_efficency

	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, min((reaction_efficency**2) * BZ_RESEARCH_SCALE), BZ_RESEARCH_MAX_AMOUNT)

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity + energy_released) / new_heat_capacity), TCMB)
		return REACTING

/datum/gas_reaction/metalhydrogen
	priority = 27
	name = "Metal Hydrogen formation"
	id = "metalhydrogen"

/datum/gas_reaction/metalhydrogen/init_reqs()
	min_requirements = list(
		/datum/gas/hydrogen = 100,
		/datum/gas/bz		= 5,
		"TEMP" = METAL_HYDROGEN_MINIMUM_HEAT
		)

/datum/gas_reaction/metalhydrogen/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	if(!isturf(holder))
		return NO_REACTION
	var/turf/open/location = holder
	///the more heat you use the higher is this factor
	var/increase_factor = min((temperature / METAL_HYDROGEN_MINIMUM_HEAT), 5)
	///the more moles you use and the higher the heat, the higher is the efficiency
	var/heat_efficency = cached_gases[/datum/gas/hydrogen][MOLES] * 0.01 * increase_factor
	var/pressure = air.return_pressure()
	var/energy_used = heat_efficency * METAL_HYDROGEN_FORMATION_ENERGY

	if(pressure >= METAL_HYDROGEN_MINIMUM_PRESSURE && temperature >= METAL_HYDROGEN_MINIMUM_HEAT)
		cached_gases[/datum/gas/bz][MOLES] -= heat_efficency * 0.01
		if (prob(20 * increase_factor))
			cached_gases[/datum/gas/hydrogen][MOLES] -= heat_efficency * 3.5
			if (prob(100 / increase_factor))
				new /obj/item/stack/sheet/mineral/metal_hydrogen(location)
				SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, min((heat_efficency * increase_factor * 0.5), METAL_HYDROGEN_RESEARCH_MAX_AMOUNT))

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity - energy_used) / new_heat_capacity), TCMB)
		return REACTING

/datum/gas_reaction/freonformation
	priority = 5
	name = "Freon formation"
	id = "freonformation"

/datum/gas_reaction/freonformation/init_reqs() //minimum requirements for freon formation
	min_requirements = list(
		/datum/gas/plasma = 40,
		/datum/gas/carbon_dioxide = 20,
		/datum/gas/bz = 20,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100
		)

/datum/gas_reaction/freonformation/react(datum/gas_mixture/air)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature / (FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 10), cached_gases[/datum/gas/plasma][MOLES], cached_gases[/datum/gas/carbon_dioxide][MOLES], cached_gases[/datum/gas/bz][MOLES])
	var/energy_used = heat_efficency * 100
	ASSERT_GAS(/datum/gas/freon, air)
	if ((cached_gases[/datum/gas/plasma][MOLES] - heat_efficency * 1.5 < 0 ) || (cached_gases[/datum/gas/carbon_dioxide][MOLES] - heat_efficency * 0.75 < 0) || (cached_gases[/datum/gas/bz][MOLES] - heat_efficency * 0.25 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/plasma][MOLES] -= heat_efficency * 1.5
	cached_gases[/datum/gas/carbon_dioxide][MOLES] -= heat_efficency * 0.75
	cached_gases[/datum/gas/bz][MOLES] -= heat_efficency * 0.25
	cached_gases[/datum/gas/freon][MOLES] += heat_efficency * 2.5

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity - energy_used)/new_heat_capacity), TCMB)
		return REACTING

/datum/gas_reaction/stimformation //Stimulum formation follows a strange pattern of how effective it will be at a given temperature, having some multiple peaks and some large dropoffs. Exo and endo thermic.
	priority = 5
	name = "Stimulum formation"
	id = "stimformation"

/datum/gas_reaction/stimformation/init_reqs()
	min_requirements = list(
		/datum/gas/tritium = 30,
		/datum/gas/bz = 20,
		/datum/gas/nitryl = 30,
		"TEMP" = 1500)

/datum/gas_reaction/stimformation/react(datum/gas_mixture/air)
	var/list/cached_gases = air.gases

	var/old_heat_capacity = air.heat_capacity()
	var/heat_scale = min(air.temperature/STIMULUM_HEAT_SCALE,cached_gases[/datum/gas/tritium][MOLES],cached_gases[/datum/gas/plasma][MOLES],cached_gases[/datum/gas/nitryl][MOLES])
	var/stim_energy_change = heat_scale + STIMULUM_FIRST_RISE*(heat_scale**2) - STIMULUM_FIRST_DROP*(heat_scale**3) + STIMULUM_SECOND_RISE*(heat_scale**4) - STIMULUM_ABSOLUTE_DROP*(heat_scale**5)
	ASSERT_GAS(/datum/gas/stimulum, air)
	if ((cached_gases[/datum/gas/tritium][MOLES] - heat_scale < 0 ) || (cached_gases[/datum/gas/nitryl][MOLES] - heat_scale < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/stimulum][MOLES]+= heat_scale * 0.75
	cached_gases[/datum/gas/tritium][MOLES] -= heat_scale
	cached_gases[/datum/gas/nitryl][MOLES] -= heat_scale
	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, STIMULUM_RESEARCH_AMOUNT * max(stim_energy_change, 0))
	if(stim_energy_change)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((air.temperature * old_heat_capacity + stim_energy_change) / new_heat_capacity), TCMB)
		return REACTING

/datum/gas_reaction/nobliumformation //Hyper-Noblium formation is extrememly endothermic, but requires high temperatures to start. Due to its high mass, hyper-nobelium uses large amounts of nitrogen and tritium. BZ can be used as a catalyst to make it less endothermic.
	priority = 6
	name = "Hyper-Noblium condensation"
	id = "nobformation"

/datum/gas_reaction/nobliumformation/init_reqs()
	min_requirements = list(
		/datum/gas/nitrogen = 10,
		/datum/gas/tritium = 5,
		"TEMP" = 50000)

/datum/gas_reaction/nobliumformation/react(datum/gas_mixture/air)
	var/list/cached_gases = air.gases
	air.assert_gases(/datum/gas/hypernoblium, /datum/gas/bz)
	var/old_heat_capacity = air.heat_capacity()
	var/nob_formed = min((cached_gases[/datum/gas/nitrogen][MOLES] + cached_gases[/datum/gas/tritium][MOLES]) * 0.01, cached_gases[/datum/gas/tritium][MOLES] * 0.1, cached_gases[/datum/gas/nitrogen][MOLES] * 0.2)
	var/energy_taken = nob_formed * (NOBLIUM_FORMATION_ENERGY / (max(cached_gases[/datum/gas/bz][MOLES], 1)))
	if ((cached_gases[/datum/gas/tritium][MOLES] - 5 * nob_formed < 0) || (cached_gases[/datum/gas/nitrogen][MOLES] - 10 * nob_formed < 0))
		return NO_REACTION
	cached_gases[/datum/gas/tritium][MOLES] -= nob_formed * 5
	cached_gases[/datum/gas/nitrogen][MOLES] -= nob_formed * 10
	cached_gases[/datum/gas/hypernoblium][MOLES] += nob_formed
	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, nob_formed * NOBLIUM_RESEARCH_AMOUNT)

	if (nob_formed)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((air.temperature * old_heat_capacity - energy_taken) / new_heat_capacity), TCMB)


/datum/gas_reaction/miaster	//dry heat sterilization: clears out pathogens in the air
	priority = -10 //after all the heating from fires etc. is done
	name = "Dry Heat Sterilization"
	id = "sterilization"

/datum/gas_reaction/miaster/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST+70,
		/datum/gas/miasma = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/miaster/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	// As the name says it, it needs to be dry
	if(cached_gases[/datum/gas/water_vapor] && cached_gases[/datum/gas/water_vapor][MOLES] / air.total_moles() > 0.1)
		return

	//Replace miasma with oxygen
	var/cleaned_air = min(cached_gases[/datum/gas/miasma][MOLES], 20 + (air.temperature - FIRE_MINIMUM_TEMPERATURE_TO_EXIST - 70) / 20)
	cached_gases[/datum/gas/miasma][MOLES] -= cleaned_air
	ASSERT_GAS(/datum/gas/oxygen, air)
	cached_gases[/datum/gas/oxygen][MOLES] += cleaned_air

	//Possibly burning a bit of organic matter through maillard reaction, so a *tiny* bit more heat would be understandable
	air.temperature += cleaned_air * 0.002

/datum/gas_reaction/stim_ball
	priority = 7
	name ="Stimulum Energy Ball"
	id = "stimball"

/datum/gas_reaction/stim_ball/init_reqs()
	min_requirements = list(
		/datum/gas/pluoxium = STIM_BALL_GAS_AMOUNT,
		/datum/gas/stimulum = STIM_BALL_GAS_AMOUNT,
		/datum/gas/nitryl = MINIMUM_MOLE_COUNT,
		/datum/gas/plasma = MINIMUM_MOLE_COUNT,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	)
/datum/gas_reaction/stim_ball/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/turf/open/location
	var/old_heat_capacity = air.heat_capacity()
	if(istype(holder,/datum/pipeline)) //Find the tile the reaction is occuring on, or a random part of the network if it's a pipenet.
		var/datum/pipeline/pipenet = holder
		location = get_turf(pick(pipenet.members))
	else
		location = get_turf(holder)
	air.assert_gases(/datum/gas/water_vapor, /datum/gas/nitryl, /datum/gas/carbon_dioxide, /datum/gas/nitrogen)
	var/ball_shot_angle = 180 * cos(cached_gases[/datum/gas/water_vapor][MOLES] / cached_gases[/datum/gas/nitryl][MOLES]) + 180
	var/stim_used = min(STIM_BALL_GAS_AMOUNT / cached_gases[/datum/gas/plasma][MOLES], cached_gases[/datum/gas/stimulum][MOLES])
	var/pluox_used = min(STIM_BALL_GAS_AMOUNT / cached_gases[/datum/gas/plasma][MOLES], cached_gases[/datum/gas/pluoxium][MOLES])
	if ((cached_gases[/datum/gas/pluoxium][MOLES] - pluox_used < 0 ) || (cached_gases[/datum/gas/stimulum][MOLES] - stim_used < 0) || (cached_gases[/datum/gas/plasma][MOLES] - min(stim_used * pluox_used, 30) < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	var/energy_released = stim_used * STIMULUM_HEAT_SCALE//Stimulum has a lot of stored energy, and breaking it up releases some of it
	location.fire_nuclear_particle(ball_shot_angle)
	cached_gases[/datum/gas/carbon_dioxide][MOLES] += 0.5 * pluox_used
	cached_gases[/datum/gas/nitrogen][MOLES] += 2 * stim_used
	cached_gases[/datum/gas/pluoxium][MOLES] -= pluox_used
	cached_gases[/datum/gas/stimulum][MOLES] -= stim_used
	cached_gases[/datum/gas/plasma][MOLES] -= min(stim_used * pluox_used, 30)
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = clamp((air.temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB, INFINITY)
		return REACTING

/datum/gas_reaction/halon_formation
	priority = 15
	name = "Halon formation"
	id = "halon_formation"

/datum/gas_reaction/halon_formation/init_reqs()
	min_requirements = list(
		/datum/gas/bz = MINIMUM_MOLE_COUNT,
		/datum/gas/tritium = MINIMUM_MOLE_COUNT,
		"TEMP" = 30,
		"MAX_TEMP" = 55
	)

/datum/gas_reaction/halon_formation/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.01, cached_gases[/datum/gas/tritium][MOLES], cached_gases[/datum/gas/bz][MOLES])
	var/energy_used = heat_efficency * 300
	ASSERT_GAS(/datum/gas/halon, air)
	if ((cached_gases[/datum/gas/tritium][MOLES] - heat_efficency * 4 < 0 ) || (cached_gases[/datum/gas/bz][MOLES] - heat_efficency * 0.25 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/tritium][MOLES] -= heat_efficency * 4
	cached_gases[/datum/gas/bz][MOLES] -= heat_efficency * 0.25
	cached_gases[/datum/gas/halon][MOLES] += heat_efficency * 4.25

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity), TCMB)
	return REACTING

/datum/gas_reaction/hexane_formation
	priority = 16
	name = "Hexane formation"
	id = "hexane_formation"

/datum/gas_reaction/hexane_formation/init_reqs()
	min_requirements = list(
		/datum/gas/bz = MINIMUM_MOLE_COUNT,
		/datum/gas/hydrogen = MINIMUM_MOLE_COUNT,
		"TEMP" = 450,
		"MAX_TEMP" = 465
	)

/datum/gas_reaction/hexane_formation/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.01, cached_gases[/datum/gas/hydrogen][MOLES], cached_gases[/datum/gas/bz][MOLES])
	var/energy_used = heat_efficency * 600
	ASSERT_GAS(/datum/gas/hexane, air)
	if ((cached_gases[/datum/gas/hydrogen][MOLES] - heat_efficency * 5 < 0 ) || (cached_gases[/datum/gas/bz][MOLES] - heat_efficency * 0.25 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/hydrogen][MOLES] -= heat_efficency * 5
	cached_gases[/datum/gas/bz][MOLES] -= heat_efficency * 0.25
	cached_gases[/datum/gas/hexane][MOLES] += heat_efficency * 5.25

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity - energy_used) / new_heat_capacity), TCMB)
	return REACTING

/datum/gas_reaction/healium_formation
	priority = 12
	name = "Healium formation"
	id = "healium_formation"

/datum/gas_reaction/healium_formation/init_reqs()
	min_requirements = list(
		/datum/gas/bz = MINIMUM_MOLE_COUNT,
		/datum/gas/freon = MINIMUM_MOLE_COUNT,
		"TEMP" = 25,
		"MAX_TEMP" = 300
	)

/datum/gas_reaction/healium_formation/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.3, cached_gases[/datum/gas/freon][MOLES], cached_gases[/datum/gas/bz][MOLES])
	var/energy_used = heat_efficency * 9000
	ASSERT_GAS(/datum/gas/healium, air)
	if ((cached_gases[/datum/gas/freon][MOLES] - heat_efficency * 2.75 < 0 ) || (cached_gases[/datum/gas/bz][MOLES] - heat_efficency * 0.25 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/freon][MOLES] -= heat_efficency * 2.75
	cached_gases[/datum/gas/bz][MOLES] -= heat_efficency * 0.25
	cached_gases[/datum/gas/healium][MOLES] += heat_efficency * 3

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity), TCMB)
	return REACTING

/datum/gas_reaction/proto_nitrate_formation
	priority = 13
	name = "Proto Nitrate formation"
	id = "proto_nitrate_formation"

/datum/gas_reaction/proto_nitrate_formation/init_reqs()
	min_requirements = list(
		/datum/gas/pluoxium = MINIMUM_MOLE_COUNT,
		/datum/gas/hydrogen = MINIMUM_MOLE_COUNT,
		"TEMP" = 5000,
		"MAX_TEMP" = 10000
	)

/datum/gas_reaction/proto_nitrate_formation/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.005, cached_gases[/datum/gas/pluoxium][MOLES], cached_gases[/datum/gas/hydrogen][MOLES])
	var/energy_used = heat_efficency * 650
	ASSERT_GAS(/datum/gas/proto_nitrate, air)
	if ((cached_gases[/datum/gas/pluoxium][MOLES] - heat_efficency * 0.2 < 0 ) || (cached_gases[/datum/gas/hydrogen][MOLES] - heat_efficency * 2 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/hydrogen][MOLES] -= heat_efficency * 2
	cached_gases[/datum/gas/pluoxium][MOLES] -= heat_efficency * 0.2
	cached_gases[/datum/gas/proto_nitrate][MOLES] += heat_efficency * 2.2

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity), TCMB)
	return REACTING

/datum/gas_reaction/zauker_formation
	priority = 14
	name = "Zauker formation"
	id = "zauker_formation"

/datum/gas_reaction/zauker_formation/init_reqs()
	min_requirements = list(
		/datum/gas/hypernoblium = MINIMUM_MOLE_COUNT,
		/datum/gas/stimulum = MINIMUM_MOLE_COUNT,
		"TEMP" = 50000,
		"MAX_TEMP" = 75000
	)

/datum/gas_reaction/zauker_formation/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.000005, cached_gases[/datum/gas/hypernoblium][MOLES], cached_gases[/datum/gas/stimulum][MOLES])
	var/energy_used = heat_efficency * 5000
	ASSERT_GAS(/datum/gas/zauker, air)
	if ((cached_gases[/datum/gas/hypernoblium][MOLES] - heat_efficency * 0.01 < 0 ) || (cached_gases[/datum/gas/stimulum][MOLES] - heat_efficency * 0.5 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/hypernoblium][MOLES] -= heat_efficency * 0.01
	cached_gases[/datum/gas/stimulum][MOLES] -= heat_efficency * 0.5
	cached_gases[/datum/gas/zauker][MOLES] += heat_efficency * 0.5

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity - energy_used) / new_heat_capacity), TCMB)
	return REACTING

/datum/gas_reaction/halon_o2removal
	priority = -1
	name = "Halon o2 removal"
	id = "halon_o2removal"

/datum/gas_reaction/halon_o2removal/init_reqs()
	min_requirements = list(
		/datum/gas/halon = MINIMUM_MOLE_COUNT,
		/datum/gas/oxygen = MINIMUM_MOLE_COUNT,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	)

/datum/gas_reaction/halon_o2removal/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature / ( FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 10), cached_gases[/datum/gas/halon][MOLES], cached_gases[/datum/gas/oxygen][MOLES])
	var/energy_used = heat_efficency * 2500
	ASSERT_GAS(/datum/gas/carbon_dioxide, air)
	if ((cached_gases[/datum/gas/halon][MOLES] - heat_efficency < 0 ) || (cached_gases[/datum/gas/oxygen][MOLES] - heat_efficency * 20 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/halon][MOLES] -= heat_efficency
	cached_gases[/datum/gas/oxygen][MOLES] -= heat_efficency * 20
	cached_gases[/datum/gas/carbon_dioxide][MOLES] += heat_efficency * 5

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity - energy_used) / new_heat_capacity), TCMB)
	return REACTING

/datum/gas_reaction/hexane_plasma_filtering
	priority = 9
	name = "Hexane plasma filtering"
	id = "hexane_plasma_filtering"

/datum/gas_reaction/hexane_plasma_filtering/init_reqs()
	min_requirements = list(
		/datum/gas/hexane = MINIMUM_MOLE_COUNT,
		/datum/gas/plasma = MINIMUM_MOLE_COUNT,
		"TEMP" = 150
	)

/datum/gas_reaction/hexane_plasma_filtering/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.01, cached_gases[/datum/gas/hexane][MOLES], cached_gases[/datum/gas/plasma][MOLES])
	var/energy_used = heat_efficency * 250
	ASSERT_GAS(/datum/gas/carbon_dioxide, air)
	if ((cached_gases[/datum/gas/hexane][MOLES] - heat_efficency * 0.2 < 0 ) || (cached_gases[/datum/gas/plasma][MOLES] - heat_efficency * 0.5 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/hexane][MOLES] -= heat_efficency * 0.2
	cached_gases[/datum/gas/plasma][MOLES] -= heat_efficency * 0.5
	cached_gases[/datum/gas/carbon_dioxide][MOLES] += heat_efficency * 0.4

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity - energy_used) / new_heat_capacity), TCMB)
	return REACTING

/datum/gas_reaction/hexane_n2o_filtering
	priority = 10
	name = "Hexane n2o filtering"
	id = "hexane_n2o_filtering"

/datum/gas_reaction/hexane_n2o_filtering/init_reqs()
	min_requirements = list(
		/datum/gas/hexane = MINIMUM_MOLE_COUNT,
		/datum/gas/nitrous_oxide = MINIMUM_MOLE_COUNT,
	)

/datum/gas_reaction/hexane_n2o_filtering/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.01, cached_gases[/datum/gas/hexane][MOLES], cached_gases[/datum/gas/nitrous_oxide][MOLES])
	var/energy_used = heat_efficency * 100
	ASSERT_GAS(/datum/gas/oxygen, air)
	ASSERT_GAS(/datum/gas/nitrogen, air)
	if ((cached_gases[/datum/gas/hexane][MOLES] - heat_efficency * 0.2 < 0 ) || (cached_gases[/datum/gas/nitrous_oxide][MOLES] - heat_efficency * 0.5 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/hexane][MOLES] -= heat_efficency * 0.2
	cached_gases[/datum/gas/nitrous_oxide][MOLES] -= heat_efficency * 0.6
	cached_gases[/datum/gas/oxygen][MOLES] += heat_efficency * 0.2
	cached_gases[/datum/gas/nitrogen][MOLES] += heat_efficency * 0.6

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity), TCMB)
	return REACTING

/datum/gas_reaction/zauker_decomp
	priority = 11
	name = "Zauker decomposition"
	id = "zauker_decomp"

/datum/gas_reaction/zauker_decomp/init_reqs()
	min_requirements = list(
		/datum/gas/nitrogen = MINIMUM_MOLE_COUNT,
		/datum/gas/zauker = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/zauker_decomp/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases //this speeds things up because accessing datum vars is slow
	var/temperature = air.temperature
	var/burned_fuel = 0
	burned_fuel = min(20, cached_gases[/datum/gas/nitrogen][MOLES], cached_gases[/datum/gas/zauker][MOLES])
	if(cached_gases[/datum/gas/zauker][MOLES] - burned_fuel < 0)
		return NO_REACTION
	cached_gases[/datum/gas/zauker][MOLES] -= burned_fuel

	if(burned_fuel)
		energy_released += (460 * burned_fuel)

		ASSERT_GAS(/datum/gas/oxygen, air)
		ASSERT_GAS(/datum/gas/nitrogen, air)
		cached_gases[/datum/gas/oxygen][MOLES] += burned_fuel * 0.3
		cached_gases[/datum/gas/nitrogen][MOLES] += burned_fuel * 0.7

		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
		return REACTING
	return NO_REACTION

/datum/gas_reaction/healium_crystal_formation
	priority = 17
	name = "healium crystal formation"
	id = "healium_crystal_formation"

/datum/gas_reaction/healium_crystal_formation/init_reqs()
	min_requirements = list(
		/datum/gas/oxygen = 50,
		/datum/gas/healium = 10,
		"TEMP" = 1000,
		"MAX_TEMP" = 2500
	)

/datum/gas_reaction/healium_crystal_formation/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	if(!isturf(holder))
		return NO_REACTION
	var/turf/open/location = holder
	var/consumed_fuel = 0
	consumed_fuel = min(cached_gases[/datum/gas/healium][MOLES] * 2.5, 20 * (temperature * 0.001))
	if ((cached_gases[/datum/gas/healium][MOLES] - consumed_fuel * 0.4 < 0 ) || (cached_gases[/datum/gas/oxygen][MOLES] - consumed_fuel * 0.1 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/oxygen][MOLES] -= consumed_fuel * 0.1
	cached_gases[/datum/gas/healium][MOLES] -= consumed_fuel * 0.4
	if(prob(2 * consumed_fuel))
		new /obj/item/grenade/gas_crystal/healium_crystal(location)
	energy_released += consumed_fuel * 800
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
	return REACTING

/datum/gas_reaction/proto_nitrate_crystal_formation
	priority = 18
	name = "hydrogen pluoxide crystal formation"
	id = "proto_nitrate_crystal_formation"

/datum/gas_reaction/proto_nitrate_crystal_formation/init_reqs()
	min_requirements = list(
		/datum/gas/nitrogen = 50,
		/datum/gas/proto_nitrate = 10,
		"TEMP" = 100,
		"MAX_TEMP" = 150
	)

/datum/gas_reaction/proto_nitrate_crystal_formation/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	if(!isturf(holder))
		return NO_REACTION
	var/turf/open/location = holder
	var/consumed_fuel = 0
	consumed_fuel = min(cached_gases[/datum/gas/proto_nitrate][MOLES] * 0.15, 20 * (temperature * 0.01))
	if ((cached_gases[/datum/gas/proto_nitrate][MOLES] - consumed_fuel * 0.15 < 0 ) || (cached_gases[/datum/gas/nitrogen][MOLES] - consumed_fuel * 0.01 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/nitrogen][MOLES] -= consumed_fuel * 0.01
	cached_gases[/datum/gas/proto_nitrate][MOLES] -= consumed_fuel * 0.15
	if(prob(5 * consumed_fuel))
		new /obj/item/grenade/gas_crystal/proto_nitrate_crystal(location)
	energy_released += consumed_fuel * 800
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
	return REACTING

/datum/gas_reaction/zauker_crystal_formation
	priority = 19
	name = "zauker crystal formation"
	id = "zauker_crystal_formation"

/datum/gas_reaction/zauker_crystal_formation/init_reqs()
	min_requirements = list(
		/datum/gas/plasma = 50,
		/datum/gas/zauker = 10,
		"TEMP" = 270,
		"MAX_TEMP" = 280
	)

/datum/gas_reaction/zauker_crystal_formation/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	if(!isturf(holder))
		return NO_REACTION
	var/turf/open/location = holder
	var/consumed_fuel = 0
	consumed_fuel = min(cached_gases[/datum/gas/zauker][MOLES] * 0.1, 20 * (temperature * 0.02))
	if ((cached_gases[/datum/gas/zauker][MOLES] - consumed_fuel * 0.05 < 0 ) || (cached_gases[/datum/gas/plasma][MOLES] - consumed_fuel * 5 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	cached_gases[/datum/gas/plasma][MOLES] -= consumed_fuel * 5
	cached_gases[/datum/gas/zauker][MOLES] -= consumed_fuel * 0.05
	if(prob(10 * consumed_fuel))
		new /obj/item/grenade/gas_crystal/zauker_crystal(location)
	energy_released += consumed_fuel * 800
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
	return REACTING

/datum/gas_reaction/proto_nitrate_plasma_response
	priority = 20
	name = "Proto Nitrate plasma response"
	id = "proto_nitrate_plasma_response"

/datum/gas_reaction/proto_nitrate_plasma_response/init_reqs()
	min_requirements = list(
		/datum/gas/proto_nitrate = MINIMUM_MOLE_COUNT,
		/datum/gas/plasma = MINIMUM_MOLE_COUNT,
		"TEMP" = 250,
		"MAX_TEMP" = 300
	)

/datum/gas_reaction/proto_nitrate_plasma_response/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	if(!isturf(holder))
		return NO_REACTION
	var/turf/open/location = holder
	if(cached_gases[/datum/gas/plasma][MOLES] > 10)
		return NO_REACTION
	var produced_amount = min(5, cached_gases[/datum/gas/plasma][MOLES], cached_gases[/datum/gas/proto_nitrate][MOLES])
	if(cached_gases[/datum/gas/plasma][MOLES] - produced_amount < 0 || cached_gases[/datum/gas/proto_nitrate][MOLES] - produced_amount * 0.1 < 0)
		return NO_REACTION
	cached_gases[/datum/gas/plasma][MOLES] -= produced_amount
	cached_gases[/datum/gas/proto_nitrate][MOLES] -= produced_amount * 0.1
	energy_released -= produced_amount * 1500
	if(prob(produced_amount * 15))
		new/obj/item/stack/sheet/mineral/plasma(location)
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
	return REACTING

/datum/gas_reaction/proto_nitrate_bz_response
	priority = 21
	name = "Proto Nitrate bz response"
	id = "proto_nitrate_bz_response"

/datum/gas_reaction/proto_nitrate_bz_response/init_reqs()
	min_requirements = list(
		/datum/gas/proto_nitrate = MINIMUM_MOLE_COUNT,
		/datum/gas/bz = MINIMUM_MOLE_COUNT,
		"TEMP" = 260,
		"MAX_TEMP" = 280
	)

/datum/gas_reaction/proto_nitrate_bz_response/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/turf/open/location
	if(istype(holder,/datum/pipeline)) //Find the tile the reaction is occuring on, or a random part of the network if it's a pipenet.
		var/datum/pipeline/pipenet = holder
		location = get_turf(pick(pipenet.members))
	else
		location = get_turf(holder)
	var consumed_amount = min(5, cached_gases[/datum/gas/bz][MOLES], cached_gases[/datum/gas/proto_nitrate][MOLES])
	if(cached_gases[/datum/gas/bz][MOLES] - consumed_amount < 0)
		return NO_REACTION
	if(cached_gases[/datum/gas/bz][MOLES] < 30)
		radiation_pulse(location, consumed_amount * 20, 2.5, TRUE, FALSE)
		cached_gases[/datum/gas/bz][MOLES] -= consumed_amount
	else
		for(var/mob/living/carbon/L in location)
			L.hallucination += cached_gases[/datum/gas/bz][MOLES] * 0.7
	energy_released += 100
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
	return REACTING

/datum/gas_reaction/proto_nitrate_freon_fire_response
	priority = 22
	name = "Proto Nitrate freon fire response"
	id = "proto_nitrate_freon_fire_response"

/datum/gas_reaction/proto_nitrate_freon_fire_response/init_reqs()
	min_requirements = list(
		/datum/gas/proto_nitrate = MINIMUM_MOLE_COUNT,
		/datum/gas/freon = MINIMUM_MOLE_COUNT,
		/datum/gas/oxygen = MINIMUM_MOLE_COUNT,
		"TEMP" = 270,
		"MAX_TEMP" = 310
	)

/datum/gas_reaction/proto_nitrate_freon_fire_response/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	if(cached_gases[/datum/gas/freon][MOLES] > 100 && cached_gases[/datum/gas/oxygen][MOLES] > 100)
		var fuel_consumption = min(5, temperature * 0.03, cached_gases[/datum/gas/freon][MOLES], cached_gases[/datum/gas/proto_nitrate][MOLES])
		if(cached_gases[/datum/gas/proto_nitrate][MOLES] - fuel_consumption < 0)
			return NO_REACTION
		cached_gases[/datum/gas/proto_nitrate][MOLES] -= fuel_consumption
		cached_gases[/datum/gas/freon][MOLES] += fuel_consumption * 0.01
		energy_released -= fuel_consumption * 1500
		if(energy_released)
			var/new_heat_capacity = air.heat_capacity()
			if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
				air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
		return REACTING
	return NO_REACTION

/datum/gas_reaction/proto_nitrate_tritium_response
	priority = 23
	name = "Proto Nitrate tritium response"
	id = "proto_nitrate_tritium_response"

/datum/gas_reaction/proto_nitrate_tritium_response/init_reqs()
	min_requirements = list(
		/datum/gas/proto_nitrate = MINIMUM_MOLE_COUNT,
		/datum/gas/tritium = MINIMUM_MOLE_COUNT,
		"TEMP" = 150,
		"MAX_TEMP" = 340
	)

/datum/gas_reaction/proto_nitrate_tritium_response/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var/turf/open/location = isturf(holder) ? holder : null
	var produced_amount = min(5, cached_gases[/datum/gas/tritium][MOLES], cached_gases[/datum/gas/proto_nitrate][MOLES])
	if(cached_gases[/datum/gas/tritium][MOLES] - produced_amount < 0 || cached_gases[/datum/gas/proto_nitrate][MOLES] - produced_amount * 0.01 < 0)
		return NO_REACTION
	location.rad_act(produced_amount * 2.4)
	cached_gases[/datum/gas/tritium][MOLES] -= produced_amount
	cached_gases[/datum/gas/hydrogen][MOLES] += produced_amount
	cached_gases[/datum/gas/proto_nitrate][MOLES] -= produced_amount * 0.01
	energy_released += 50
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
	return REACTING

/datum/gas_reaction/proto_nitrate_hydrogen_response
	priority = 24
	name = "Proto Nitrate hydrogen response"
	id = "proto_nitrate_hydrogen_response"

/datum/gas_reaction/proto_nitrate_hydrogen_response/init_reqs()
	min_requirements = list(
		/datum/gas/proto_nitrate = MINIMUM_MOLE_COUNT,
		/datum/gas/hydrogen = 150,
	)

/datum/gas_reaction/proto_nitrate_hydrogen_response/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var produced_amount = min(5, cached_gases[/datum/gas/hydrogen][MOLES], cached_gases[/datum/gas/proto_nitrate][MOLES])
	if(cached_gases[/datum/gas/hydrogen][MOLES] - produced_amount < 0)
		return NO_REACTION
	cached_gases[/datum/gas/hydrogen][MOLES] -= produced_amount
	cached_gases[/datum/gas/proto_nitrate][MOLES] += produced_amount * 0.5
	energy_released -= produced_amount * 2500
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
	return REACTING

/datum/gas_reaction/proto_nitrate_zauker_response
	priority = 25
	name = "Proto Nitrate Zauker response"
	id = "proto_nitrate_zauker_response"

/datum/gas_reaction/proto_nitrate_zauker_response/init_reqs()
	min_requirements = list(
		/datum/gas/proto_nitrate = MINIMUM_MOLE_COUNT,
		/datum/gas/zauker = MINIMUM_MOLE_COUNT,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	)

/datum/gas_reaction/proto_nitrate_zauker_response/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/turf/open/location = isturf(holder) ? holder : null
	var max_power = min(5, cached_gases[/datum/gas/zauker][MOLES])
	cached_gases[/datum/gas/zauker][MOLES] = 0
	explosion(location, max_power * 0.55, max_power * 0.95, max_power * 1.25, max_power* 3)
	return REACTING

/datum/gas_reaction/pluox_formation
	priority = 2
	name = "Pluoxium formation"
	id = "pluox_formation"

/datum/gas_reaction/pluox_formation/init_reqs()
	min_requirements = list(
		/datum/gas/carbon_dioxide = MINIMUM_MOLE_COUNT,
		/datum/gas/oxygen = MINIMUM_MOLE_COUNT,
		/datum/gas/tritium = MINIMUM_MOLE_COUNT,
		"TEMP" = 50,
		"MAX_TEMP" = T0C
	)

/datum/gas_reaction/pluox_formation/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/temperature = air.temperature
	var produced_amount = min(5, cached_gases[/datum/gas/carbon_dioxide][MOLES], cached_gases[/datum/gas/oxygen][MOLES])
	if(cached_gases[/datum/gas/carbon_dioxide][MOLES] - produced_amount < 0 || cached_gases[/datum/gas/oxygen][MOLES] - produced_amount * 0.5 < 0 || cached_gases[/datum/gas/tritium][MOLES] - produced_amount * 0.01 < 0)
		return NO_REACTION
	cached_gases[/datum/gas/carbon_dioxide][MOLES] -= produced_amount
	cached_gases[/datum/gas/oxygen][MOLES] -= produced_amount * 0.5
	cached_gases[/datum/gas/tritium][MOLES] -= produced_amount * 0.01
	ASSERT_GAS(/datum/gas/pluoxium, air)
	cached_gases[/datum/gas/pluoxium][MOLES] += produced_amount
	ASSERT_GAS(/datum/gas/hydrogen, air)
	cached_gases[/datum/gas/hydrogen][MOLES] += produced_amount * 0.01
	energy_released += produced_amount * 250
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity
	return REACTING

// BEGIN
/datum/gas_reaction/libital
    priority = 1
    name = "libital"
    id = "libital"


/datum/gas_reaction/libital/init_reqs()
	min_requirements = list(
		/datum/gas/phenol = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/nitrogen = 1
	)


/datum/gas_reaction/libital/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/phenol) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/nitrogen)
	remove_air = air.get_moles(/datum/gas/phenol)
	air.adjust_moles(/datum/gas/phenol, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	air.adjust_moles(/datum/gas/libital, cleaned_air)

/datum/gas_reaction/probital
    priority = 1
    name = "probital"
    id = "probital"


/datum/gas_reaction/probital/init_reqs()
	min_requirements = list(
		/datum/gas/copper = 1,
		/datum/gas/acetone = 1,
		/datum/gas/phosphorus = 1
	)


/datum/gas_reaction/probital/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/copper) + air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/phosphorus)
	remove_air = air.get_moles(/datum/gas/copper)
	air.adjust_moles(/datum/gas/copper, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/phosphorus)
	air.adjust_moles(/datum/gas/phosphorus, -remove_air)
	air.adjust_moles(/datum/gas/probital, cleaned_air)

/datum/gas_reaction/lenturi
    priority = 1
    name = "lenturi"
    id = "lenturi"


/datum/gas_reaction/lenturi/init_reqs()
	min_requirements = list(
		/datum/gas/ammonia = 1,
		/datum/gas/silver = 1,
		/datum/gas/sulfur = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/chlorine = 1
	)


/datum/gas_reaction/lenturi/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/silver) + air.get_moles(/datum/gas/sulfur) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/chlorine)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/silver)
	air.adjust_moles(/datum/gas/silver, -remove_air)
	remove_air = air.get_moles(/datum/gas/sulfur)
	air.adjust_moles(/datum/gas/sulfur, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	air.adjust_moles(/datum/gas/lenturi, cleaned_air)

/datum/gas_reaction/aiuri
    priority = 1
    name = "aiuri"
    id = "aiuri"


/datum/gas_reaction/aiuri/init_reqs()
	min_requirements = list(
		/datum/gas/ammonia = 1,
		/datum/gas/acid = 1,
		/datum/gas/hydrogen = 1
	)


/datum/gas_reaction/aiuri/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/acid) + air.get_moles(/datum/gas/hydrogen)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	air.adjust_moles(/datum/gas/aiuri, cleaned_air)

/datum/gas_reaction/hercuri
    priority = 1
    name = "hercuri"
    id = "hercuri"


/datum/gas_reaction/hercuri/init_reqs()
	min_requirements = list(
		/datum/gas/cryostylane = 3,
		/datum/gas/bromine = 3,
		/datum/gas/lye = 3,
		"TEMP" = 47)

/datum/gas_reaction/hercuri/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/cryostylane) + air.get_moles(/datum/gas/bromine) + air.get_moles(/datum/gas/lye)
	remove_air = air.get_moles(/datum/gas/cryostylane)
	air.adjust_moles(/datum/gas/cryostylane, -remove_air)
	remove_air = air.get_moles(/datum/gas/bromine)
	air.adjust_moles(/datum/gas/bromine, -remove_air)
	remove_air = air.get_moles(/datum/gas/lye)
	air.adjust_moles(/datum/gas/lye, -remove_air)
	air.adjust_moles(/datum/gas/hercuri, cleaned_air)

/datum/gas_reaction/convermol
    priority = 1
    name = "convermol"
    id = "convermol"


/datum/gas_reaction/convermol/init_reqs()
	min_requirements = list(
		/datum/gas/hydrogen = 1,
		/datum/gas/fluorine = 1,
		/datum/gas/oil = 1,
		"TEMP" = 370)

/datum/gas_reaction/convermol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/fluorine) + air.get_moles(/datum/gas/oil)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/fluorine)
	air.adjust_moles(/datum/gas/fluorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	air.adjust_moles(/datum/gas/convermol, cleaned_air)

/datum/gas_reaction/tirimol
    priority = 1
    name = "tirimol"
    id = "tirimol"


/datum/gas_reaction/tirimol/init_reqs()
	min_requirements = list(
		/datum/gas/nitrogen = 3,
		/datum/gas/acetone = 3
	)


/datum/gas_reaction/tirimol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/nitrogen) + air.get_moles(/datum/gas/acetone)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	air.adjust_moles(/datum/gas/tirimol, cleaned_air)

/datum/gas_reaction/seiver
    priority = 1
    name = "seiver"
    id = "seiver"


/datum/gas_reaction/seiver/init_reqs()
	min_requirements = list(
		/datum/gas/nitrogen = 1,
		/datum/gas/potassium = 1,
		/datum/gas/aluminium = 1
	)


/datum/gas_reaction/seiver/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/nitrogen) + air.get_moles(/datum/gas/potassium) + air.get_moles(/datum/gas/aluminium)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/potassium)
	air.adjust_moles(/datum/gas/potassium, -remove_air)
	remove_air = air.get_moles(/datum/gas/aluminium)
	air.adjust_moles(/datum/gas/aluminium, -remove_air)
	air.adjust_moles(/datum/gas/seiver, cleaned_air)

/datum/gas_reaction/multiver
    priority = 1
    name = "multiver"
    id = "multiver"


/datum/gas_reaction/multiver/init_reqs()
	min_requirements = list(
		/datum/gas/ash = 1,
		/datum/gas/sodiumchloride = 1,
		"TEMP" = 380)

/datum/gas_reaction/multiver/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ash) + air.get_moles(/datum/gas/sodiumchloride)
	remove_air = air.get_moles(/datum/gas/ash)
	air.adjust_moles(/datum/gas/ash, -remove_air)
	remove_air = air.get_moles(/datum/gas/sodiumchloride)
	air.adjust_moles(/datum/gas/sodiumchloride, -remove_air)
	air.adjust_moles(/datum/gas/multiver, cleaned_air)

/datum/gas_reaction/syriniver
    priority = 1
    name = "syriniver"
    id = "syriniver"


/datum/gas_reaction/syriniver/init_reqs()
	min_requirements = list(
		/datum/gas/sulfur = 1,
		/datum/gas/fluorine = 1,
		/datum/gas/toxin = 1,
		/datum/gas/nitrous_oxide = 1
	)


/datum/gas_reaction/syriniver/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sulfur) + air.get_moles(/datum/gas/fluorine) + air.get_moles(/datum/gas/toxin) + air.get_moles(/datum/gas/nitrous_oxide)
	remove_air = air.get_moles(/datum/gas/sulfur)
	air.adjust_moles(/datum/gas/sulfur, -remove_air)
	remove_air = air.get_moles(/datum/gas/fluorine)
	air.adjust_moles(/datum/gas/fluorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/toxin)
	air.adjust_moles(/datum/gas/toxin, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitrous_oxide)
	air.adjust_moles(/datum/gas/nitrous_oxide, -remove_air)
	air.adjust_moles(/datum/gas/syriniver, cleaned_air)

/datum/gas_reaction/penthrite
    priority = 1
    name = "penthrite"
    id = "penthrite"


/datum/gas_reaction/penthrite/init_reqs()
	min_requirements = list(
		/datum/gas/pentaerythritol = 1,
		/datum/gas/acetone = 1,
		/datum/gas/nitracid = 1,
		/datum/gas/wittel = 1
	)


/datum/gas_reaction/penthrite/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/pentaerythritol) + air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/nitracid) + air.get_moles(/datum/gas/wittel)
	remove_air = air.get_moles(/datum/gas/pentaerythritol)
	air.adjust_moles(/datum/gas/pentaerythritol, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitracid)
	air.adjust_moles(/datum/gas/nitracid, -remove_air)
	remove_air = air.get_moles(/datum/gas/wittel)
	air.adjust_moles(/datum/gas/wittel, -remove_air)
	air.adjust_moles(/datum/gas/penthrite, cleaned_air)

/datum/gas_reaction/space_drugs
    priority = 1
    name = "space_drugs"
    id = "space_drugs"


/datum/gas_reaction/space_drugs/init_reqs()
	min_requirements = list(
		/datum/gas/mercury = 1,
		/datum/gas/sugar = 1,
		/datum/gas/lithium = 1
	)


/datum/gas_reaction/space_drugs/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mercury) + air.get_moles(/datum/gas/sugar) + air.get_moles(/datum/gas/lithium)
	remove_air = air.get_moles(/datum/gas/mercury)
	air.adjust_moles(/datum/gas/mercury, -remove_air)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	remove_air = air.get_moles(/datum/gas/lithium)
	air.adjust_moles(/datum/gas/lithium, -remove_air)
	air.adjust_moles(/datum/gas/space_drugs, cleaned_air)

/datum/gas_reaction/crank
    priority = 1
    name = "crank"
    id = "crank"


/datum/gas_reaction/crank/init_reqs()
	min_requirements = list(
		/datum/gas/diphenhydramine = 1,
		/datum/gas/ammonia = 1,
		/datum/gas/lithium = 1,
		/datum/gas/acid = 1,
		/datum/gas/fuel = 1,
		"TEMP" = 390)

/datum/gas_reaction/crank/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/diphenhydramine) + air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/lithium) + air.get_moles(/datum/gas/acid) + air.get_moles(/datum/gas/fuel)
	remove_air = air.get_moles(/datum/gas/diphenhydramine)
	air.adjust_moles(/datum/gas/diphenhydramine, -remove_air)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/lithium)
	air.adjust_moles(/datum/gas/lithium, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	remove_air = air.get_moles(/datum/gas/fuel)
	air.adjust_moles(/datum/gas/fuel, -remove_air)
	air.adjust_moles(/datum/gas/crank, cleaned_air)

/datum/gas_reaction/krokodil
    priority = 1
    name = "krokodil"
    id = "krokodil"


/datum/gas_reaction/krokodil/init_reqs()
	min_requirements = list(
		/datum/gas/diphenhydramine = 1,
		/datum/gas/morphine = 1,
		/datum/gas/space_cleaner = 1,
		/datum/gas/potassium = 1,
		/datum/gas/phosphorus = 1,
		/datum/gas/fuel = 1,
		"TEMP" = 380)

/datum/gas_reaction/krokodil/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/diphenhydramine) + air.get_moles(/datum/gas/morphine) + air.get_moles(/datum/gas/space_cleaner) + air.get_moles(/datum/gas/potassium) + air.get_moles(/datum/gas/phosphorus) + air.get_moles(/datum/gas/fuel)
	remove_air = air.get_moles(/datum/gas/diphenhydramine)
	air.adjust_moles(/datum/gas/diphenhydramine, -remove_air)
	remove_air = air.get_moles(/datum/gas/morphine)
	air.adjust_moles(/datum/gas/morphine, -remove_air)
	remove_air = air.get_moles(/datum/gas/space_cleaner)
	air.adjust_moles(/datum/gas/space_cleaner, -remove_air)
	remove_air = air.get_moles(/datum/gas/potassium)
	air.adjust_moles(/datum/gas/potassium, -remove_air)
	remove_air = air.get_moles(/datum/gas/phosphorus)
	air.adjust_moles(/datum/gas/phosphorus, -remove_air)
	remove_air = air.get_moles(/datum/gas/fuel)
	air.adjust_moles(/datum/gas/fuel, -remove_air)
	air.adjust_moles(/datum/gas/krokodil, cleaned_air)

/datum/gas_reaction/methamphetamine
    priority = 1
    name = "methamphetamine"
    id = "methamphetamine"


/datum/gas_reaction/methamphetamine/init_reqs()
	min_requirements = list(
		/datum/gas/ephedrine = 1,
		/datum/gas/iodine = 1,
		/datum/gas/phosphorus = 1,
		/datum/gas/hydrogen = 1,
		"TEMP" = 374)

/datum/gas_reaction/methamphetamine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ephedrine) + air.get_moles(/datum/gas/iodine) + air.get_moles(/datum/gas/phosphorus) + air.get_moles(/datum/gas/hydrogen)
	remove_air = air.get_moles(/datum/gas/ephedrine)
	air.adjust_moles(/datum/gas/ephedrine, -remove_air)
	remove_air = air.get_moles(/datum/gas/iodine)
	air.adjust_moles(/datum/gas/iodine, -remove_air)
	remove_air = air.get_moles(/datum/gas/phosphorus)
	air.adjust_moles(/datum/gas/phosphorus, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	air.adjust_moles(/datum/gas/methamphetamine, cleaned_air)

/datum/gas_reaction/bath_salts
    priority = 1
    name = "bath_salts"
    id = "bath_salts"


/datum/gas_reaction/bath_salts/init_reqs()
	min_requirements = list(
		/datum/gas/bad_food = 1,
		/datum/gas/saltpetre = 1,
		/datum/gas/nutriment = 1,
		/datum/gas/space_cleaner = 1,
		/datum/gas/enzyme = 1,
		/datum/gas/tea = 1,
		/datum/gas/mercury = 1,
		"TEMP" = 374)

/datum/gas_reaction/bath_salts/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/bad_food) + air.get_moles(/datum/gas/saltpetre) + air.get_moles(/datum/gas/nutriment) + air.get_moles(/datum/gas/space_cleaner) + air.get_moles(/datum/gas/enzyme) + air.get_moles(/datum/gas/tea) + air.get_moles(/datum/gas/mercury)
	remove_air = air.get_moles(/datum/gas/bad_food)
	air.adjust_moles(/datum/gas/bad_food, -remove_air)
	remove_air = air.get_moles(/datum/gas/saltpetre)
	air.adjust_moles(/datum/gas/saltpetre, -remove_air)
	remove_air = air.get_moles(/datum/gas/nutriment)
	air.adjust_moles(/datum/gas/nutriment, -remove_air)
	remove_air = air.get_moles(/datum/gas/space_cleaner)
	air.adjust_moles(/datum/gas/space_cleaner, -remove_air)
	remove_air = air.get_moles(/datum/gas/enzyme)
	air.adjust_moles(/datum/gas/enzyme, -remove_air)
	remove_air = air.get_moles(/datum/gas/tea)
	air.adjust_moles(/datum/gas/tea, -remove_air)
	remove_air = air.get_moles(/datum/gas/mercury)
	air.adjust_moles(/datum/gas/mercury, -remove_air)
	air.adjust_moles(/datum/gas/bath_salts, cleaned_air)

/datum/gas_reaction/aranesp
    priority = 1
    name = "aranesp"
    id = "aranesp"


/datum/gas_reaction/aranesp/init_reqs()
	min_requirements = list(
		/datum/gas/epinephrine = 1,
		/datum/gas/atropine = 1,
		/datum/gas/morphine = 1
	)


/datum/gas_reaction/aranesp/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/epinephrine) + air.get_moles(/datum/gas/atropine) + air.get_moles(/datum/gas/morphine)
	remove_air = air.get_moles(/datum/gas/epinephrine)
	air.adjust_moles(/datum/gas/epinephrine, -remove_air)
	remove_air = air.get_moles(/datum/gas/atropine)
	air.adjust_moles(/datum/gas/atropine, -remove_air)
	remove_air = air.get_moles(/datum/gas/morphine)
	air.adjust_moles(/datum/gas/morphine, -remove_air)
	air.adjust_moles(/datum/gas/aranesp, cleaned_air)

/datum/gas_reaction/happiness
    priority = 1
    name = "happiness"
    id = "happiness"


/datum/gas_reaction/happiness/init_reqs()
	min_requirements = list(
		/datum/gas/nitrous_oxide = 2,
		/datum/gas/epinephrine = 2,
		/datum/gas/ethanol = 2
	)


/datum/gas_reaction/happiness/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/nitrous_oxide) + air.get_moles(/datum/gas/epinephrine) + air.get_moles(/datum/gas/ethanol)
	remove_air = air.get_moles(/datum/gas/nitrous_oxide)
	air.adjust_moles(/datum/gas/nitrous_oxide, -remove_air)
	remove_air = air.get_moles(/datum/gas/epinephrine)
	air.adjust_moles(/datum/gas/epinephrine, -remove_air)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	air.adjust_moles(/datum/gas/happiness, cleaned_air)

/datum/gas_reaction/pumpup
    priority = 1
    name = "pumpup"
    id = "pumpup"


/datum/gas_reaction/pumpup/init_reqs()
	min_requirements = list(
		/datum/gas/epinephrine = 2,
		/datum/gas/coffee = 2
	)


/datum/gas_reaction/pumpup/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/epinephrine) + air.get_moles(/datum/gas/coffee)
	remove_air = air.get_moles(/datum/gas/epinephrine)
	air.adjust_moles(/datum/gas/epinephrine, -remove_air)
	remove_air = air.get_moles(/datum/gas/coffee)
	air.adjust_moles(/datum/gas/coffee, -remove_air)
	air.adjust_moles(/datum/gas/pumpup, cleaned_air)

/datum/gas_reaction/leporazine
    priority = 1
    name = "leporazine"
    id = "leporazine"


/datum/gas_reaction/leporazine/init_reqs()
	min_requirements = list(
		/datum/gas/silicon = 1,
		/datum/gas/copper = 1
	)


/datum/gas_reaction/leporazine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/silicon) + air.get_moles(/datum/gas/copper)
	remove_air = air.get_moles(/datum/gas/silicon)
	air.adjust_moles(/datum/gas/silicon, -remove_air)
	remove_air = air.get_moles(/datum/gas/copper)
	air.adjust_moles(/datum/gas/copper, -remove_air)
	air.adjust_moles(/datum/gas/leporazine, cleaned_air)

/datum/gas_reaction/rezadone
    priority = 1
    name = "rezadone"
    id = "rezadone"


/datum/gas_reaction/rezadone/init_reqs()
	min_requirements = list(
		/datum/gas/carpotoxin = 1,
		/datum/gas/cryptobiolin = 1,
		/datum/gas/copper = 1
	)


/datum/gas_reaction/rezadone/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/carpotoxin) + air.get_moles(/datum/gas/cryptobiolin) + air.get_moles(/datum/gas/copper)
	remove_air = air.get_moles(/datum/gas/carpotoxin)
	air.adjust_moles(/datum/gas/carpotoxin, -remove_air)
	remove_air = air.get_moles(/datum/gas/cryptobiolin)
	air.adjust_moles(/datum/gas/cryptobiolin, -remove_air)
	remove_air = air.get_moles(/datum/gas/copper)
	air.adjust_moles(/datum/gas/copper, -remove_air)
	air.adjust_moles(/datum/gas/rezadone, cleaned_air)

/datum/gas_reaction/spaceacillin
    priority = 1
    name = "spaceacillin"
    id = "spaceacillin"


/datum/gas_reaction/spaceacillin/init_reqs()
	min_requirements = list(
		/datum/gas/cryptobiolin = 1,
		/datum/gas/epinephrine = 1
	)


/datum/gas_reaction/spaceacillin/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/cryptobiolin) + air.get_moles(/datum/gas/epinephrine)
	remove_air = air.get_moles(/datum/gas/cryptobiolin)
	air.adjust_moles(/datum/gas/cryptobiolin, -remove_air)
	remove_air = air.get_moles(/datum/gas/epinephrine)
	air.adjust_moles(/datum/gas/epinephrine, -remove_air)
	air.adjust_moles(/datum/gas/spaceacillin, cleaned_air)

/datum/gas_reaction/oculine
    priority = 1
    name = "oculine"
    id = "oculine"


/datum/gas_reaction/oculine/init_reqs()
	min_requirements = list(
		/datum/gas/multiver = 2,
		/datum/gas/carbon = 2,
		/datum/gas/hydrogen = 2
	)


/datum/gas_reaction/oculine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/multiver) + air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/hydrogen)
	remove_air = air.get_moles(/datum/gas/multiver)
	air.adjust_moles(/datum/gas/multiver, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	air.adjust_moles(/datum/gas/oculine, cleaned_air)

/datum/gas_reaction/inacusiate
    priority = 1
    name = "inacusiate"
    id = "inacusiate"


/datum/gas_reaction/inacusiate/init_reqs()
	min_requirements = list(
		/datum/gas/water = 1,
		/datum/gas/carbon = 1,
		/datum/gas/multiver = 1
	)


/datum/gas_reaction/inacusiate/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/multiver)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/multiver)
	air.adjust_moles(/datum/gas/multiver, -remove_air)
	air.adjust_moles(/datum/gas/inacusiate, cleaned_air)

/datum/gas_reaction/synaptizine
    priority = 1
    name = "synaptizine"
    id = "synaptizine"


/datum/gas_reaction/synaptizine/init_reqs()
	min_requirements = list(
		/datum/gas/sugar = 1,
		/datum/gas/lithium = 1,
		/datum/gas/water = 1
	)


/datum/gas_reaction/synaptizine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sugar) + air.get_moles(/datum/gas/lithium) + air.get_moles(/datum/gas/water)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	remove_air = air.get_moles(/datum/gas/lithium)
	air.adjust_moles(/datum/gas/lithium, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	air.adjust_moles(/datum/gas/synaptizine, cleaned_air)

/datum/gas_reaction/salglu_solution
    priority = 1
    name = "salglu_solution"
    id = "salglu_solution"


/datum/gas_reaction/salglu_solution/init_reqs()
	min_requirements = list(
		/datum/gas/sodiumchloride = 1,
		/datum/gas/water = 1,
		/datum/gas/sugar = 1
	)


/datum/gas_reaction/salglu_solution/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sodiumchloride) + air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/sugar)
	remove_air = air.get_moles(/datum/gas/sodiumchloride)
	air.adjust_moles(/datum/gas/sodiumchloride, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	air.adjust_moles(/datum/gas/salglu_solution, cleaned_air)

/datum/gas_reaction/mine_salve
    priority = 1
    name = "mine_salve"
    id = "mine_salve"


/datum/gas_reaction/mine_salve/init_reqs()
	min_requirements = list(
		/datum/gas/oil = 1,
		/datum/gas/water = 1,
		/datum/gas/iron = 1
	)


/datum/gas_reaction/mine_salve/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oil) + air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/iron)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/iron)
	air.adjust_moles(/datum/gas/iron, -remove_air)
	air.adjust_moles(/datum/gas/mine_salve, cleaned_air)

/datum/gas_reaction/synthflesh
    priority = 1
    name = "synthflesh"
    id = "synthflesh"


/datum/gas_reaction/synthflesh/init_reqs()
	min_requirements = list(
		/datum/gas/blood = 1,
		/datum/gas/carbon = 1,
		/datum/gas/libital = 1
	)


/datum/gas_reaction/synthflesh/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/blood) + air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/libital)
	remove_air = air.get_moles(/datum/gas/blood)
	air.adjust_moles(/datum/gas/blood, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/libital)
	air.adjust_moles(/datum/gas/libital, -remove_air)
	air.adjust_moles(/datum/gas/synthflesh, cleaned_air)

/datum/gas_reaction/calomel
    priority = 1
    name = "calomel"
    id = "calomel"


/datum/gas_reaction/calomel/init_reqs()
	min_requirements = list(
		/datum/gas/mercury = 1,
		/datum/gas/chlorine = 1,
		"TEMP" = 374)

/datum/gas_reaction/calomel/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mercury) + air.get_moles(/datum/gas/chlorine)
	remove_air = air.get_moles(/datum/gas/mercury)
	air.adjust_moles(/datum/gas/mercury, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	air.adjust_moles(/datum/gas/calomel, cleaned_air)

/datum/gas_reaction/potass_iodide
    priority = 1
    name = "potass_iodide"
    id = "potass_iodide"


/datum/gas_reaction/potass_iodide/init_reqs()
	min_requirements = list(
		/datum/gas/potassium = 1,
		/datum/gas/iodine = 1
	)


/datum/gas_reaction/potass_iodide/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/potassium) + air.get_moles(/datum/gas/iodine)
	remove_air = air.get_moles(/datum/gas/potassium)
	air.adjust_moles(/datum/gas/potassium, -remove_air)
	remove_air = air.get_moles(/datum/gas/iodine)
	air.adjust_moles(/datum/gas/iodine, -remove_air)
	air.adjust_moles(/datum/gas/potass_iodide, cleaned_air)

/datum/gas_reaction/pen_acid
    priority = 1
    name = "pen_acid"
    id = "pen_acid"


/datum/gas_reaction/pen_acid/init_reqs()
	min_requirements = list(
		/datum/gas/fuel = 1,
		/datum/gas/chlorine = 1,
		/datum/gas/ammonia = 1,
		/datum/gas/formaldehyde = 1,
		/datum/gas/sodium = 1,
		/datum/gas/cyanide = 1
	)


/datum/gas_reaction/pen_acid/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/fuel) + air.get_moles(/datum/gas/chlorine) + air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/formaldehyde) + air.get_moles(/datum/gas/sodium) + air.get_moles(/datum/gas/cyanide)
	remove_air = air.get_moles(/datum/gas/fuel)
	air.adjust_moles(/datum/gas/fuel, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/formaldehyde)
	air.adjust_moles(/datum/gas/formaldehyde, -remove_air)
	remove_air = air.get_moles(/datum/gas/sodium)
	air.adjust_moles(/datum/gas/sodium, -remove_air)
	remove_air = air.get_moles(/datum/gas/cyanide)
	air.adjust_moles(/datum/gas/cyanide, -remove_air)
	air.adjust_moles(/datum/gas/pen_acid, cleaned_air)

/datum/gas_reaction/sal_acid
    priority = 1
    name = "sal_acid"
    id = "sal_acid"


/datum/gas_reaction/sal_acid/init_reqs()
	min_requirements = list(
		/datum/gas/sodium = 1,
		/datum/gas/phenol = 1,
		/datum/gas/carbon = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/acid = 1
	)


/datum/gas_reaction/sal_acid/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sodium) + air.get_moles(/datum/gas/phenol) + air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/acid)
	remove_air = air.get_moles(/datum/gas/sodium)
	air.adjust_moles(/datum/gas/sodium, -remove_air)
	remove_air = air.get_moles(/datum/gas/phenol)
	air.adjust_moles(/datum/gas/phenol, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	air.adjust_moles(/datum/gas/sal_acid, cleaned_air)

/datum/gas_reaction/oxandrolone
    priority = 1
    name = "oxandrolone"
    id = "oxandrolone"


/datum/gas_reaction/oxandrolone/init_reqs()
	min_requirements = list(
		/datum/gas/carbon = 3,
		/datum/gas/phenol = 3,
		/datum/gas/hydrogen = 3,
		/datum/gas/oxygen = 3
	)


/datum/gas_reaction/oxandrolone/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/phenol) + air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/phenol)
	air.adjust_moles(/datum/gas/phenol, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/oxandrolone, cleaned_air)

/datum/gas_reaction/salbutamol
    priority = 1
    name = "salbutamol"
    id = "salbutamol"


/datum/gas_reaction/salbutamol/init_reqs()
	min_requirements = list(
		/datum/gas/sal_acid = 1,
		/datum/gas/lithium = 1,
		/datum/gas/aluminium = 1,
		/datum/gas/bromine = 1,
		/datum/gas/ammonia = 1
	)


/datum/gas_reaction/salbutamol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sal_acid) + air.get_moles(/datum/gas/lithium) + air.get_moles(/datum/gas/aluminium) + air.get_moles(/datum/gas/bromine) + air.get_moles(/datum/gas/ammonia)
	remove_air = air.get_moles(/datum/gas/sal_acid)
	air.adjust_moles(/datum/gas/sal_acid, -remove_air)
	remove_air = air.get_moles(/datum/gas/lithium)
	air.adjust_moles(/datum/gas/lithium, -remove_air)
	remove_air = air.get_moles(/datum/gas/aluminium)
	air.adjust_moles(/datum/gas/aluminium, -remove_air)
	remove_air = air.get_moles(/datum/gas/bromine)
	air.adjust_moles(/datum/gas/bromine, -remove_air)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	air.adjust_moles(/datum/gas/salbutamol, cleaned_air)

/datum/gas_reaction/ephedrine
    priority = 1
    name = "ephedrine"
    id = "ephedrine"


/datum/gas_reaction/ephedrine/init_reqs()
	min_requirements = list(
		/datum/gas/sugar = 1,
		/datum/gas/oil = 1,
		/datum/gas/hydrogen = 1,
		/datum/gas/diethylamine = 1
	)


/datum/gas_reaction/ephedrine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sugar) + air.get_moles(/datum/gas/oil) + air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/diethylamine)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/diethylamine)
	air.adjust_moles(/datum/gas/diethylamine, -remove_air)
	air.adjust_moles(/datum/gas/ephedrine, cleaned_air)

/datum/gas_reaction/diphenhydramine
    priority = 1
    name = "diphenhydramine"
    id = "diphenhydramine"


/datum/gas_reaction/diphenhydramine/init_reqs()
	min_requirements = list(
		/datum/gas/oil = 1,
		/datum/gas/carbon = 1,
		/datum/gas/bromine = 1,
		/datum/gas/diethylamine = 1,
		/datum/gas/ethanol = 1
	)


/datum/gas_reaction/diphenhydramine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oil) + air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/bromine) + air.get_moles(/datum/gas/diethylamine) + air.get_moles(/datum/gas/ethanol)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/bromine)
	air.adjust_moles(/datum/gas/bromine, -remove_air)
	remove_air = air.get_moles(/datum/gas/diethylamine)
	air.adjust_moles(/datum/gas/diethylamine, -remove_air)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	air.adjust_moles(/datum/gas/diphenhydramine, cleaned_air)

/datum/gas_reaction/atropine
    priority = 1
    name = "atropine"
    id = "atropine"


/datum/gas_reaction/atropine/init_reqs()
	min_requirements = list(
		/datum/gas/ethanol = 1,
		/datum/gas/acetone = 1,
		/datum/gas/diethylamine = 1,
		/datum/gas/phenol = 1,
		/datum/gas/acid = 1
	)


/datum/gas_reaction/atropine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ethanol) + air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/diethylamine) + air.get_moles(/datum/gas/phenol) + air.get_moles(/datum/gas/acid)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/diethylamine)
	air.adjust_moles(/datum/gas/diethylamine, -remove_air)
	remove_air = air.get_moles(/datum/gas/phenol)
	air.adjust_moles(/datum/gas/phenol, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	air.adjust_moles(/datum/gas/atropine, cleaned_air)

/datum/gas_reaction/epinephrine
    priority = 1
    name = "epinephrine"
    id = "epinephrine"


/datum/gas_reaction/epinephrine/init_reqs()
	min_requirements = list(
		/datum/gas/phenol = 1,
		/datum/gas/acetone = 1,
		/datum/gas/diethylamine = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/chlorine = 1,
		/datum/gas/hydrogen = 1
	)


/datum/gas_reaction/epinephrine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/phenol) + air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/diethylamine) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/chlorine) + air.get_moles(/datum/gas/hydrogen)
	remove_air = air.get_moles(/datum/gas/phenol)
	air.adjust_moles(/datum/gas/phenol, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/diethylamine)
	air.adjust_moles(/datum/gas/diethylamine, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	air.adjust_moles(/datum/gas/epinephrine, cleaned_air)

/datum/gas_reaction/strange_reagent
    priority = 1
    name = "strange_reagent"
    id = "strange_reagent"


/datum/gas_reaction/strange_reagent/init_reqs()
	min_requirements = list(
		/datum/gas/omnizine = 1,
		/datum/gas/holywater = 1,
		/datum/gas/mutagen = 1
	)


/datum/gas_reaction/strange_reagent/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/omnizine) + air.get_moles(/datum/gas/holywater) + air.get_moles(/datum/gas/mutagen)
	remove_air = air.get_moles(/datum/gas/omnizine)
	air.adjust_moles(/datum/gas/omnizine, -remove_air)
	remove_air = air.get_moles(/datum/gas/holywater)
	air.adjust_moles(/datum/gas/holywater, -remove_air)
	remove_air = air.get_moles(/datum/gas/mutagen)
	air.adjust_moles(/datum/gas/mutagen, -remove_air)
	air.adjust_moles(/datum/gas/strange_reagent, cleaned_air)

/datum/gas_reaction/mannitol
    priority = 1
    name = "mannitol"
    id = "mannitol"


/datum/gas_reaction/mannitol/init_reqs()
	min_requirements = list(
		/datum/gas/sugar = 1,
		/datum/gas/hydrogen = 1,
		/datum/gas/water = 1
	)


/datum/gas_reaction/mannitol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sugar) + air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/water)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	air.adjust_moles(/datum/gas/mannitol, cleaned_air)

/datum/gas_reaction/neurine
    priority = 1
    name = "neurine"
    id = "neurine"


/datum/gas_reaction/neurine/init_reqs()
	min_requirements = list(
		/datum/gas/mannitol = 1,
		/datum/gas/acetone = 1,
		/datum/gas/oxygen = 1
	)


/datum/gas_reaction/neurine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mannitol) + air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/mannitol)
	air.adjust_moles(/datum/gas/mannitol, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/neurine, cleaned_air)

/datum/gas_reaction/mutadone
    priority = 1
    name = "mutadone"
    id = "mutadone"


/datum/gas_reaction/mutadone/init_reqs()
	min_requirements = list(
		/datum/gas/mutagen = 1,
		/datum/gas/acetone = 1,
		/datum/gas/bromine = 1
	)


/datum/gas_reaction/mutadone/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mutagen) + air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/bromine)
	remove_air = air.get_moles(/datum/gas/mutagen)
	air.adjust_moles(/datum/gas/mutagen, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/bromine)
	air.adjust_moles(/datum/gas/bromine, -remove_air)
	air.adjust_moles(/datum/gas/mutadone, cleaned_air)

/datum/gas_reaction/antihol
    priority = 1
    name = "antihol"
    id = "antihol"


/datum/gas_reaction/antihol/init_reqs()
	min_requirements = list(
		/datum/gas/ethanol = 1,
		/datum/gas/multiver = 1,
		/datum/gas/copper = 1
	)


/datum/gas_reaction/antihol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ethanol) + air.get_moles(/datum/gas/multiver) + air.get_moles(/datum/gas/copper)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	remove_air = air.get_moles(/datum/gas/multiver)
	air.adjust_moles(/datum/gas/multiver, -remove_air)
	remove_air = air.get_moles(/datum/gas/copper)
	air.adjust_moles(/datum/gas/copper, -remove_air)
	air.adjust_moles(/datum/gas/antihol, cleaned_air)

/datum/gas_reaction/cryoxadone
    priority = 1
    name = "cryoxadone"
    id = "cryoxadone"


/datum/gas_reaction/cryoxadone/init_reqs()
	min_requirements = list(
		/datum/gas/stable_plasma = 1,
		/datum/gas/acetone = 1,
		/datum/gas/mutagen = 1
	)


/datum/gas_reaction/cryoxadone/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/stable_plasma) + air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/mutagen)
	remove_air = air.get_moles(/datum/gas/stable_plasma)
	air.adjust_moles(/datum/gas/stable_plasma, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/mutagen)
	air.adjust_moles(/datum/gas/mutagen, -remove_air)
	air.adjust_moles(/datum/gas/cryoxadone, cleaned_air)

/datum/gas_reaction/pyroxadone
    priority = 1
    name = "pyroxadone"
    id = "pyroxadone"


/datum/gas_reaction/pyroxadone/init_reqs()
	min_requirements = list(
		/datum/gas/cryoxadone = 1,
		/datum/gas/slimejelly = 1
	)


/datum/gas_reaction/pyroxadone/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/cryoxadone) + air.get_moles(/datum/gas/slimejelly)
	remove_air = air.get_moles(/datum/gas/cryoxadone)
	air.adjust_moles(/datum/gas/cryoxadone, -remove_air)
	remove_air = air.get_moles(/datum/gas/slimejelly)
	air.adjust_moles(/datum/gas/slimejelly, -remove_air)
	air.adjust_moles(/datum/gas/pyroxadone, cleaned_air)

/datum/gas_reaction/clonexadone
    priority = 1
    name = "clonexadone"
    id = "clonexadone"


/datum/gas_reaction/clonexadone/init_reqs()
	min_requirements = list(
		/datum/gas/cryoxadone = 1,
		/datum/gas/sodium = 1
	)


/datum/gas_reaction/clonexadone/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/cryoxadone) + air.get_moles(/datum/gas/sodium)
	remove_air = air.get_moles(/datum/gas/cryoxadone)
	air.adjust_moles(/datum/gas/cryoxadone, -remove_air)
	remove_air = air.get_moles(/datum/gas/sodium)
	air.adjust_moles(/datum/gas/sodium, -remove_air)
	air.adjust_moles(/datum/gas/clonexadone, cleaned_air)

/datum/gas_reaction/haloperidol
    priority = 1
    name = "haloperidol"
    id = "haloperidol"


/datum/gas_reaction/haloperidol/init_reqs()
	min_requirements = list(
		/datum/gas/chlorine = 1,
		/datum/gas/fluorine = 1,
		/datum/gas/aluminium = 1,
		/datum/gas/potass_iodide = 1,
		/datum/gas/oil = 1
	)


/datum/gas_reaction/haloperidol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/chlorine) + air.get_moles(/datum/gas/fluorine) + air.get_moles(/datum/gas/aluminium) + air.get_moles(/datum/gas/potass_iodide) + air.get_moles(/datum/gas/oil)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/fluorine)
	air.adjust_moles(/datum/gas/fluorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/aluminium)
	air.adjust_moles(/datum/gas/aluminium, -remove_air)
	remove_air = air.get_moles(/datum/gas/potass_iodide)
	air.adjust_moles(/datum/gas/potass_iodide, -remove_air)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	air.adjust_moles(/datum/gas/haloperidol, cleaned_air)

/datum/gas_reaction/regen_jelly
    priority = 1
    name = "regen_jelly"
    id = "regen_jelly"


/datum/gas_reaction/regen_jelly/init_reqs()
	min_requirements = list(
		/datum/gas/omnizine = 1,
		/datum/gas/slimejelly = 1
	)


/datum/gas_reaction/regen_jelly/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/omnizine) + air.get_moles(/datum/gas/slimejelly)
	remove_air = air.get_moles(/datum/gas/omnizine)
	air.adjust_moles(/datum/gas/omnizine, -remove_air)
	remove_air = air.get_moles(/datum/gas/slimejelly)
	air.adjust_moles(/datum/gas/slimejelly, -remove_air)
	air.adjust_moles(/datum/gas/regen_jelly, cleaned_air)

/datum/gas_reaction/higadrite
    priority = 1
    name = "higadrite"
    id = "higadrite"


/datum/gas_reaction/higadrite/init_reqs()
	min_requirements = list(
		/datum/gas/phenol = 2,
		/datum/gas/lithium = 2
	)


/datum/gas_reaction/higadrite/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/phenol) + air.get_moles(/datum/gas/lithium)
	remove_air = air.get_moles(/datum/gas/phenol)
	air.adjust_moles(/datum/gas/phenol, -remove_air)
	remove_air = air.get_moles(/datum/gas/lithium)
	air.adjust_moles(/datum/gas/lithium, -remove_air)
	air.adjust_moles(/datum/gas/higadrite, cleaned_air)

/datum/gas_reaction/morphine
    priority = 1
    name = "morphine"
    id = "morphine"


/datum/gas_reaction/morphine/init_reqs()
	min_requirements = list(
		/datum/gas/carbon = 2,
		/datum/gas/hydrogen = 2,
		/datum/gas/ethanol = 2,
		/datum/gas/oxygen = 2,
		"TEMP" = 480)

/datum/gas_reaction/morphine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/ethanol) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/morphine, cleaned_air)

/datum/gas_reaction/modafinil
    priority = 1
    name = "modafinil"
    id = "modafinil"


/datum/gas_reaction/modafinil/init_reqs()
	min_requirements = list(
		/datum/gas/diethylamine = 1,
		/datum/gas/ammonia = 1,
		/datum/gas/phenol = 1,
		/datum/gas/acetone = 1,
		/datum/gas/acid = 1
	)


/datum/gas_reaction/modafinil/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/diethylamine) + air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/phenol) + air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/acid)
	remove_air = air.get_moles(/datum/gas/diethylamine)
	air.adjust_moles(/datum/gas/diethylamine, -remove_air)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/phenol)
	air.adjust_moles(/datum/gas/phenol, -remove_air)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	air.adjust_moles(/datum/gas/modafinil, cleaned_air)

/datum/gas_reaction/psicodine
    priority = 1
    name = "psicodine"
    id = "psicodine"


/datum/gas_reaction/psicodine/init_reqs()
	min_requirements = list(
		/datum/gas/mannitol = 2,
		/datum/gas/water = 2,
		/datum/gas/impedrezene = 2
	)


/datum/gas_reaction/psicodine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mannitol) + air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/impedrezene)
	remove_air = air.get_moles(/datum/gas/mannitol)
	air.adjust_moles(/datum/gas/mannitol, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/impedrezene)
	air.adjust_moles(/datum/gas/impedrezene, -remove_air)
	air.adjust_moles(/datum/gas/psicodine, cleaned_air)

/datum/gas_reaction/granibitaluri
    priority = 1
    name = "granibitaluri"
    id = "granibitaluri"


/datum/gas_reaction/granibitaluri/init_reqs()
	min_requirements = list(
		/datum/gas/sodiumchloride = 1,
		/datum/gas/carbon = 1,
		/datum/gas/acid = 1
	)


/datum/gas_reaction/granibitaluri/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sodiumchloride) + air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/acid)
	remove_air = air.get_moles(/datum/gas/sodiumchloride)
	air.adjust_moles(/datum/gas/sodiumchloride, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	air.adjust_moles(/datum/gas/granibitaluri, cleaned_air)

/datum/gas_reaction/sterilizine
    priority = 1
    name = "sterilizine"
    id = "sterilizine"


/datum/gas_reaction/sterilizine/init_reqs()
	min_requirements = list(
		/datum/gas/ethanol = 1,
		/datum/gas/multiver = 1,
		/datum/gas/chlorine = 1
	)


/datum/gas_reaction/sterilizine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ethanol) + air.get_moles(/datum/gas/multiver) + air.get_moles(/datum/gas/chlorine)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	remove_air = air.get_moles(/datum/gas/multiver)
	air.adjust_moles(/datum/gas/multiver, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	air.adjust_moles(/datum/gas/sterilizine, cleaned_air)

/datum/gas_reaction/lube
    priority = 1
    name = "lube"
    id = "lube"


/datum/gas_reaction/lube/init_reqs()
	min_requirements = list(
		/datum/gas/water = 1,
		/datum/gas/silicon = 1,
		/datum/gas/oxygen = 1
	)


/datum/gas_reaction/lube/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/silicon) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/silicon)
	air.adjust_moles(/datum/gas/silicon, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/lube, cleaned_air)

/datum/gas_reaction/spraytan
    priority = 1
    name = "spraytan"
    id = "spraytan"


/datum/gas_reaction/spraytan/init_reqs()
	min_requirements = list(
		/datum/gas/orangejuice = 1,
		/datum/gas/oil = 1
	)


/datum/gas_reaction/spraytan/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/orangejuice) + air.get_moles(/datum/gas/oil)
	remove_air = air.get_moles(/datum/gas/orangejuice)
	air.adjust_moles(/datum/gas/orangejuice, -remove_air)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	air.adjust_moles(/datum/gas/spraytan, cleaned_air)

/datum/gas_reaction/impedrezene
    priority = 1
    name = "impedrezene"
    id = "impedrezene"


/datum/gas_reaction/impedrezene/init_reqs()
	min_requirements = list(
		/datum/gas/mercury = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/sugar = 1
	)


/datum/gas_reaction/impedrezene/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mercury) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/sugar)
	remove_air = air.get_moles(/datum/gas/mercury)
	air.adjust_moles(/datum/gas/mercury, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	air.adjust_moles(/datum/gas/impedrezene, cleaned_air)

/datum/gas_reaction/cryptobiolin
    priority = 1
    name = "cryptobiolin"
    id = "cryptobiolin"


/datum/gas_reaction/cryptobiolin/init_reqs()
	min_requirements = list(
		/datum/gas/potassium = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/sugar = 1
	)


/datum/gas_reaction/cryptobiolin/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/potassium) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/sugar)
	remove_air = air.get_moles(/datum/gas/potassium)
	air.adjust_moles(/datum/gas/potassium, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	air.adjust_moles(/datum/gas/cryptobiolin, cleaned_air)

/datum/gas_reaction/glycerol
    priority = 1
    name = "glycerol"
    id = "glycerol"


/datum/gas_reaction/glycerol/init_reqs()
	min_requirements = list(
		/datum/gas/cornoil = 3,
		/datum/gas/acid = 3
	)


/datum/gas_reaction/glycerol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/cornoil) + air.get_moles(/datum/gas/acid)
	remove_air = air.get_moles(/datum/gas/cornoil)
	air.adjust_moles(/datum/gas/cornoil, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	air.adjust_moles(/datum/gas/glycerol, cleaned_air)

/datum/gas_reaction/sodiumchloride
    priority = 1
    name = "sodiumchloride"
    id = "sodiumchloride"


/datum/gas_reaction/sodiumchloride/init_reqs()
	min_requirements = list(
		/datum/gas/water = 1,
		/datum/gas/sodium = 1,
		/datum/gas/chlorine = 1
	)


/datum/gas_reaction/sodiumchloride/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/sodium) + air.get_moles(/datum/gas/chlorine)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/sodium)
	air.adjust_moles(/datum/gas/sodium, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	air.adjust_moles(/datum/gas/sodiumchloride, cleaned_air)

/datum/gas_reaction/stable_plasma
    priority = 1
    name = "stable_plasma"
    id = "stable_plasma"


/datum/gas_reaction/stable_plasma/init_reqs()
	min_requirements = list(
		/datum/gas/plasma = 1
	)


/datum/gas_reaction/stable_plasma/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/plasma)
	remove_air = air.get_moles(/datum/gas/plasma)
	air.adjust_moles(/datum/gas/plasma, -remove_air)
	air.adjust_moles(/datum/gas/stable_plasma, cleaned_air)

/datum/gas_reaction/carbondioxide
    priority = 1
    name = "carbondioxide"
    id = "carbondioxide"


/datum/gas_reaction/carbondioxide/init_reqs()
	min_requirements = list(
		/datum/gas/carbon = 1,
		/datum/gas/oxygen = 1,
		"TEMP" = 777)

/datum/gas_reaction/carbondioxide/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/carbondioxide, cleaned_air)

/datum/gas_reaction/nitrous_oxide
    priority = 1
    name = "nitrous_oxide"
    id = "nitrous_oxide"


/datum/gas_reaction/nitrous_oxide/init_reqs()
	min_requirements = list(
		/datum/gas/ammonia = 2,
		/datum/gas/nitrogen = 2,
		/datum/gas/oxygen = 2,
		"TEMP" = 525)

/datum/gas_reaction/nitrous_oxide/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/nitrogen) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/nitrous_oxide, cleaned_air)

/datum/gas_reaction/mulligan
    priority = 1
    name = "mulligan"
    id = "mulligan"


/datum/gas_reaction/mulligan/init_reqs()
	min_requirements = list(
		/datum/gas/jelly = 1,
		/datum/gas/mutagen = 1
	)


/datum/gas_reaction/mulligan/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/jelly) + air.get_moles(/datum/gas/mutagen)
	remove_air = air.get_moles(/datum/gas/jelly)
	air.adjust_moles(/datum/gas/jelly, -remove_air)
	remove_air = air.get_moles(/datum/gas/mutagen)
	air.adjust_moles(/datum/gas/mutagen, -remove_air)
	air.adjust_moles(/datum/gas/mulligan, cleaned_air)

/datum/gas_reaction/virus_food
    priority = 1
    name = "virus_food"
    id = "virus_food"


/datum/gas_reaction/virus_food/init_reqs()
	min_requirements = list(
		/datum/gas/water = 5,
		/datum/gas/milk = 5
	)


/datum/gas_reaction/virus_food/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/milk)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/milk)
	air.adjust_moles(/datum/gas/milk, -remove_air)
	air.adjust_moles(/datum/gas/virus_food, cleaned_air)

/datum/gas_reaction/ammonia
    priority = 1
    name = "ammonia"
    id = "ammonia"


/datum/gas_reaction/ammonia/init_reqs()
	min_requirements = list(
		/datum/gas/hydrogen = 3,
		/datum/gas/nitrogen = 3
	)


/datum/gas_reaction/ammonia/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/nitrogen)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	air.adjust_moles(/datum/gas/ammonia, cleaned_air)

/datum/gas_reaction/diethylamine
    priority = 1
    name = "diethylamine"
    id = "diethylamine"


/datum/gas_reaction/diethylamine/init_reqs()
	min_requirements = list(
		/datum/gas/ammonia = 1,
		/datum/gas/ethanol = 1
	)


/datum/gas_reaction/diethylamine/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/ethanol)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	air.adjust_moles(/datum/gas/diethylamine, cleaned_air)

/datum/gas_reaction/space_cleaner
    priority = 1
    name = "space_cleaner"
    id = "space_cleaner"


/datum/gas_reaction/space_cleaner/init_reqs()
	min_requirements = list(
		/datum/gas/ammonia = 1,
		/datum/gas/water = 1
	)


/datum/gas_reaction/space_cleaner/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/water)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	air.adjust_moles(/datum/gas/space_cleaner, cleaned_air)

/datum/gas_reaction/plantbgone
    priority = 1
    name = "plantbgone"
    id = "plantbgone"


/datum/gas_reaction/plantbgone/init_reqs()
	min_requirements = list(
		/datum/gas/toxin = 1,
		/datum/gas/water = 1
	)


/datum/gas_reaction/plantbgone/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/toxin) + air.get_moles(/datum/gas/water)
	remove_air = air.get_moles(/datum/gas/toxin)
	air.adjust_moles(/datum/gas/toxin, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	air.adjust_moles(/datum/gas/plantbgone, cleaned_air)

/datum/gas_reaction/weedkiller
    priority = 1
    name = "weedkiller"
    id = "weedkiller"


/datum/gas_reaction/weedkiller/init_reqs()
	min_requirements = list(
		/datum/gas/toxin = 1,
		/datum/gas/ammonia = 1
	)


/datum/gas_reaction/weedkiller/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/toxin) + air.get_moles(/datum/gas/ammonia)
	remove_air = air.get_moles(/datum/gas/toxin)
	air.adjust_moles(/datum/gas/toxin, -remove_air)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	air.adjust_moles(/datum/gas/weedkiller, cleaned_air)

/datum/gas_reaction/pestkiller
    priority = 1
    name = "pestkiller"
    id = "pestkiller"


/datum/gas_reaction/pestkiller/init_reqs()
	min_requirements = list(
		/datum/gas/toxin = 1,
		/datum/gas/ethanol = 1
	)


/datum/gas_reaction/pestkiller/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/toxin) + air.get_moles(/datum/gas/ethanol)
	remove_air = air.get_moles(/datum/gas/toxin)
	air.adjust_moles(/datum/gas/toxin, -remove_air)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	air.adjust_moles(/datum/gas/pestkiller, cleaned_air)

/datum/gas_reaction/drying_agent
    priority = 1
    name = "drying_agent"
    id = "drying_agent"


/datum/gas_reaction/drying_agent/init_reqs()
	min_requirements = list(
		/datum/gas/stable_plasma = 2,
		/datum/gas/ethanol = 2,
		/datum/gas/sodium = 2
	)


/datum/gas_reaction/drying_agent/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/stable_plasma) + air.get_moles(/datum/gas/ethanol) + air.get_moles(/datum/gas/sodium)
	remove_air = air.get_moles(/datum/gas/stable_plasma)
	air.adjust_moles(/datum/gas/stable_plasma, -remove_air)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	remove_air = air.get_moles(/datum/gas/sodium)
	air.adjust_moles(/datum/gas/sodium, -remove_air)
	air.adjust_moles(/datum/gas/drying_agent, cleaned_air)

/datum/gas_reaction/acetone
    priority = 1
    name = "acetone"
    id = "acetone"


/datum/gas_reaction/acetone/init_reqs()
	min_requirements = list(
		/datum/gas/oil = 1,
		/datum/gas/fuel = 1,
		/datum/gas/oxygen = 1
	)


/datum/gas_reaction/acetone/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oil) + air.get_moles(/datum/gas/fuel) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	remove_air = air.get_moles(/datum/gas/fuel)
	air.adjust_moles(/datum/gas/fuel, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/acetone, cleaned_air)

/datum/gas_reaction/carpet
    priority = 1
    name = "carpet"
    id = "carpet"


/datum/gas_reaction/carpet/init_reqs()
	min_requirements = list(
		/datum/gas/space_drugs = 1,
		/datum/gas/blood = 1
	)


/datum/gas_reaction/carpet/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/space_drugs) + air.get_moles(/datum/gas/blood)
	remove_air = air.get_moles(/datum/gas/space_drugs)
	air.adjust_moles(/datum/gas/space_drugs, -remove_air)
	remove_air = air.get_moles(/datum/gas/blood)
	air.adjust_moles(/datum/gas/blood, -remove_air)
	air.adjust_moles(/datum/gas/carpet, cleaned_air)

/datum/gas_reaction/oil
    priority = 1
    name = "oil"
    id = "oil"


/datum/gas_reaction/oil/init_reqs()
	min_requirements = list(
		/datum/gas/fuel = 1,
		/datum/gas/carbon = 1,
		/datum/gas/hydrogen = 1
	)


/datum/gas_reaction/oil/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/fuel) + air.get_moles(/datum/gas/carbon) + air.get_moles(/datum/gas/hydrogen)
	remove_air = air.get_moles(/datum/gas/fuel)
	air.adjust_moles(/datum/gas/fuel, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	air.adjust_moles(/datum/gas/oil, cleaned_air)

/datum/gas_reaction/phenol
    priority = 1
    name = "phenol"
    id = "phenol"


/datum/gas_reaction/phenol/init_reqs()
	min_requirements = list(
		/datum/gas/water = 1,
		/datum/gas/chlorine = 1,
		/datum/gas/oil = 1
	)


/datum/gas_reaction/phenol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/chlorine) + air.get_moles(/datum/gas/oil)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	air.adjust_moles(/datum/gas/phenol, cleaned_air)

/datum/gas_reaction/ash
    priority = 1
    name = "ash"
    id = "ash"


/datum/gas_reaction/ash/init_reqs()
	min_requirements = list(
		/datum/gas/oil = 1,
		"TEMP" = 480)

/datum/gas_reaction/ash/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oil)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	air.adjust_moles(/datum/gas/ash, cleaned_air)

/datum/gas_reaction/colorful_reagent
    priority = 1
    name = "colorful_reagent"
    id = "colorful_reagent"


/datum/gas_reaction/colorful_reagent/init_reqs()
	min_requirements = list(
		/datum/gas/stable_plasma = 1,
		/datum/gas/radium = 1,
		/datum/gas/space_drugs = 1,
		/datum/gas/cryoxadone = 1,
		/datum/gas/triple_citrus = 1
	)


/datum/gas_reaction/colorful_reagent/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/stable_plasma) + air.get_moles(/datum/gas/radium) + air.get_moles(/datum/gas/space_drugs) + air.get_moles(/datum/gas/cryoxadone) + air.get_moles(/datum/gas/triple_citrus)
	remove_air = air.get_moles(/datum/gas/stable_plasma)
	air.adjust_moles(/datum/gas/stable_plasma, -remove_air)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	remove_air = air.get_moles(/datum/gas/space_drugs)
	air.adjust_moles(/datum/gas/space_drugs, -remove_air)
	remove_air = air.get_moles(/datum/gas/cryoxadone)
	air.adjust_moles(/datum/gas/cryoxadone, -remove_air)
	remove_air = air.get_moles(/datum/gas/triple_citrus)
	air.adjust_moles(/datum/gas/triple_citrus, -remove_air)
	air.adjust_moles(/datum/gas/colorful_reagent, cleaned_air)

/datum/gas_reaction/monkey_powder
    priority = 1
    name = "monkey_powder"
    id = "monkey_powder"


/datum/gas_reaction/monkey_powder/init_reqs()
	min_requirements = list(
		/datum/gas/banana = 1,
		/datum/gas/nutriment = 1,
		/datum/gas/liquidgibs = 1
	)


/datum/gas_reaction/monkey_powder/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/banana) + air.get_moles(/datum/gas/nutriment) + air.get_moles(/datum/gas/liquidgibs)
	remove_air = air.get_moles(/datum/gas/banana)
	air.adjust_moles(/datum/gas/banana, -remove_air)
	remove_air = air.get_moles(/datum/gas/nutriment)
	air.adjust_moles(/datum/gas/nutriment, -remove_air)
	remove_air = air.get_moles(/datum/gas/liquidgibs)
	air.adjust_moles(/datum/gas/liquidgibs, -remove_air)
	air.adjust_moles(/datum/gas/monkey_powder, cleaned_air)

/datum/gas_reaction/hair_dye
    priority = 1
    name = "hair_dye"
    id = "hair_dye"


/datum/gas_reaction/hair_dye/init_reqs()
	min_requirements = list(
		/datum/gas/colorful_reagent = 1,
		/datum/gas/radium = 1,
		/datum/gas/space_drugs = 1
	)


/datum/gas_reaction/hair_dye/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/colorful_reagent) + air.get_moles(/datum/gas/radium) + air.get_moles(/datum/gas/space_drugs)
	remove_air = air.get_moles(/datum/gas/colorful_reagent)
	air.adjust_moles(/datum/gas/colorful_reagent, -remove_air)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	remove_air = air.get_moles(/datum/gas/space_drugs)
	air.adjust_moles(/datum/gas/space_drugs, -remove_air)
	air.adjust_moles(/datum/gas/hair_dye, cleaned_air)

/datum/gas_reaction/barbers_aid
    priority = 1
    name = "barbers_aid"
    id = "barbers_aid"


/datum/gas_reaction/barbers_aid/init_reqs()
	min_requirements = list(
		/datum/gas/carpet = 1,
		/datum/gas/radium = 1,
		/datum/gas/space_drugs = 1
	)


/datum/gas_reaction/barbers_aid/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/carpet) + air.get_moles(/datum/gas/radium) + air.get_moles(/datum/gas/space_drugs)
	remove_air = air.get_moles(/datum/gas/carpet)
	air.adjust_moles(/datum/gas/carpet, -remove_air)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	remove_air = air.get_moles(/datum/gas/space_drugs)
	air.adjust_moles(/datum/gas/space_drugs, -remove_air)
	air.adjust_moles(/datum/gas/barbers_aid, cleaned_air)

/datum/gas_reaction/concentrated_barbers_aid
    priority = 1
    name = "concentrated_barbers_aid"
    id = "concentrated_barbers_aid"


/datum/gas_reaction/concentrated_barbers_aid/init_reqs()
	min_requirements = list(
		/datum/gas/barbers_aid = 1,
		/datum/gas/mutagen = 1
	)


/datum/gas_reaction/concentrated_barbers_aid/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/barbers_aid) + air.get_moles(/datum/gas/mutagen)
	remove_air = air.get_moles(/datum/gas/barbers_aid)
	air.adjust_moles(/datum/gas/barbers_aid, -remove_air)
	remove_air = air.get_moles(/datum/gas/mutagen)
	air.adjust_moles(/datum/gas/mutagen, -remove_air)
	air.adjust_moles(/datum/gas/concentrated_barbers_aid, cleaned_air)

/datum/gas_reaction/baldium
    priority = 1
    name = "baldium"
    id = "baldium"


/datum/gas_reaction/baldium/init_reqs()
	min_requirements = list(
		/datum/gas/radium = 1,
		/datum/gas/acid = 1,
		/datum/gas/lye = 1,
		"TEMP" = 395)

/datum/gas_reaction/baldium/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/radium) + air.get_moles(/datum/gas/acid) + air.get_moles(/datum/gas/lye)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	remove_air = air.get_moles(/datum/gas/lye)
	air.adjust_moles(/datum/gas/lye, -remove_air)
	air.adjust_moles(/datum/gas/baldium, cleaned_air)

/datum/gas_reaction/saltpetre
    priority = 1
    name = "saltpetre"
    id = "saltpetre"


/datum/gas_reaction/saltpetre/init_reqs()
	min_requirements = list(
		/datum/gas/potassium = 1,
		/datum/gas/nitrogen = 1,
		/datum/gas/oxygen = 1
	)


/datum/gas_reaction/saltpetre/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/potassium) + air.get_moles(/datum/gas/nitrogen) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/potassium)
	air.adjust_moles(/datum/gas/potassium, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/saltpetre, cleaned_air)

/datum/gas_reaction/lye
    priority = 1
    name = "lye"
    id = "lye"


/datum/gas_reaction/lye/init_reqs()
	min_requirements = list(
		/datum/gas/sodium = 1,
		/datum/gas/hydrogen = 1,
		/datum/gas/oxygen = 1
	)


/datum/gas_reaction/lye/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sodium) + air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/sodium)
	air.adjust_moles(/datum/gas/sodium, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/lye, cleaned_air)

/datum/gas_reaction/royal_bee_jelly
    priority = 1
    name = "royal_bee_jelly"
    id = "royal_bee_jelly"


/datum/gas_reaction/royal_bee_jelly/init_reqs()
	min_requirements = list(
		/datum/gas/mutagen = 10,
		/datum/gas/honey = 10
	)


/datum/gas_reaction/royal_bee_jelly/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mutagen) + air.get_moles(/datum/gas/honey)
	remove_air = air.get_moles(/datum/gas/mutagen)
	air.adjust_moles(/datum/gas/mutagen, -remove_air)
	remove_air = air.get_moles(/datum/gas/honey)
	air.adjust_moles(/datum/gas/honey, -remove_air)
	air.adjust_moles(/datum/gas/royal_bee_jelly, cleaned_air)

/datum/gas_reaction/laughter
    priority = 1
    name = "laughter"
    id = "laughter"


/datum/gas_reaction/laughter/init_reqs()
	min_requirements = list(
		/datum/gas/sugar = 1,
		/datum/gas/banana = 1
	)


/datum/gas_reaction/laughter/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/sugar) + air.get_moles(/datum/gas/banana)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	remove_air = air.get_moles(/datum/gas/banana)
	air.adjust_moles(/datum/gas/banana, -remove_air)
	air.adjust_moles(/datum/gas/laughter, cleaned_air)

/datum/gas_reaction/plastic_polymers
    priority = 1
    name = "plastic_polymers"
    id = "plastic_polymers"


/datum/gas_reaction/plastic_polymers/init_reqs()
	min_requirements = list(
		/datum/gas/oil = 5,
		/datum/gas/acid = 5,
		/datum/gas/ash = 5,
		"TEMP" = 374)

/datum/gas_reaction/plastic_polymers/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oil) + air.get_moles(/datum/gas/acid) + air.get_moles(/datum/gas/ash)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	remove_air = air.get_moles(/datum/gas/ash)
	air.adjust_moles(/datum/gas/ash, -remove_air)
	air.adjust_moles(/datum/gas/plastic_polymers, cleaned_air)

/datum/gas_reaction/pax
    priority = 1
    name = "pax"
    id = "pax"


/datum/gas_reaction/pax/init_reqs()
	min_requirements = list(
		/datum/gas/mindbreaker = 1,
		/datum/gas/synaptizine = 1,
		/datum/gas/water = 1
	)


/datum/gas_reaction/pax/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mindbreaker) + air.get_moles(/datum/gas/synaptizine) + air.get_moles(/datum/gas/water)
	remove_air = air.get_moles(/datum/gas/mindbreaker)
	air.adjust_moles(/datum/gas/mindbreaker, -remove_air)
	remove_air = air.get_moles(/datum/gas/synaptizine)
	air.adjust_moles(/datum/gas/synaptizine, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	air.adjust_moles(/datum/gas/pax, cleaned_air)

/datum/gas_reaction/yuck
    priority = 1
    name = "yuck"
    id = "yuck"


/datum/gas_reaction/yuck/init_reqs()
	min_requirements = list(
		/datum/gas/fuel = 3
	)


/datum/gas_reaction/yuck/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/fuel)
	remove_air = air.get_moles(/datum/gas/fuel)
	air.adjust_moles(/datum/gas/fuel, -remove_air)
	air.adjust_moles(/datum/gas/yuck, cleaned_air)

/datum/gas_reaction/slimejelly
    priority = 1
    name = "slimejelly"
    id = "slimejelly"


/datum/gas_reaction/slimejelly/init_reqs()
	min_requirements = list(
		/datum/gas/oil = 3,
		/datum/gas/radium = 3
	)


/datum/gas_reaction/slimejelly/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oil) + air.get_moles(/datum/gas/radium)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	air.adjust_moles(/datum/gas/slimejelly, cleaned_air)

/datum/gas_reaction/gravitum
    priority = 1
    name = "gravitum"
    id = "gravitum"


/datum/gas_reaction/gravitum/init_reqs()
	min_requirements = list(
		/datum/gas/wittel = 1,
		/datum/gas/sorium = 1
	)


/datum/gas_reaction/gravitum/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/wittel) + air.get_moles(/datum/gas/sorium)
	remove_air = air.get_moles(/datum/gas/wittel)
	air.adjust_moles(/datum/gas/wittel, -remove_air)
	remove_air = air.get_moles(/datum/gas/sorium)
	air.adjust_moles(/datum/gas/sorium, -remove_air)
	air.adjust_moles(/datum/gas/gravitum, cleaned_air)

/datum/gas_reaction/hydrogen_peroxide
    priority = 1
    name = "hydrogen_peroxide"
    id = "hydrogen_peroxide"


/datum/gas_reaction/hydrogen_peroxide/init_reqs()
	min_requirements = list(
		/datum/gas/water = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/chlorine = 1
	)


/datum/gas_reaction/hydrogen_peroxide/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/chlorine)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	air.adjust_moles(/datum/gas/hydrogen_peroxide, cleaned_air)

/datum/gas_reaction/acetone_oxide
    priority = 1
    name = "acetone_oxide"
    id = "acetone_oxide"


/datum/gas_reaction/acetone_oxide/init_reqs()
	min_requirements = list(
		/datum/gas/acetone = 2,
		/datum/gas/oxygen = 2,
		/datum/gas/hydrogen_peroxide = 2
	)


/datum/gas_reaction/acetone_oxide/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/hydrogen_peroxide)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen_peroxide)
	air.adjust_moles(/datum/gas/hydrogen_peroxide, -remove_air)
	air.adjust_moles(/datum/gas/acetone_oxide, cleaned_air)

/datum/gas_reaction/pentaerythritol
    priority = 1
    name = "pentaerythritol"
    id = "pentaerythritol"


/datum/gas_reaction/pentaerythritol/init_reqs()
	min_requirements = list(
		/datum/gas/acetaldehyde = 1,
		/datum/gas/formaldehyde = 1,
		/datum/gas/water = 1
	)


/datum/gas_reaction/pentaerythritol/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/acetaldehyde) + air.get_moles(/datum/gas/formaldehyde) + air.get_moles(/datum/gas/water)
	remove_air = air.get_moles(/datum/gas/acetaldehyde)
	air.adjust_moles(/datum/gas/acetaldehyde, -remove_air)
	remove_air = air.get_moles(/datum/gas/formaldehyde)
	air.adjust_moles(/datum/gas/formaldehyde, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	air.adjust_moles(/datum/gas/pentaerythritol, cleaned_air)

/datum/gas_reaction/acetaldehyde
    priority = 1
    name = "acetaldehyde"
    id = "acetaldehyde"


/datum/gas_reaction/acetaldehyde/init_reqs()
	min_requirements = list(
		/datum/gas/acetone = 1,
		/datum/gas/formaldehyde = 1,
		/datum/gas/water = 1,
		"TEMP" = 450)

/datum/gas_reaction/acetaldehyde/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/formaldehyde) + air.get_moles(/datum/gas/water)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/formaldehyde)
	air.adjust_moles(/datum/gas/formaldehyde, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	air.adjust_moles(/datum/gas/acetaldehyde, cleaned_air)

/datum/gas_reaction/holywater
    priority = 1
    name = "holywater"
    id = "holywater"


/datum/gas_reaction/holywater/init_reqs()
	min_requirements = list(
		/datum/gas/hollowwater = 1
	)


/datum/gas_reaction/holywater/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/hollowwater)
	remove_air = air.get_moles(/datum/gas/hollowwater)
	air.adjust_moles(/datum/gas/hollowwater, -remove_air)
	air.adjust_moles(/datum/gas/holywater, cleaned_air)

/datum/gas_reaction/gravy
    priority = 1
    name = "gravy"
    id = "gravy"


/datum/gas_reaction/gravy/init_reqs()
	min_requirements = list(
		/datum/gas/milk = 1,
		/datum/gas/nutriment = 1,
		/datum/gas/flour = 1
	)


/datum/gas_reaction/gravy/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/milk) + air.get_moles(/datum/gas/nutriment) + air.get_moles(/datum/gas/flour)
	remove_air = air.get_moles(/datum/gas/milk)
	air.adjust_moles(/datum/gas/milk, -remove_air)
	remove_air = air.get_moles(/datum/gas/nutriment)
	air.adjust_moles(/datum/gas/nutriment, -remove_air)
	remove_air = air.get_moles(/datum/gas/flour)
	air.adjust_moles(/datum/gas/flour, -remove_air)
	air.adjust_moles(/datum/gas/gravy, cleaned_air)

/datum/gas_reaction/exotic_stabilizer
    priority = 1
    name = "exotic_stabilizer"
    id = "exotic_stabilizer"


/datum/gas_reaction/exotic_stabilizer/init_reqs()
	min_requirements = list(
		/datum/gas/plasma_oxide = 1,
		/datum/gas/stabilizing_agent = 1
	)


/datum/gas_reaction/exotic_stabilizer/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/plasma_oxide) + air.get_moles(/datum/gas/stabilizing_agent)
	remove_air = air.get_moles(/datum/gas/plasma_oxide)
	air.adjust_moles(/datum/gas/plasma_oxide, -remove_air)
	remove_air = air.get_moles(/datum/gas/stabilizing_agent)
	air.adjust_moles(/datum/gas/stabilizing_agent, -remove_air)
	air.adjust_moles(/datum/gas/exotic_stabilizer, cleaned_air)

/datum/gas_reaction/gunpowder
    priority = 1
    name = "gunpowder"
    id = "gunpowder"


/datum/gas_reaction/gunpowder/init_reqs()
	min_requirements = list(
		/datum/gas/saltpetre = 1,
		/datum/gas/multiver = 1,
		/datum/gas/sulfur = 1
	)


/datum/gas_reaction/gunpowder/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/saltpetre) + air.get_moles(/datum/gas/multiver) + air.get_moles(/datum/gas/sulfur)
	remove_air = air.get_moles(/datum/gas/saltpetre)
	air.adjust_moles(/datum/gas/saltpetre, -remove_air)
	remove_air = air.get_moles(/datum/gas/multiver)
	air.adjust_moles(/datum/gas/multiver, -remove_air)
	remove_air = air.get_moles(/datum/gas/sulfur)
	air.adjust_moles(/datum/gas/sulfur, -remove_air)
	air.adjust_moles(/datum/gas/gunpowder, cleaned_air)

/datum/gas_reaction/thermite
    priority = 1
    name = "thermite"
    id = "thermite"


/datum/gas_reaction/thermite/init_reqs()
	min_requirements = list(
		/datum/gas/aluminium = 1,
		/datum/gas/iron = 1,
		/datum/gas/oxygen = 1
	)


/datum/gas_reaction/thermite/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/aluminium) + air.get_moles(/datum/gas/iron) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/aluminium)
	air.adjust_moles(/datum/gas/aluminium, -remove_air)
	remove_air = air.get_moles(/datum/gas/iron)
	air.adjust_moles(/datum/gas/iron, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/thermite, cleaned_air)

/datum/gas_reaction/stabilizing_agent
    priority = 1
    name = "stabilizing_agent"
    id = "stabilizing_agent"


/datum/gas_reaction/stabilizing_agent/init_reqs()
	min_requirements = list(
		/datum/gas/iron = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/hydrogen = 1
	)


/datum/gas_reaction/stabilizing_agent/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/iron) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/hydrogen)
	remove_air = air.get_moles(/datum/gas/iron)
	air.adjust_moles(/datum/gas/iron, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	air.adjust_moles(/datum/gas/stabilizing_agent, cleaned_air)

/datum/gas_reaction/clf3
    priority = 1
    name = "clf3"
    id = "clf3"


/datum/gas_reaction/clf3/init_reqs()
	min_requirements = list(
		/datum/gas/chlorine = 1,
		/datum/gas/fluorine = 1,
		"TEMP" = 424)

/datum/gas_reaction/clf3/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/chlorine) + air.get_moles(/datum/gas/fluorine)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/fluorine)
	air.adjust_moles(/datum/gas/fluorine, -remove_air)
	air.adjust_moles(/datum/gas/clf3, cleaned_air)

/datum/gas_reaction/sorium
    priority = 1
    name = "sorium"
    id = "sorium"


/datum/gas_reaction/sorium/init_reqs()
	min_requirements = list(
		/datum/gas/mercury = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/nitrogen = 1,
		/datum/gas/carbon = 1
	)


/datum/gas_reaction/sorium/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mercury) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/nitrogen) + air.get_moles(/datum/gas/carbon)
	remove_air = air.get_moles(/datum/gas/mercury)
	air.adjust_moles(/datum/gas/mercury, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	air.adjust_moles(/datum/gas/sorium, cleaned_air)

/datum/gas_reaction/liquid_dark_matter
    priority = 1
    name = "liquid_dark_matter"
    id = "liquid_dark_matter"


/datum/gas_reaction/liquid_dark_matter/init_reqs()
	min_requirements = list(
		/datum/gas/stable_plasma = 1,
		/datum/gas/radium = 1,
		/datum/gas/carbon = 1
	)


/datum/gas_reaction/liquid_dark_matter/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/stable_plasma) + air.get_moles(/datum/gas/radium) + air.get_moles(/datum/gas/carbon)
	remove_air = air.get_moles(/datum/gas/stable_plasma)
	air.adjust_moles(/datum/gas/stable_plasma, -remove_air)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	air.adjust_moles(/datum/gas/liquid_dark_matter, cleaned_air)

/datum/gas_reaction/flash_powder
    priority = 1
    name = "flash_powder"
    id = "flash_powder"


/datum/gas_reaction/flash_powder/init_reqs()
	min_requirements = list(
		/datum/gas/aluminium = 1,
		/datum/gas/potassium = 1,
		/datum/gas/sulfur = 1
	)


/datum/gas_reaction/flash_powder/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/aluminium) + air.get_moles(/datum/gas/potassium) + air.get_moles(/datum/gas/sulfur)
	remove_air = air.get_moles(/datum/gas/aluminium)
	air.adjust_moles(/datum/gas/aluminium, -remove_air)
	remove_air = air.get_moles(/datum/gas/potassium)
	air.adjust_moles(/datum/gas/potassium, -remove_air)
	remove_air = air.get_moles(/datum/gas/sulfur)
	air.adjust_moles(/datum/gas/sulfur, -remove_air)
	air.adjust_moles(/datum/gas/flash_powder, cleaned_air)

/datum/gas_reaction/smoke_powder
    priority = 1
    name = "smoke_powder"
    id = "smoke_powder"


/datum/gas_reaction/smoke_powder/init_reqs()
	min_requirements = list(
		/datum/gas/potassium = 1,
		/datum/gas/sugar = 1,
		/datum/gas/phosphorus = 1
	)


/datum/gas_reaction/smoke_powder/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/potassium) + air.get_moles(/datum/gas/sugar) + air.get_moles(/datum/gas/phosphorus)
	remove_air = air.get_moles(/datum/gas/potassium)
	air.adjust_moles(/datum/gas/potassium, -remove_air)
	remove_air = air.get_moles(/datum/gas/sugar)
	air.adjust_moles(/datum/gas/sugar, -remove_air)
	remove_air = air.get_moles(/datum/gas/phosphorus)
	air.adjust_moles(/datum/gas/phosphorus, -remove_air)
	air.adjust_moles(/datum/gas/smoke_powder, cleaned_air)

/datum/gas_reaction/sonic_powder
    priority = 1
    name = "sonic_powder"
    id = "sonic_powder"


/datum/gas_reaction/sonic_powder/init_reqs()
	min_requirements = list(
		/datum/gas/oxygen = 1,
		/datum/gas/space_cola = 1,
		/datum/gas/phosphorus = 1
	)


/datum/gas_reaction/sonic_powder/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/space_cola) + air.get_moles(/datum/gas/phosphorus)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/space_cola)
	air.adjust_moles(/datum/gas/space_cola, -remove_air)
	remove_air = air.get_moles(/datum/gas/phosphorus)
	air.adjust_moles(/datum/gas/phosphorus, -remove_air)
	air.adjust_moles(/datum/gas/sonic_powder, cleaned_air)

/datum/gas_reaction/phlogiston
    priority = 1
    name = "phlogiston"
    id = "phlogiston"


/datum/gas_reaction/phlogiston/init_reqs()
	min_requirements = list(
		/datum/gas/phosphorus = 1,
		/datum/gas/acid = 1,
		/datum/gas/stable_plasma = 1
	)


/datum/gas_reaction/phlogiston/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/phosphorus) + air.get_moles(/datum/gas/acid) + air.get_moles(/datum/gas/stable_plasma)
	remove_air = air.get_moles(/datum/gas/phosphorus)
	air.adjust_moles(/datum/gas/phosphorus, -remove_air)
	remove_air = air.get_moles(/datum/gas/acid)
	air.adjust_moles(/datum/gas/acid, -remove_air)
	remove_air = air.get_moles(/datum/gas/stable_plasma)
	air.adjust_moles(/datum/gas/stable_plasma, -remove_air)
	air.adjust_moles(/datum/gas/phlogiston, cleaned_air)

/datum/gas_reaction/napalm
    priority = 1
    name = "napalm"
    id = "napalm"


/datum/gas_reaction/napalm/init_reqs()
	min_requirements = list(
		/datum/gas/oil = 1,
		/datum/gas/fuel = 1,
		/datum/gas/ethanol = 1
	)


/datum/gas_reaction/napalm/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oil) + air.get_moles(/datum/gas/fuel) + air.get_moles(/datum/gas/ethanol)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	remove_air = air.get_moles(/datum/gas/fuel)
	air.adjust_moles(/datum/gas/fuel, -remove_air)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	air.adjust_moles(/datum/gas/napalm, cleaned_air)

/datum/gas_reaction/cryostylane
    priority = 1
    name = "cryostylane"
    id = "cryostylane"


/datum/gas_reaction/cryostylane/init_reqs()
	min_requirements = list(
		/datum/gas/water = 1,
		/datum/gas/stable_plasma = 1,
		/datum/gas/nitrogen = 1
	)


/datum/gas_reaction/cryostylane/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/water) + air.get_moles(/datum/gas/stable_plasma) + air.get_moles(/datum/gas/nitrogen)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	remove_air = air.get_moles(/datum/gas/stable_plasma)
	air.adjust_moles(/datum/gas/stable_plasma, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	air.adjust_moles(/datum/gas/cryostylane, cleaned_air)

/datum/gas_reaction/pyrosium
    priority = 1
    name = "pyrosium"
    id = "pyrosium"


/datum/gas_reaction/pyrosium/init_reqs()
	min_requirements = list(
		/datum/gas/stable_plasma = 1,
		/datum/gas/radium = 1,
		/datum/gas/phosphorus = 1
	)


/datum/gas_reaction/pyrosium/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/stable_plasma) + air.get_moles(/datum/gas/radium) + air.get_moles(/datum/gas/phosphorus)
	remove_air = air.get_moles(/datum/gas/stable_plasma)
	air.adjust_moles(/datum/gas/stable_plasma, -remove_air)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	remove_air = air.get_moles(/datum/gas/phosphorus)
	air.adjust_moles(/datum/gas/phosphorus, -remove_air)
	air.adjust_moles(/datum/gas/pyrosium, cleaned_air)


/datum/gas_reaction/firefighting_foam
    priority = 1
    name = "firefighting_foam"
    id = "firefighting_foam"


/datum/gas_reaction/firefighting_foam/init_reqs()
	min_requirements = list(
		/datum/gas/stabilizing_agent = 1,
		/datum/gas/fluorosurfactant = 1,
		/datum/gas/carbon = 1,
		"TEMP" = 200)

/datum/gas_reaction/firefighting_foam/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/stabilizing_agent) + air.get_moles(/datum/gas/fluorosurfactant) + air.get_moles(/datum/gas/carbon)
	remove_air = air.get_moles(/datum/gas/stabilizing_agent)
	air.adjust_moles(/datum/gas/stabilizing_agent, -remove_air)
	remove_air = air.get_moles(/datum/gas/fluorosurfactant)
	air.adjust_moles(/datum/gas/fluorosurfactant, -remove_air)
	remove_air = air.get_moles(/datum/gas/carbon)
	air.adjust_moles(/datum/gas/carbon, -remove_air)
	air.adjust_moles(/datum/gas/firefighting_foam, cleaned_air)

/datum/gas_reaction/formaldehyde
    priority = 1
    name = "formaldehyde"
    id = "formaldehyde"


/datum/gas_reaction/formaldehyde/init_reqs()
	min_requirements = list(
		/datum/gas/ethanol = 1,
		/datum/gas/oxygen = 1,
		/datum/gas/silver = 1,
		"TEMP" = 420)

/datum/gas_reaction/formaldehyde/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ethanol) + air.get_moles(/datum/gas/oxygen) + air.get_moles(/datum/gas/silver)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	remove_air = air.get_moles(/datum/gas/silver)
	air.adjust_moles(/datum/gas/silver, -remove_air)
	air.adjust_moles(/datum/gas/formaldehyde, cleaned_air)

/datum/gas_reaction/fentanyl
    priority = 1
    name = "fentanyl"
    id = "fentanyl"


/datum/gas_reaction/fentanyl/init_reqs()
	min_requirements = list(
		/datum/gas/space_drugs = 1,
		"TEMP" = 674)

/datum/gas_reaction/fentanyl/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/space_drugs)
	remove_air = air.get_moles(/datum/gas/space_drugs)
	air.adjust_moles(/datum/gas/space_drugs, -remove_air)
	air.adjust_moles(/datum/gas/fentanyl, cleaned_air)

/datum/gas_reaction/cyanide
    priority = 1
    name = "cyanide"
    id = "cyanide"


/datum/gas_reaction/cyanide/init_reqs()
	min_requirements = list(
		/datum/gas/oil = 1,
		/datum/gas/ammonia = 1,
		/datum/gas/oxygen = 1,
		"TEMP" = 380)

/datum/gas_reaction/cyanide/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/oil) + air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/oxygen)
	remove_air = air.get_moles(/datum/gas/oil)
	air.adjust_moles(/datum/gas/oil, -remove_air)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/oxygen)
	air.adjust_moles(/datum/gas/oxygen, -remove_air)
	air.adjust_moles(/datum/gas/cyanide, cleaned_air)

/datum/gas_reaction/itching_powder
    priority = 1
    name = "itching_powder"
    id = "itching_powder"


/datum/gas_reaction/itching_powder/init_reqs()
	min_requirements = list(
		/datum/gas/fuel = 1,
		/datum/gas/ammonia = 1,
		/datum/gas/multiver = 1
	)


/datum/gas_reaction/itching_powder/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/fuel) + air.get_moles(/datum/gas/ammonia) + air.get_moles(/datum/gas/multiver)
	remove_air = air.get_moles(/datum/gas/fuel)
	air.adjust_moles(/datum/gas/fuel, -remove_air)
	remove_air = air.get_moles(/datum/gas/ammonia)
	air.adjust_moles(/datum/gas/ammonia, -remove_air)
	remove_air = air.get_moles(/datum/gas/multiver)
	air.adjust_moles(/datum/gas/multiver, -remove_air)
	air.adjust_moles(/datum/gas/itching_powder, cleaned_air)

/datum/gas_reaction/nitracid
    priority = 1
    name = "nitracid"
    id = "nitracid"


/datum/gas_reaction/nitracid/init_reqs()
	min_requirements = list(
		/datum/gas/fluacid = 1,
		/datum/gas/nitrogen = 1,
		/datum/gas/hydrogen_peroxide = 1,
		"TEMP" = 480)

/datum/gas_reaction/nitracid/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/fluacid) + air.get_moles(/datum/gas/nitrogen) + air.get_moles(/datum/gas/hydrogen_peroxide)
	remove_air = air.get_moles(/datum/gas/fluacid)
	air.adjust_moles(/datum/gas/fluacid, -remove_air)
	remove_air = air.get_moles(/datum/gas/nitrogen)
	air.adjust_moles(/datum/gas/nitrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen_peroxide)
	air.adjust_moles(/datum/gas/hydrogen_peroxide, -remove_air)
	air.adjust_moles(/datum/gas/nitracid, cleaned_air)

/datum/gas_reaction/sulfonal
    priority = 1
    name = "sulfonal"
    id = "sulfonal"


/datum/gas_reaction/sulfonal/init_reqs()
	min_requirements = list(
		/datum/gas/acetone = 1,
		/datum/gas/diethylamine = 1,
		/datum/gas/sulfur = 1
	)


/datum/gas_reaction/sulfonal/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/acetone) + air.get_moles(/datum/gas/diethylamine) + air.get_moles(/datum/gas/sulfur)
	remove_air = air.get_moles(/datum/gas/acetone)
	air.adjust_moles(/datum/gas/acetone, -remove_air)
	remove_air = air.get_moles(/datum/gas/diethylamine)
	air.adjust_moles(/datum/gas/diethylamine, -remove_air)
	remove_air = air.get_moles(/datum/gas/sulfur)
	air.adjust_moles(/datum/gas/sulfur, -remove_air)
	air.adjust_moles(/datum/gas/sulfonal, cleaned_air)

/datum/gas_reaction/lipolicide
    priority = 1
    name = "lipolicide"
    id = "lipolicide"


/datum/gas_reaction/lipolicide/init_reqs()
	min_requirements = list(
		/datum/gas/mercury = 1,
		/datum/gas/diethylamine = 1,
		/datum/gas/ephedrine = 1
	)


/datum/gas_reaction/lipolicide/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/mercury) + air.get_moles(/datum/gas/diethylamine) + air.get_moles(/datum/gas/ephedrine)
	remove_air = air.get_moles(/datum/gas/mercury)
	air.adjust_moles(/datum/gas/mercury, -remove_air)
	remove_air = air.get_moles(/datum/gas/diethylamine)
	air.adjust_moles(/datum/gas/diethylamine, -remove_air)
	remove_air = air.get_moles(/datum/gas/ephedrine)
	air.adjust_moles(/datum/gas/ephedrine, -remove_air)
	air.adjust_moles(/datum/gas/lipolicide, cleaned_air)

/datum/gas_reaction/mutagen
    priority = 1
    name = "mutagen"
    id = "mutagen"


/datum/gas_reaction/mutagen/init_reqs()
	min_requirements = list(
		/datum/gas/radium = 1,
		/datum/gas/phosphorus = 1,
		/datum/gas/chlorine = 1
	)


/datum/gas_reaction/mutagen/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/radium) + air.get_moles(/datum/gas/phosphorus) + air.get_moles(/datum/gas/chlorine)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	remove_air = air.get_moles(/datum/gas/phosphorus)
	air.adjust_moles(/datum/gas/phosphorus, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	air.adjust_moles(/datum/gas/mutagen, cleaned_air)

/datum/gas_reaction/lexorin
    priority = 1
    name = "lexorin"
    id = "lexorin"


/datum/gas_reaction/lexorin/init_reqs()
	min_requirements = list(
		/datum/gas/plasma = 1,
		/datum/gas/hydrogen = 1,
		/datum/gas/salbutamol = 1
	)


/datum/gas_reaction/lexorin/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/plasma) + air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/salbutamol)
	remove_air = air.get_moles(/datum/gas/plasma)
	air.adjust_moles(/datum/gas/plasma, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/salbutamol)
	air.adjust_moles(/datum/gas/salbutamol, -remove_air)
	air.adjust_moles(/datum/gas/lexorin, cleaned_air)

/datum/gas_reaction/chloralhydrate
    priority = 1
    name = "chloralhydrate"
    id = "chloralhydrate"


/datum/gas_reaction/chloralhydrate/init_reqs()
	min_requirements = list(
		/datum/gas/ethanol = 1,
		/datum/gas/chlorine = 1,
		/datum/gas/water = 1
	)


/datum/gas_reaction/chloralhydrate/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/ethanol) + air.get_moles(/datum/gas/chlorine) + air.get_moles(/datum/gas/water)
	remove_air = air.get_moles(/datum/gas/ethanol)
	air.adjust_moles(/datum/gas/ethanol, -remove_air)
	remove_air = air.get_moles(/datum/gas/chlorine)
	air.adjust_moles(/datum/gas/chlorine, -remove_air)
	remove_air = air.get_moles(/datum/gas/water)
	air.adjust_moles(/datum/gas/water, -remove_air)
	air.adjust_moles(/datum/gas/chloralhydrate, cleaned_air)

/datum/gas_reaction/zombiepowder
    priority = 1
    name = "zombiepowder"
    id = "zombiepowder"


/datum/gas_reaction/zombiepowder/init_reqs()
	min_requirements = list(
		/datum/gas/carpotoxin = 5,
		/datum/gas/morphine = 5,
		/datum/gas/copper = 5
	)


/datum/gas_reaction/zombiepowder/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/carpotoxin) + air.get_moles(/datum/gas/morphine) + air.get_moles(/datum/gas/copper)
	remove_air = air.get_moles(/datum/gas/carpotoxin)
	air.adjust_moles(/datum/gas/carpotoxin, -remove_air)
	remove_air = air.get_moles(/datum/gas/morphine)
	air.adjust_moles(/datum/gas/morphine, -remove_air)
	remove_air = air.get_moles(/datum/gas/copper)
	air.adjust_moles(/datum/gas/copper, -remove_air)
	air.adjust_moles(/datum/gas/zombiepowder, cleaned_air)

/datum/gas_reaction/ghoulpowder
    priority = 1
    name = "ghoulpowder"
    id = "ghoulpowder"


/datum/gas_reaction/ghoulpowder/init_reqs()
	min_requirements = list(
		/datum/gas/zombiepowder = 1,
		/datum/gas/epinephrine = 1
	)


/datum/gas_reaction/ghoulpowder/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/zombiepowder) + air.get_moles(/datum/gas/epinephrine)
	remove_air = air.get_moles(/datum/gas/zombiepowder)
	air.adjust_moles(/datum/gas/zombiepowder, -remove_air)
	remove_air = air.get_moles(/datum/gas/epinephrine)
	air.adjust_moles(/datum/gas/epinephrine, -remove_air)
	air.adjust_moles(/datum/gas/ghoulpowder, cleaned_air)

/datum/gas_reaction/mindbreaker
    priority = 1
    name = "mindbreaker"
    id = "mindbreaker"


/datum/gas_reaction/mindbreaker/init_reqs()
	min_requirements = list(
		/datum/gas/silicon = 1,
		/datum/gas/hydrogen = 1,
		/datum/gas/multiver = 1
	)


/datum/gas_reaction/mindbreaker/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/silicon) + air.get_moles(/datum/gas/hydrogen) + air.get_moles(/datum/gas/multiver)
	remove_air = air.get_moles(/datum/gas/silicon)
	air.adjust_moles(/datum/gas/silicon, -remove_air)
	remove_air = air.get_moles(/datum/gas/hydrogen)
	air.adjust_moles(/datum/gas/hydrogen, -remove_air)
	remove_air = air.get_moles(/datum/gas/multiver)
	air.adjust_moles(/datum/gas/multiver, -remove_air)
	air.adjust_moles(/datum/gas/mindbreaker, cleaned_air)

/datum/gas_reaction/anacea
    priority = 1
    name = "anacea"
    id = "anacea"


/datum/gas_reaction/anacea/init_reqs()
	min_requirements = list(
		/datum/gas/haloperidol = 1,
		/datum/gas/impedrezene = 1,
		/datum/gas/radium = 1
	)


/datum/gas_reaction/anacea/react(datum/gas_mixture/air, datum/holder)
	var/remove_air = 0
	var/cleaned_air = air.get_moles(/datum/gas/haloperidol) + air.get_moles(/datum/gas/impedrezene) + air.get_moles(/datum/gas/radium)
	remove_air = air.get_moles(/datum/gas/haloperidol)
	air.adjust_moles(/datum/gas/haloperidol, -remove_air)
	remove_air = air.get_moles(/datum/gas/impedrezene)
	air.adjust_moles(/datum/gas/impedrezene, -remove_air)
	remove_air = air.get_moles(/datum/gas/radium)
	air.adjust_moles(/datum/gas/radium, -remove_air)
	air.adjust_moles(/datum/gas/anacea, cleaned_air)


// END
