/* Contains:
 * /obj/item/rig_module/device
 * /obj/item/rig_module/device/plasmacutter
 * /obj/item/rig_module/device/healthscanner
 * /obj/item/rig_module/device/drill
 * /obj/item/rig_module/device/orescanner
 * /obj/item/rig_module/device/rcd
 * /obj/item/rig_module/device/anomaly_scanner
 * /obj/item/rig_module/maneuvering_jets
 * /obj/item/rig_module/foam_sprayer
 * /obj/item/rig_module/device/broadcaster
 * /obj/item/rig_module/chem_dispenser
 * /obj/item/rig_module/chem_dispenser/injector
 * /obj/item/rig_module/voice
 * /obj/item/rig_module/device/paperdispenser
 * /obj/item/rig_module/device/pen
 * /obj/item/rig_module/device/stamp
 */

/obj/item/rig_module/device
	name = "mounted device"
	desc = "Some kind of hardsuit mount."
	usable = 0
	selectable = 1
	toggleable = 0
	disruptive = 0
	price_tag = 200


	var/device_type
	var/obj/item/device

/obj/item/rig_module/device/healthscanner
	name = "health scanner module"
	desc = "A hardsuit-mounted health scanner."
	icon_state = "scanner"
	interface_name = "health scanner"
	interface_desc = "Shows an informative health readout when used on a subject."

	price_tag = 1250

	device_type = /obj/item/device/scanner/health/rig


/obj/item/rig_module/device/drill
	name = "hardsuit drill mount"
	desc = "A very heavy diamond-tipped drill."
	icon_state = "drill"
	interface_name = "mounted drill"
	interface_desc = "A diamond-tipped industrial drill."
	suit_overlay_active = "mounted-drill"
	suit_overlay_inactive = "mounted-drill"
	use_power_cost = 0.1

	price_tag = 1350

	device_type = /obj/item/tool/pickaxe/diamonddrill/rig

/obj/item/rig_module/device/anomaly_scanner
	name = "hardsuit anomaly scanner"
	desc = "You think it's called an Elder Sarsparilla or something."
	icon_state = "eldersasparilla"
	interface_name = "Alden-Saraspova counter"
	interface_desc = "An exotic particle detector commonly used by xenoarchaeologists."
	engage_string = "Begin Scan"
	usable = 1
	selectable = 0
	device_type = /obj/item/device/ano_scanner


/obj/item/rig_module/device/orescanner
	name = "ore scanner module"
	desc = "A clunky old ore scanner."
	icon_state = "scanner"
	interface_name = "ore detector"
	interface_desc = "A sonar system used to detect large masses of ore."
	engage_string = "Begin Scan"
	usable = 1
	selectable = 0
	device_type = /obj/item/device/scanner/mining

	price_tag = 850


/obj/item/rig_module/device/rcd
	name = "RCD mount"
	desc = "A cell-powered rapid construction device for a hardsuit."
	icon_state = "rcd"
	interface_name = "mounted RCD"
	interface_desc = "A device for building or removing walls. Cell-powered."
	usable = 1
	engage_string = "Configure RCD"
	price_tag = 1000

	device_type = /obj/item/rcd/mounted

/obj/item/rig_module/device/New()
	..()
	if(device_type) device = new device_type(src)

/obj/item/rig_module/device/engage(atom/target)
	if(!..() || !device)
		return 0

	if(!target)
		device.attack_self(holder.wearer)
		return 1

	var/turf/T = get_turf(target)
	if(istype(T) && !T.Adjacent(get_turf(src)))
		return 0

	var/resolved = target.attackby(device,holder.wearer)
	if(!resolved && device && target)
		device.afterattack(target,holder.wearer,1)
	return 1


/obj/item/rig_module/modular_injector
	name = "mounted modular dispenser"
	desc = "A specialized system for injecting chemicals."
	icon_state = "injector"
	usable = TRUE
	selectable = FALSE
	toggleable = FALSE
	disruptive = FALSE

	price_tag = 2250
	engage_string = "Inject"

	interface_name = "integrated dispenser"
	interface_desc = "A chemical dispenser"
	var/list/beakers = list()
	var/max_beakers = 5
	var/injection_amount = 5
	var/max_injection_amount = 20
	var/empties = 0
	var/initial_beakers = null
	/// ^ Used for initializing with beakers , the format used is list(beaker_type, beaker_reagent_id, beaker_reagent_amount)

	charges = list()

