
/*

	All telecommunications interactions:

*/

/obj/machinery/telecomms
	var/temp = "" // output message
	var/tempfreq = FREQ_COMMON
	var/mob/living/operator

/obj/machinery/telecomms/attackby(obj/item/P, mob/user, params)

	var/icon_closed = initial(icon_state)
	var/icon_open = "[initial(icon_state)]_o"
	if(!on)
		icon_closed = "[initial(icon_state)]_off"
		icon_open = "[initial(icon_state)]_o_off"

	if(default_deconstruction_screwdriver(user, icon_open, icon_closed, P))
		return
	// Using a multitool lets you access the receiver's interface
	else if(P.tool_behaviour == TOOL_MULTITOOL)
		attack_hand(user)

	else if(default_deconstruction_crowbar(P))
		return
	else
		return ..()

/obj/machinery/telecomms/ui_interact(mob/user, datum/tgui/ui)
	operator = user
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Telecomms")
		ui.open()

/obj/machinery/telecomms/ui_data(mob/user)
	var/list/data = list()

	data += add_option()

	data["minfreq"] = MIN_FREE_FREQ
	data["maxfreq"] = MAX_FREE_FREQ
	data["frequency"] = tempfreq

	var/obj/item/multitool/heldmultitool = get_multitool(user)
	data["multitool"] = heldmultitool

	if(heldmultitool)
		data["multibuff"] = heldmultitool.buffer

	data["toggled"] = toggled
	data["id"] = id
	data["network"] = network
	data["prefab"] = autolinkers.len ? TRUE : FALSE

	var/list/linked = list()
	var/i = 0
	data["linked"] = list()
	for(var/obj/machinery/telecomms/machine in links)
		i++
		if(machine.hide && !hide)
			continue
		var/list/entry = list()
		entry["index"] = i
		entry["name"] = machine.name
		entry["id"] = machine.id
		linked += list(entry)
	data["linked"] = linked

	var/list/frequencies = list()
	data["frequencies"] = list()
	for(var/x in freq_listening)
		frequencies += list(x)
	data["frequencies"] = frequencies

	return data

/obj/machinery/telecomms/ui_act(action, params)
	if(..())
		return

	if(!issilicon(usr))
		if(!istype(usr.get_active_held_item(), /obj/item/multitool))
			return

	var/obj/item/multitool/heldmultitool = get_multitool(operator)

	switch(action)
		if("toggle")
			toggled = !toggled
			update_power()
			update_icon()
			log_game("[key_name(operator)] toggled [toggled ? "On" : "Off"] [src] at [AREACOORD(src)].")
			. = TRUE
		if("id")
			if(params["value"])
				if(length(params["value"]) > 32)
					to_chat(operator, "<span class='warning'>Error: Machine ID too long!</span>")
					playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
					return
				else
					id = params["value"]
					log_game("[key_name(operator)] has changed the ID for [src] at [AREACOORD(src)] to [id].")
					. = TRUE
		if("network")
			if(params["value"])
				if(length(params["value"]) > 15)
					to_chat(operator, "<span class='warning'>Error: Network name too long!</span>")
					playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
					return
				else
					for(var/obj/machinery/telecomms/T in links)
						T.links.Remove(src)
					network = params["value"]
					links = list()
					log_game("[key_name(operator)] has changed the network for [src] at [AREACOORD(src)] to [network].")
					. = TRUE
		if("tempfreq")
			if(params["value"])
				tempfreq = text2num(params["value"]) * 10
		if("freq")
			var/newfreq = tempfreq * 10
			if(newfreq == FREQ_SYNDICATE)
				to_chat(operator, "<span class='warning'>Error: Interference preventing filtering frequency: \"[newfreq / 10] GHz\"</span>")
				playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
			else
				if(!(newfreq in freq_listening) && newfreq < 10000)
					freq_listening.Add(newfreq)
					log_game("[key_name(operator)] added frequency [newfreq] for [src] at [AREACOORD(src)].")
					. = TRUE
		if("delete")
			freq_listening.Remove(params["value"])
			log_game("[key_name(operator)] added removed frequency [params["value"]] for [src] at [AREACOORD(src)].")
			. = TRUE
		if("unlink")
			var/obj/machinery/telecomms/T = links[text2num(params["value"])]
			if(T)
				// Remove link entries from both T and src.
				if(T.links)
					T.links.Remove(src)
				links.Remove(T)
				log_game("[key_name(operator)] unlinked [src] and [T] at [AREACOORD(src)].")
				. = TRUE
		if("link")
			if(heldmultitool)
				var/obj/machinery/telecomms/T = heldmultitool.buffer
				if(istype(T) && T != src)
					if(!(src in T.links))
						T.links += src
					if(!(T in links))
						links += T
						log_game("[key_name(operator)] linked [src] for [T] at [AREACOORD(src)].")
						. = TRUE
		if("buffer")
			heldmultitool.buffer = src
			. = TRUE
		if("flush")
			heldmultitool.buffer = null
			. = TRUE

	add_act(action, params)
	. = TRUE

