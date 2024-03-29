// UI menu navigation
#define HOME "home"
#define LIST "list"
#define ENTRY "entry"

/obj/machinery/disease2/isolator/
	name = "pathogenic isolator"
	density = 1
	anchored = 1
	icon = 'icons/obj/virology.dmi'
	icon_state = "isolator"
	var/isolating = 0
	var/state = HOME
	var/datum/disease2/disease/virus2 = null
	var/datum/data/record/entry = null
	var/obj/item/reagent_containers/syringe/sample = null

/obj/machinery/disease2/isolator/update_icon()
	if (stat & (BROKEN|NOPOWER))
		icon_state = "isolator"
		return

	if (isolating)
		icon_state = "isolator_processing"
	else if (sample)
		icon_state = "isolator_in"
	else
		icon_state = "isolator"

/obj/machinery/disease2/isolator/attackby(var/obj/O as obj, var/mob/user)
	if(!istype(O,/obj/item/reagent_containers/syringe)) return
	//var/obj/item/reagent_containers/syringe/S = O

	if(sample)
		to_chat(user, "\The [src] is already loaded.")
		return
	else
		to_chat(user, "\The [src] has a slot for a syringe style you've never seen before.")
/* Currently bugged. Unable to interact with machine after inserting syringe. Quick fix of not being able to insert anything for now. ~Aeger
	sample = S
	user.drop_item()
	S.loc = src

	user.visible_message("[user] adds \a [O] to \the [src]!", "You add \a [O] to \the [src]!")
	SSnano.update_uis(src)
	update_icon()

	src.attack_hand(user)
*/

/obj/machinery/disease2/isolator/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN)) return
	nano_ui_interact(user)

/obj/machinery/disease2/isolator/nano_ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = NANOUI_FOCUS)
	user.set_machine(src)

	var/data[0]
	data["syringe_inserted"] = !!sample
	data["isolating"] = isolating
	data["pathogen_pool"] = null
	data["state"] = state
	data["entry"] = entry
	data["can_print"] = (state != HOME || sample) && !isolating

	switch (state)
		if (HOME)
			if (sample)
				var/list/pathogen_pool[0]
				for(var/datum/reagent/organic/blood/B in sample.reagents.reagent_list)
					var/list/virus = B.data["virus2"]
					for (var/ID in virus)
						var/datum/disease2/disease/V = virus[ID]
						var/datum/data/record/R = null
						if (ID in virusDB)
							R = virusDB[ID]

						var/mob/living/carbon/human/D = B.data["donor"]
						pathogen_pool.Add(list(list(\
							"name" = "[D.get_species()] [B.name]", \
							"dna" = B.data["blood_DNA"], \
							"unique_id" = V.uniqueID, \
							"reference" = "\ref[V]", \
							"is_in_database" = !!R, \
							"record" = "\ref[R]")))

				if (pathogen_pool.len > 0)
					data["pathogen_pool"] = pathogen_pool

		if (LIST)
			var/list/db[0]
			for (var/ID in virusDB)
				var/datum/data/record/r = virusDB[ID]
				db.Add(list(list("name" = r.fields["name"], "record" = "\ref[r]")))

			if (db.len > 0)
				data["database"] = db

		if (ENTRY)
			if (entry)
				var/desc = entry.fields["description"]
				data["entry"] = list(\
					"name" = entry.fields["name"], \
					"description" = replacetext(desc, "\n", ""))

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "pathogenic_isolator.tmpl", src.name, 400, 500)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/disease2/isolator/Process()
	if (isolating > 0)
		isolating -= 1
		if (isolating == 0)
			if (virus2)
				var/obj/item/virusdish/d = new /obj/item/virusdish(src.loc)
				d.virus2 = virus2.getcopy()
				virus2 = null
				ping("\The [src] pings, \"Viral strain isolated.\"")

			SSnano.update_uis(src)
			update_icon()

/obj/machinery/disease2/isolator/Topic(href, href_list)
	if (..()) return 1

	var/mob/user = usr
	var/datum/nanoui/ui = SSnano.get_open_ui(user, src, "main")

	if (href_list["close"])
		user.unset_machine()
		ui.close()
		return 0

	if (href_list[HOME])
		state = HOME
		return 1

	if (href_list[LIST])
		state = LIST
		return 1

	if (href_list[ENTRY])
		if (istype(locate(href_list["view"]), /datum/data/record))
			entry = locate(href_list["view"])

		state = ENTRY
		return 1

	if (href_list["print"])
		print(user)
		return 1

	if(!sample) return 1

	if (href_list["isolate"])
		var/datum/disease2/disease/V = locate(href_list["isolate"])
		if (V)
			virus2 = V
			isolating = 20
			update_icon()
		return 1

	if (href_list["eject"])
		sample.loc = src.loc
		sample = null
		update_icon()
		return 1

/obj/machinery/disease2/isolator/proc/print(var/mob/user)
	var/obj/item/paper/P = new /obj/item/paper(loc)

	switch (state)
		if (HOME)
			if (!sample) return
			P.name = "paper - Patient Diagnostic Report"
			P.info = {"
				[virology_letterhead("Patient Diagnostic Report")]
				<center><small><font color='red'><b>CONFIDENTIAL MEDICAL REPORT</b></font></small></center><br>
				<large><u>Sample:</u></large> [sample.name]<br>
"}

			if (user)
				P.info += "<u>Generated By:</u> [user.name]<br>"

			P.info += "<hr>"

			for(var/datum/reagent/organic/blood/B in sample.reagents.reagent_list)
				var/mob/living/carbon/human/D = B.data["donor"]
				P.info += "<large><u>[D.get_species()] [B.name]:</u></large><br>[B.data["blood_DNA"]]<br>"

				var/list/virus = B.data["virus2"]
				P.info += "<u>Pathogens:</u> <br>"
				if (virus.len > 0)
					for (var/ID in virus)
						var/datum/disease2/disease/V = virus[ID]
						P.info += "[V.name()]<br>"
				else
					P.info += "None<br>"

			P.info += {"
			<hr>
			<u>Additional Notes:</u>&nbsp;
"}

		if (LIST)
			P.name = "paper - Virus List"
			P.info = {"
				[virology_letterhead("Virus List")]
"}

			var/i = 0
			for (var/ID in virusDB)
				i++
				var/datum/data/record/r = virusDB[ID]
				P.info += "[i]. " + r.fields["name"]
				P.info += "<br>"

			P.info += {"
			<hr>
			<u>Additional Notes:</u>&nbsp;
"}

		if (ENTRY)
			P.name = "paper - Viral Profile"
			P.info = {"
				[virology_letterhead("Viral Profile")]
				[entry.fields["description"]]
				<hr>
				<u>Additional Notes:</u>&nbsp;
"}

	state("The nearby computer prints out a report.")