/obj/item/rig_module/modular_injector/Initialize()
	. = ..()
	if(initial_beakers)
		for(var/list/bdata in initial_beakers)
			var/btype = bdata[1]
			var/obj/item/reagent_containers/beaker = new btype(src)
			beaker.reagents.add_reagent(bdata[2], bdata[3])
			accepts_item(beaker, null , TRUE)
	//Just to update us
	rebuild_charges()

/obj/item/rig_module/modular_injector/New()
	..()
	//Just to update us
	rebuild_charges()

// Rebuilds charges , sad but necesarry due to how rig UI's get its data
/obj/item/rig_module/modular_injector/proc/rebuild_charges()
	empties = 0
	if(beakers && beakers.len)
		var/list/processed_charges = list()
		for(var/obj/item/reagent_containers/beaker in beakers)
			var/datum/rig_charge/charge_dat = new
			var/reag_name = beaker.reagents.get_master_reagent_name()
			empties++;

			charge_dat.short_name   = reag_name ? reag_name : "Empty[empties]"
			charge_dat.display_name = reag_name ? reag_name : "Empty[empties]"
			charge_dat.product_type = ref(beaker)
			charge_dat.charges      = beaker.reagents.total_volume

			if(!charge_selected) charge_selected = charge_dat.short_name
			processed_charges[charge_dat.short_name] = charge_dat

		charges = processed_charges


/obj/item/rig_module/modular_injector/accepts_item(obj/item/reagent_containers/item, mob/living/user, userless = FALSE)
	if(!istype(item))
		return FALSE
	if(beakers.len == max_beakers)
		to_chat(user, "\The [src] has all its beaker slots filled, remove one of them!")
		return FALSE
	if(userless)
		beakers += item
		rebuild_charges()
		item.forceMove(src)
		return TRUE
	if(user.unEquip(item))
		// Gotta keep it for later when we remove the beaker.
		beakers += item
		rebuild_charges()
		item.forceMove(src)


/obj/item/rig_module/modular_injector/attackby(obj/item/W, mob/user)
	if(..())
		return FALSE
	if(istype(W, /obj/item/reagent_containers))
		accepts_item(W, user)
		return FALSE
	if(W.get_tool_quality(QUALITY_SCREW_DRIVING))
		var/obj/item/reagent_containers/sel_ref = input(user, "Choose a beaker to remove", null) in beakers
		if(sel_ref)
			beakers -= sel_ref
			charge_selected = null
			rebuild_charges()
			user.visible_message("[user] removes \the [sel_ref.name] from \the [src]")
			if(!user.put_in_active_hand(sel_ref))
				sel_ref.loc = get_turf(src)
	if(W.get_tool_quality(QUALITY_BOLT_TURNING))
		var/amount = input(user, "Choose reagent injection amount", null) in list(0, initial(injection_amount), max_injection_amount * 0.5, max_injection_amount)
		if(amount != null)
			injection_amount = amount
			to_chat(user, "You set the injection amount to [amount] on \the [src]")
			user.visible_message("[user] tweaks the injection amount on \the [src]")

/obj/item/rig_module/modular_injector/engage(atom/target)

	if(!..())
		return FALSE

	var/mob/living/carbon/human/H = holder.wearer

	if(!charge_selected)
		to_chat(H, SPAN_DANGER("You have not selected a beaker to inject from!"))
		return FALSE

	var/datum/rig_charge/charge = charges[charge_selected]
	var/obj/item/reagent_containers/beaker = locate(charge.product_type)
	if(beaker.reagents.total_volume < injection_amount)
		to_chat(H, SPAN_DANGER("Insufficient chems!"))
		return FALSE

	var/mob/living/carbon/target_mob
	if(target)
		if(iscarbon(target))
			target_mob = target
		else
			return FALSE
	else
		target_mob = H

	if(target_mob != H)
		to_chat(H, SPAN_DANGER("You inject [target_mob] with [injection_amount] unit\s of [beaker.name]."))
	to_chat(target_mob, "<span class='danger'>You feel a rush in your veins as [injection_amount] unit\s of chemicals are injected in your bloodstream.</span>")
	// Update display
	beaker.reagents.trans_to_mob(target_mob, injection_amount, CHEM_BLOOD)
	rebuild_charges()
	return TRUE