/obj/machinery/telecomms/proc/add_option()
	return

/obj/machinery/telecomms/bus/add_option()
	var/list/data = list()
	data["type"] = "bus"
	data["changefrequency"] = change_frequency
	return data

/obj/machinery/telecomms/relay/add_option()
	var/list/data = list()
	data["type"] = "relay"
	data["broadcasting"] = broadcasting
	data["receiving"] = receiving
	return data

/obj/machinery/telecomms/proc/add_act(action, params)

/obj/machinery/telecomms/relay/add_act(action, params)
	switch(action)
		if("broadcast")
			broadcasting = !broadcasting
			. = TRUE
		if("receive")
			receiving = !receiving
			. = TRUE

/obj/machinery/telecomms/bus/add_act(action, params)
	switch(action)
		if("change_freq")
			var/newfreq = text2num(params["value"]) * 10
			if(newfreq)
				if(newfreq < 10000)
					change_frequency = newfreq
					. = TRUE
				else
					change_frequency = 0

// Returns a multitool from a user depending on their mobtype.

/obj/machinery/telecomms/proc/get_multitool(mob/user)
	var/obj/item/multitool/P = null
	// Let's double check
	if(!issilicon(user) && istype(user.get_active_held_item(), /obj/item/multitool))
		P = user.get_active_held_item()
	else if(isAI(user))
		var/mob/living/silicon/ai/U = user
		P = U.aiMulti
	else if(iscyborg(user) && in_range(user, src))
		if(istype(user.get_active_held_item(), /obj/item/multitool))
			P = user.get_active_held_item()
	return P

/obj/machinery/telecomms/proc/canAccess(mob/user)
	if(issilicon(user) || in_range(user, src))
		return TRUE
	return FALSE


// Additional Options for certain machines. Use this when you want to add an option to a specific machine.
// Example of how to use below.

/obj/machinery/telecomms/proc/Options_Menu()
	return ""

// The topic for Additional Options. Use this for checking href links for your specific option.
// Example of how to use below.
/obj/machinery/telecomms/proc/Options_Topic(href, href_list)
	return

// RELAY

/obj/machinery/telecomms/relay/Options_Menu()
	var/dat = ""
	dat += "<br>Broadcasting: <A href='?src=[REF(src)];broadcast=1'>[broadcasting ? "YES" : "NO"]</a>"
	dat += "<br>Receiving:    <A href='?src=[REF(src)];receive=1'>[receiving ? "YES" : "NO"]</a>"
	return dat

/obj/machinery/telecomms/relay/Options_Topic(href, href_list)

	if(href_list["receive"])
		receiving = !receiving
		temp = "<font color = #666633>-% Receiving mode changed. %-</font>"
	if(href_list["broadcast"])
		broadcasting = !broadcasting
		temp = "<font color = #666633>-% Broadcasting mode changed. %-</font>"

// BUS

/obj/machinery/telecomms/bus/Options_Menu()
	var/dat = "<br>Change Signal Frequency: <A href='?src=[REF(src)];change_freq=1'>[change_frequency ? "YES ([change_frequency])" : "NO"]</a>"
	return dat

