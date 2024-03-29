// Simple holder for each floor in the lift.
/datum/turbolift_stop
	var/area_ref
	var/label
	var/name
	var/announce_str
	var/arrival_sound
	var/delay_time

	var/list/doors = list()
	var/obj/structure/lift/button/ext_panel

/datum/turbolift_stop/proc/set_area_ref(var/ref)
	var/area/turbolift/A = locate(ref)
	if(!istype(A))
		log_debug("Turbolift floor area was of the wrong type: ref=[ref]")
		return

	area_ref = ref
	label = A.lift_floor_label
	name = A.lift_floor_name ? A.lift_floor_name : A.name
	announce_str = A.lift_announce_str
	arrival_sound = A.arrival_sound
	delay_time = A.delay_time

//called when a lift has queued this floor as a destination
/datum/turbolift_stop/proc/pending_move(var/datum/turbolift/lift)
	if(ext_panel)
		ext_panel.light_up()

//called when a lift arrives at this floor
/datum/turbolift_stop/proc/arrived(var/datum/turbolift/lift)
	if(!lift.fire_mode)
		lift.open_doors(src)
	if(ext_panel)
		ext_panel.reset()