/obj/item/rig_module/modular_injector/combat
	name = "mounted combat dispenser"
	desc = "A specialized system for injecting combat stimulants."
	price_tag = 7250
	max_injection_amount = 30
	max_beakers = 6
	initial_beakers = list(
		list(/obj/item/reagent_containers/glass/beaker/large, "hyperzine", 60),
		list(/obj/item/reagent_containers/glass/beaker/large, "tramadol", 60),
		list(/obj/item/reagent_containers/glass/beaker/large, "nutriment", 60),
		list(/obj/item/reagent_containers/glass/beaker/large, "tricordrazine", 60)
	)
	interface_name = "integrated chemical combat dispenser"
	interface_desc = "Dispenses loaded chemicals directly into the user's bloodstream."

/obj/item/rig_module/modular_injector/medical
	name = "mounted medical injector"
	desc = "A specialized system for injecting chemicals in patients."
	price_tag = 3750
	max_injection_amount = 60
	max_beakers = 6
	usable = 0
	selectable = 1
	disruptive = 1
	initial_beakers = list(
		list(/obj/item/reagent_containers/glass/beaker/large, "inaprovaline",60),
		list(/obj/item/reagent_containers/glass/beaker/large, "dexalinp",60),
		list(/obj/item/reagent_containers/glass/beaker/large, "tramadol",60),
		list(/obj/item/reagent_containers/glass/beaker/large, "bicaridine", 60),
		list(/obj/item/reagent_containers/glass/beaker/large, "kelotane",60),
		list(/obj/item/reagent_containers/glass/beaker/large, "anti_toxin", 60),
		list(/obj/item/reagent_containers/glass/beaker/large, "spaceacillin", 60)
	)
	interface_name = "integrated chemical injector"
	interface_desc = "Dispenses loaded chemicals directly into the bloodstream of its target. Can be used on the wearer as well."