/obj/machinery/telecomms/bus/Options_Topic(href, href_list)

	if(href_list["change_freq"])

		var/newfreq = input(usr, "Specify a new frequency for new signals to change to. Enter null to turn off frequency changing. Decimals assigned automatically.", src, network) as null|num
		if(canAccess(usr))
			if(newfreq)
				if(findtext(num2text(newfreq), "."))
					newfreq *= 10 // shift the decimal one place
				if(newfreq < 10000)
					change_frequency = newfreq
					temp = "<font color = #666633>-% New frequency to change to assigned: \"[newfreq] GHz\" %-</font>"
			else
				change_frequency = 0
				temp = "<font color = #666633>-% Frequency changing deactivated %-</font>"


/obj/machinery/telecomms/Topic(href, href_list)
	if(..())
		return

	if(!issilicon(usr))
		if(!istype(usr.get_active_held_item(), /obj/item/multitool))
			return

	var/obj/item/multitool/P = get_multitool(usr)

	if(href_list["input"])
		switch(href_list["input"])

			if("toggle")

				toggled = !toggled
				temp = "<font color = #666633>-% [src] has been [toggled ? "activated" : "deactivated"].</font>"
				update_power()


			if("id")
				var/newid = reject_bad_text(stripped_input(usr, "Specify the new ID for this machine", src, id, MAX_MESSAGE_LEN))
				if(newid && canAccess(usr))
					id = newid
					temp = "<font color = #666633>-% New ID assigned: \"[id]\" %-</font>"

			if("network")
				var/newnet = stripped_input(usr, "Specify the new network for this machine. This will break all current links.", src, network)
				if(newnet && canAccess(usr))

					if(length(newnet) > 15)
						temp = "<font color = #666633>-% Too many characters in new network tag %-</font>"

					else
						for(var/obj/machinery/telecomms/T in links)
							T.links.Remove(src)

						network = newnet
						links = list()
						temp = "<font color = #666633>-% New network tag assigned: \"[network]\" %-</font>"


			if("freq")
				var/newfreq = input(usr, "Specify a new frequency to filter (GHz). Decimals assigned automatically.", src, network) as null|num
				if(newfreq && canAccess(usr))
					if(findtext(num2text(newfreq), "."))
						newfreq *= 10 // shift the decimal one place
					if(newfreq == FREQ_SYNDICATE)
						temp = "<font color = #FF0000>-% Error: Interference preventing filtering frequency: \"[newfreq] GHz\" %-</font>"
					else
						if(!(newfreq in freq_listening) && newfreq < 10000)
							freq_listening.Add(newfreq)
							temp = "<font color = #666633>-% New frequency filter assigned: \"[newfreq] GHz\" %-</font>"

	if(href_list["delete"])

		// changed the layout about to workaround a pesky runtime -- Doohl

		var/x = text2num(href_list["delete"])
		temp = "<font color = #666633>-% Removed frequency filter [x] %-</font>"
		freq_listening.Remove(x)

	if(href_list["unlink"])

		if(text2num(href_list["unlink"]) <= length(links))
			var/obj/machinery/telecomms/T = links[text2num(href_list["unlink"])]
			if(T)
				temp = "<font color = #666633>-% Removed [REF(T)] [T.name] from linked entities. %-</font>"

				// Remove link entries from both T and src.

				if(T.links)
					T.links.Remove(src)
				links.Remove(T)

			else
				temp = "<font color = #666633>-% Unable to locate machine to unlink from, try again. %-</font>"

	if(href_list["link"])

		if(P)
			var/obj/machinery/telecomms/T = P.buffer
			if(istype(T) && T != src)
				if(!(src in T.links))
					T.links += src

				if(!(T in links))
					links += T

				temp = "<font color = #666633>-% Successfully linked with [REF(T)] [T.name] %-</font>"

			else
				temp = "<font color = #666633>-% Unable to acquire buffer %-</font>"

	if(href_list["buffer"])

		P.buffer = src
		temp = "<font color = #666633>-% Successfully stored [REF(P.buffer)] [P.buffer.name] in buffer %-</font>"


	if(href_list["flush"])

		temp = "<font color = #666633>-% Buffer successfully flushed. %-</font>"
		P.buffer = null

	Options_Topic(href, href_list)

	usr.set_machine(src)

	updateUsrDialog()

