/obj/item/youtuberadio
	name = "youtube radio"
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	inhand_icon_state = "walkietalkie"
	worn_icon_state = "radio"
	desc = "A handheld radio that can transmit Telenet Streams."
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	dog_fashion = /datum/dog_fashion/back

	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_SMALL

	var/playing = 0


/obj/item/youtuberadio/attack_self(mob/user)

// need youtube dl command to just get audio

// youtube-dl -x --audio-format mp3 https://www.youtube.com/watch?v=uWusmdmc0to



	var/ytdl = CONFIG_GET(string/invoke_youtubedl)

	if(playing == 0)


		var/web_sound_input = input("Enter content URL (supported sites only, leave blank to stop playing)", "Play Internet Sound via youtube-dl") as text|null
		if(istext(web_sound_input))
			var/web_sound_url = ""
			var/stop_web_sounds = FALSE
			var/list/music_extra_data = list()
			if(length(web_sound_input))

				web_sound_input = trim(web_sound_input)
				if(findtext(web_sound_input, ":") && !findtext(web_sound_input, GLOB.is_http_protocol))
					to_chat(src, "<span class='boldwarning'>Non-http(s) URIs are not allowed.</span>", confidential = TRUE)
					to_chat(src, "<span class='warning'>For youtube-dl shortcuts like ytsearch: please use the appropriate full url from the website.</span>", confidential = TRUE)
					return
				var/shell_scrubbed_input = shell_url_scrub(web_sound_input)
				// var/list/output = world.shelleo("[ytdl] --geo-bypass --format \"bestaudio\[ext=mp3]/best\[ext=mp4]\[height<=360]/bestaudio\[ext=m4a]/bestaudio\[ext=aac]\" --dump-single-json --no-playlist -- \"[shell_scrubbed_input]\"")


				var/list/output = world.shelleo("[ytdl] -x --audio-format mp3 \"[shell_scrubbed_input]\"")

				// Either save as a predictable


				var/errorlevel = output[SHELLEO_ERRORLEVEL]
				to_chat(world, "1")
				to_chat(world, errorlevel)

				var/stdout = output[SHELLEO_STDOUT]

				to_chat(world, "2")
				to_chat(world, stdout)

				var/stderr = output[SHELLEO_STDERR]

				to_chat(world, "3")
				to_chat(world, stderr)

				// The video should be saving somewhere - I need to grab the mp3 then pipe it
				// Where is it DLing?




		// 		if(!errorlevel)
		// 			var/list/data
		// 			try
		// 				data = json_decode(stdout)
		// 			catch(var/exception/e)
		// 				to_chat(src, "<span class='boldwarning'>Youtube-dl JSON parsing FAILED:</span>", confidential = TRUE)
		// 				to_chat(src, "<span class='warning'>[e]: [stdout]</span>", confidential = TRUE)
		// 				return

		// 			if (data["url"])
		// 				web_sound_url = data["url"]
		// 				var/title = "[data["title"]]"
		// 				var/webpage_url = title
		// 				if (data["webpage_url"])
		// 					webpage_url = "<a href=\"[data["webpage_url"]]\">[title]</a>"
		// 				music_extra_data["start"] = data["start_time"]
		// 				music_extra_data["end"] = data["end_time"]
		// 				music_extra_data["link"] = data["webpage_url"]
		// 				music_extra_data["title"] = data["title"]

		// 				var/res = alert(usr, "Show the title of and link to this song to the players?\n[title]",, "No", "Yes", "Cancel")
		// 				switch(res)
		// 					if("Yes")
		// 						to_chat(world, "<span class='boldannounce'>An admin played: [webpage_url]</span>", confidential = TRUE)
		// 					if("Cancel")
		// 						return

		// 				SSblackbox.record_feedback("nested tally", "played_url", 1, list("[ckey]", "[web_sound_input]"))
		// 				log_admin("[key_name(src)] played web sound: [web_sound_input]")
		// 				message_admins("[key_name(src)] played web sound: [web_sound_input]")
		// 		else
		// 			to_chat(src, "<span class='boldwarning'>Youtube-dl URL retrieval FAILED:</span>", confidential = TRUE)
		// 			to_chat(src, "<span class='warning'>[stderr]</span>", confidential = TRUE)

		// 	else //pressed ok with blank
		// 		log_admin("[key_name(src)] stopped web sound")
		// 		message_admins("[key_name(src)] stopped web sound")
		// 		web_sound_url = null
		// 		stop_web_sounds = TRUE

		// 	if(web_sound_url && !findtext(web_sound_url, GLOB.is_http_protocol))
		// 		to_chat(src, "<span class='boldwarning'>BLOCKED: Content URL not using http(s) protocol</span>", confidential = TRUE)
		// 		to_chat(src, "<span class='warning'>The media provider returned a content URL that isn't using the HTTP or HTTPS protocol</span>", confidential = TRUE)
		// 		return
		// 	if(web_sound_url || stop_web_sounds)
		// 		for(var/m in GLOB.player_list)
		// 			var/mob/M = m
		// 			var/client/C = M.client
		// 			if(C.prefs.toggles & SOUND_MIDI)
		// 				if(!stop_web_sounds)
		// 					C.tgui_panel?.play_music(web_sound_url, music_extra_data)
		// 				else
		// 					C.tgui_panel?.stop_music()

		// SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Internet Sound")