/*
/obj/item/rig_module/chem_dispenser
	name = "mounted chemical dispenser"
	desc = "A complex web of tubing and needles suitable for hardsuit use."
	icon_state = "injector"
	usable = 1
	selectable = 0
	toggleable = 0
	disruptive = 0

	price_tag = 2250

	engage_string = "Inject"

	interface_name = "integrated chemical dispenser"
	interface_desc = "Dispenses loaded chemicals directly into the wearer's bloodstream."

	charges = list(
		list("tricordrazine", "tricordrazine", 0, 80),
		list("tramadol",      "tramadol",      0, 80),
		list("dexalin plus",  "dexalinp",      0, 80),
		list("antibiotics",   "spaceacillin",  0, 80),
		list("antitoxins",    "anti_toxin",    0, 80),
		list("nutrients",     "glucose",     0, 80),
		list("hyronalin",     "hyronalin",     0, 80),
		list("radium",        "radium",        0, 80)
		)

	var/max_reagent_volume = 80 //Used when refilling.

/obj/item/rig_module/chem_dispenser/ninja
	name = "compact chem dispenser"
	desc = "A normal chemical dispenser but much smaller and tighter."
	interface_desc = "Dispenses loaded chemicals directly into the wearer's bloodstream. This variant is made to be extremely light and flexible."

	price_tag = 1500//Its trash

	//just over a syringe worth of each. Want more? Go refill. Gives the ninja another reason to have to show their face.
	charges = list(
		list("tricordrazine", "tricordrazine", 0, 20),
		list("tramadol",      "tramadol",      0, 20),
		list("dexalin plus",  "dexalinp",      0, 20),
		list("antibiotics",   "spaceacillin",  0, 20),
		list("antitoxins",    "anti_toxin",    0, 20),
		list("nutrients",     "glucose",     0, 80),
		list("hyronalin",     "hyronalin",     0, 20),
		list("radium",        "radium",        0, 20)
		)

/obj/item/rig_module/chem_dispenser/accepts_item(var/obj/item/input_item, var/mob/living/user)

	if(!input_item.is_drainable())
		return 0

	if(!input_item.reagents || !input_item.reagents.total_volume)
		to_chat(user, "\The [input_item] is empty.")
		return 0

	// Magical chemical filtration system, do not question it.
	var/total_transferred = 0
	for(var/datum/reagent/R in input_item.reagents.reagent_list)
		for(var/chargetype in charges)
			var/datum/rig_charge/charge = charges[chargetype]
			if(charge.display_name == R.id)

				var/chems_to_transfer = R.volume

				if((charge.charges + chems_to_transfer) > max_reagent_volume)
					chems_to_transfer = max_reagent_volume - charge.charges

				charge.charges += chems_to_transfer
				input_item.reagents.remove_reagent(R.id, chems_to_transfer)
				total_transferred += chems_to_transfer

				break

	if(total_transferred)
		to_chat(user, "<font color='blue'>You transfer [total_transferred] units into the suit reservoir.</font>")
	else
		to_chat(user, SPAN_DANGER("None of the reagents seem suitable."))
	return 1

/obj/item/rig_module/chem_dispenser/engage(atom/target)

	if(!..())
		return 0

	var/mob/living/carbon/human/H = holder.wearer

	if(!charge_selected)
		to_chat(H, SPAN_DANGER("You have not selected a chemical type."))
		return 0

	var/datum/rig_charge/charge = charges[charge_selected]

	if(!charge)
		return 0

	var/chems_to_use = 5
	if(charge.charges <= 0)
		to_chat(H, SPAN_DANGER("Insufficient chems!"))
		return 0
	else if(charge.charges < chems_to_use)
		chems_to_use = charge.charges

	var/mob/living/carbon/target_mob
	if(target)
		if(iscarbon(target))
			target_mob = target
		else
			return 0
	else
		target_mob = H

	if(target_mob != H)
		to_chat(H, SPAN_DANGER("You inject [target_mob] with [chems_to_use] unit\s of [charge.display_name]."))
	to_chat(target_mob, "<span class='danger'>You feel a rushing in your veins as [chems_to_use] unit\s of [charge.display_name] [chems_to_use == 1 ? "is" : "are"] injected.</span>")
	target_mob.reagents.add_reagent(charge.display_name, chems_to_use)

	charge.charges -= chems_to_use
	if(charge.charges < 0) charge.charges = 0

	return 1

/obj/item/rig_module/chem_dispenser/combat

	name = "combat chemical injector"
	desc = "A complex web of tubing and needles suitable for hardsuit use."

	price_tag = 3500

	charges = list(
		list("synaptizine",   "synaptizine",   0, 30),
		list("hyperzine",     "hyperzine",     0, 30),
		list("oxycodone",     "oxycodone",     0, 30),
		list("nutrients",     "glucose",     0, 80),
		)

	interface_name = "combat chem dispenser"
	interface_desc = "Dispenses loaded chemicals directly into the bloodstream."


/obj/item/rig_module/chem_dispenser/injector
	name = "mounted chemical injector"
	desc = "A complex web of tubing and a large needle suitable for hardsuit use."
	usable = 0
	selectable = 1
	disruptive = 1

	price_tag = 3000

	interface_name = "mounted chem injector"
	interface_desc = "Dispenses loaded chemicals via an arm-mounted injector."
*/
/obj/item/rig_module/voice

	name = "hardsuit voice synthesiser"
	desc = "A speaker box and sound processor."
	icon_state = "megaphone"
	usable = 1
	selectable = 0
	toggleable = 0
	disruptive = 0

	price_tag = 2500

	engage_string = "Configure Synthesiser"

	interface_name = "voice synthesiser"
	interface_desc = "A flexible and powerful voice modulator system."

	var/obj/item/voice_changer/voice_holder

/obj/item/rig_module/voice/New()
	..()
	voice_holder = new(src)
	voice_holder.active = 0

/obj/item/rig_module/voice/installed()
	..()
	holder.speech = src

/obj/item/rig_module/voice/engage()

	if(!..())
		return 0

	var/choice= input("Would you like to toggle the synthesiser or set the name?") as null|anything in list("Enable","Disable","Set Name")

	if(!choice)
		return 0

	switch(choice)
		if("Enable")
			active = 1
			voice_holder.active = 1
			to_chat(usr, "<font color='blue'>You enable the speech synthesiser.</font>")
		if("Disable")
			active = 0
			voice_holder.active = 0
			to_chat(usr, "<font color='blue'>You disable the speech synthesiser.</font>")
		if("Set Name")
			var/raw_choice = sanitize(input(usr, "Please enter a new name.")  as text|null, MAX_NAME_LEN)
			if(!raw_choice)
				return 0
			voice_holder.voice = raw_choice
			to_chat(usr, "<font color='blue'>You are now mimicking <B>[voice_holder.voice]</B>.</font>")
	return 1

