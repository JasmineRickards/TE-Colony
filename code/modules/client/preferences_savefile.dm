#define SAVEFILE_VERSION_MIN	8
#define SAVEFILE_VERSION_MAX	18

/datum/preferences/proc/load_path(ckey,filename="preferences.sav")
	if(!ckey)	return
	path = "data/player_saves/[copytext(ckey,1,2)]/[ckey]/[filename]"
	savefile_version = SAVEFILE_VERSION_MAX

/datum/preferences/proc/load_preferences()
	if(!path)				return 0
	if(!check_cooldown())
		if(istype(client))
			to_chat(client, SPAN_WARNING("You're attempting to load your preferences a little too fast. Wait half a second, then try again."))
		return 0
	if(!fexists(path))		return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"

	S["version"] >> savefile_version
	player_setup.load_preferences(S)
	loaded_preferences = S
	return 1

/datum/preferences/proc/save_preferences(var/announce = 1)
	if(!path)				return 0
	if(!check_cooldown())
		if(istype(client))
			to_chat(client, SPAN_WARNING("You're attempting to save your preferences a little too fast. Wait half a second, then try again."))
			log_and_message_admins("[key_name(usr)] has saved their preferences really fast and was stopped.")
		return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"
	if(announce)
		log_and_message_admins("[key_name(usr)] has saved their preferences.")

	S["version"] << SAVEFILE_VERSION_MAX
	player_setup.save_preferences(S)
	loaded_preferences = S
	return 1

/datum/preferences/proc/load_character(slot)
	if(!path)				return 0
	if(!check_cooldown())
		if(istype(client))
			to_chat(client, SPAN_WARNING("You're attempting to load your character a little too fast. Wait half a second, then try again."))
			log_and_message_admins("[key_name(usr)] has loaded a character too fast and was stopped.")
		return 0

	if(!fexists(path))		return 0

	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"
	if(!slot)	slot = default_slot

	if(slot != SAVE_RESET) // SAVE_RESET will reset the slot as though it does not exist, but keep the current slot for saving purposes.
		slot = sanitize_integer(slot, 1, config.character_slots, initial(default_slot))
		if(slot != default_slot)
			default_slot = slot
			S["default_slot"] << slot
	else
		S["default_slot"] << default_slot

	if(slot != SAVE_RESET)
		S.cd = GLOB.maps_data.character_load_path(S, slot)
		player_setup.load_character(S)
	else
		player_setup.load_character(S)
		S.cd = GLOB.maps_data.character_load_path(S, default_slot)

	loaded_character = S
	log_and_message_admins("[key_name(usr)] has loaded a character.")

	return 1

/datum/preferences/proc/save_character()
	if(!path)				return 0
	if(!check_cooldown())
		if(istype(client))
			to_chat(client, SPAN_WARNING("You're attempting to save your character a little too fast. Wait half a second, then try again."))
			log_and_message_admins("[key_name(usr)] has saved a character really fast and was stopped.")
		return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = GLOB.maps_data.character_save_path(default_slot)

	S["version"] << SAVEFILE_VERSION_MAX
	player_setup.save_character(S)
	loaded_character = S
	log_and_message_admins("[key_name(usr)] has saved a character.")
	return S

/datum/preferences/proc/sanitize_preferences()
	player_setup.sanitize_setup()
	return 1

/datum/preferences/proc/overwrite_character(slot)
	if(!path)				return 0
	if(!fexists(path))		return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	if(!slot)	slot = default_slot
	if(slot != SAVE_RESET)
		slot = sanitize_integer(slot, 1, config.character_slots, initial(default_slot))
		if(slot != default_slot)
			default_slot = slot
			S["default_slot"] << slot
	else
		S["default_slot"] << default_slot

	return 1


/datum/preferences/proc/update_setup(var/savefile/preferences, var/savefile/character)
	if(!preferences || !character)
		return 0
	return player_setup.update_setup(preferences, character)

#undef SAVEFILE_VERSION_MAX
#undef SAVEFILE_VERSION_MIN