/obj/item/rig_module/maneuvering_jets

	name = "hardsuit maneuvering jets"
	desc = "A compact gas thruster system for a hardsuit."
	icon_state = "thrusters"
	usable = 1
	toggleable = 1
	selectable = 0
	disruptive = 0


	suit_overlay_active = "maneuvering_active"
	suit_overlay_inactive = null //"maneuvering_inactive"

	engage_string = "Toggle Stabilizers"
	activate_string = "Activate Thrusters"
	deactivate_string = "Deactivate Thrusters"

	interface_name = "maneuvering jets"
	interface_desc = "An inbuilt EVA maneuvering system that runs off the rig air supply."

	var/obj/item/tank/jetpack/rig/jets

/obj/item/rig_module/maneuvering_jets/engage()
	if(!..())
		return 0
	jets.toggle_rockets()
	return 1

/obj/item/rig_module/maneuvering_jets/activate()

	if(active)
		return 0

	active = 1

	spawn(1)
		if(suit_overlay_active)
			suit_overlay = suit_overlay_active
		else
			suit_overlay = null
		holder.update_icon()

	if(!jets.on)
		jets.toggle()
	return 1

/obj/item/rig_module/maneuvering_jets/deactivate()
	if(!..())
		return 0
	if(jets.on)
		jets.toggle()
	return 1

/obj/item/rig_module/maneuvering_jets/Initialize()
	. = ..()
	jets = new(src)

//Some slightly complex setup here to make hardsuit jetpacks work right
/obj/item/rig_module/maneuvering_jets/installed()
	..()
	//Holder is the rig core module, the thing the user is wearing
	jets.holder = holder

	//We set the jetpack's gastank to the core's internal airtank.
	//So the jetpack isn't really a tank but more of a pressure valve for another tank
	jets.gastank = holder.air_supply

	//Sets up the trail fx to track movement of the core module, and thusly the user
	jets.trail.set_up(holder)

	//Tells the trail that its jetpack isn't the core module, but the jets
	jets.trail.jetpack = jets

/obj/item/rig_module/maneuvering_jets/uninstalled()
	..()
	jets.holder = null
	jets.trail.set_up(jets)

/obj/item/rig_module/autodoc
	name = "autodoc module"
	desc = "A complex surgery system for almost all your needs."
	use_power_cost = 10
	active = 1
	usable = 1

	interface_name = "Autodoc"
	interface_desc = "Module with set of instruments that is capable to preform surgery on user"
	var/datum/autodoc/autodoc_processor
	var/autodoc_type = /datum/autodoc
	var/turf/wearer_loc = null

/obj/item/rig_module/autodoc/Initialize()
	. = ..()
	autodoc_processor = new autodoc_type(src)
	autodoc_processor.damage_heal_amount = 20

/obj/item/rig_module/autodoc/Destroy()
	QDEL_NULL(autodoc_processor)
	return ..()

/obj/item/rig_module/autodoc/engage()
	if(!..())
		return 0
	if(autodoc_processor.active)
		autodoc_processor.stop()
	autodoc_processor.set_patient(holder.wearer)
	nano_ui_interact(usr)
	return 1
/obj/item/rig_module/autodoc/Topic(href, href_list)
	return autodoc_processor.Topic(href, href_list)

/obj/item/rig_module/autodoc/Process()
	if(..())
		autodoc_processor.stop()
	if(autodoc_processor.active)
		if(wearer_loc == null)
			wearer_loc = get_turf(holder.wearer)
		if(wearer_loc != get_turf(holder.wearer))
			autodoc_processor.fail()
		passive_power_cost = 5
		engage_string = "Abort operations"
	else
		engage_string = "Interact"
		passive_power_cost = 0
		wearer_loc = null

/obj/item/rig_module/autodoc/nano_ui_interact(mob/user, ui_key, datum/nanoui/ui, force_open, datum/nanoui/master_ui, datum/nano_topic_state/state = GLOB.deep_inventory_state)
	autodoc_processor.nano_ui_interact(user, ui_key, ui, force_open, state = GLOB.deep_inventory_state)
/obj/item/rig_module/autodoc/activate()
	return
/obj/item/rig_module/autodoc/deactivate()
	return

/obj/item/rig_module/autodoc/commercial
	autodoc_type = /datum/autodoc/capitalist_autodoc


/obj/item/rig_module/cargo_clamp
	name = "hardsuit cargo clamp"
	desc = "A pair of folding arm-mounted clamps for a hardsuit, meant for loading crates and other large objects. Due to its bulky nature, precludes the installation of most hardsuit weaponry."
	icon_state = "clamp"
	interface_name = "cargo handler"
	interface_desc = "A set of folding clamps loaded to a counterbalanced storage unit. Can load various large objects."
	usable = 1
	use_power_cost = 1
	selectable = 1
	engage_string = "unload cargo"
	price_tag = 600
	mutually_exclusive_modules = list(/obj/item/rig_module/mounted, /obj/item/rig_module/held)
	var/cargo_max = 6//this module has 5 things in contents by default(ui elements), this gives it 5 capacity for other things


/obj/item/rig_module/cargo_clamp/engage(atom/target)
	if(!..())
		return FALSE

	if(!target)
		for(var/obj/structure/struct in contents)
			struct.forceMove(get_turf(src))
		return TRUE

	if(contents.len > cargo_max)
		to_chat(usr, SPAN_WARNING("The cargo compartment on [src] is full!"))
		return FALSE
	var/turf/T = get_turf(target)
	if(istype(T) && !T.Adjacent(get_turf(src)))
		return FALSE

	if(!istype(target, /obj/structure))
		return FALSE

	var/obj/structure/loading_item = target
	if(loading_item.anchored)
		if(istype(loading_item, /obj/structure/scrap))
			var/obj/structure/scrap/tocube = loading_item
			if(!do_after(usr, 2 SECONDS, tocube))
				return FALSE
			tocube.make_cube()
		return FALSE
	for(var/O in loading_item.contents)
		if(istype(O, /mob/living))
			to_chat(usr, SPAN_WARNING("Living creatures detected. Cargo loading stopped."))
			return
	to_chat(usr, SPAN_NOTICE("You begin loading [loading_item] into [src]."))
	if(do_after(usr, 2 SECONDS, loading_item))
		loading_item.forceMove(src)
		to_chat(usr, SPAN_NOTICE("You load [loading_item] into [src]."))

/obj/item/rig_module/cargo_clamp/uninstalled()
	..()
	visible_message(SPAN_WARNING("All the loaded cargo falls out of [src]!"))
	for(var/obj/structure/struct in contents)
		struct.forceMove(get_turf(src))

/obj/item/rig_module/cargo_clamp/large
	name = "large hardsuit cargo clamp"
	desc = "A pair of folding arm-mounted clamps for a hardsuit, meant for loading crates and other large objects. This one is a Lonestar design, capable of holding a little more cargo."
	cargo_max = 8
	price_tag = 1600 //can't be obtained outside of purchasing, so higher price is a detriment
	mutually_exclusive_modules = list(/obj/item/rig_module/mounted, /obj/item/rig_module/held, /obj/item/rig_module/cargo_clamp)





/obj/item/rig_module/grappler
	name = "hardsuit grappler"
	desc = "A ten-meter tether connected to a heavy winch and grappling hook. Can pull things towards you, can pull you towards things."
	icon_state = "tether"
	interface_name = "grappler"
	interface_desc = "Fire the grapple to reel things in."
	engage_string = "grapple"
	selectable = 1
	price_tag = 1000
	use_power_cost = 10
	var/max_range = 10
	var/last_use
	var/cooldown_time = 1 SECOND
	var/obj/item/gun/energy/grappler/launcher //we're not a subtype of /mounted/ for cooldown handling reasons mostly

/obj/item/rig_module/grappler/Initialize()
	..()
	launcher = new /obj/item/gun/energy/grappler(src)


/obj/item/rig_module/grappler/engage(atom/target)
	if(!..())
		return FALSE
	if(!target)
		return FALSE
	if(world.time < last_use + cooldown_time || get_dist(target, usr) > max_range)
		return FALSE

	cooldown_time = 1 SECOND
	launcher.Fire(target,holder.wearer)
	last_use = world.time
	if(ismob(target))
		cooldown_time = 10 SECONDS //10x longer cooldown on hooking people, so you can't grapplelock them as easily