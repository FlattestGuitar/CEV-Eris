/obj/item/weapon/gun/projectile/automatic //Hopefully someone will find a way to make these fire in bursts or something. --Superxpdude
	name = "prototype SMG"
	desc = "A prototype lightweight, fast firing gun. Uses 9mm rounds."
	icon_state = "generic_smg"
	w_class = ITEM_SIZE_NORMAL
	load_method = SPEEDLOADER //yup. until someone sprites a magazine for it.
	max_shells = 22
	caliber = "9mm"
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 2)
	slot_flags = SLOT_BELT
	ammo_type = /obj/item/ammo_casing/c9mm
	multi_aim = 1
	burst_delay = 2
	fire_sound = 'sound/weapons/guns/fire/smg_fire.ogg'
	unload_sound = 'sound/weapons/guns/interact/smg_magout.ogg'
	reload_sound = 'sound/weapons/guns/interact/smg_magin.ogg'
	cocked_sound = 'sound/weapons/guns/interact/smg_cock.ogg'

	firemodes = list(
		FULL_AUTO_400,
		list(mode_name="semiauto",       burst=1, fire_delay=0,     dispersion=null),
		list(mode_name="3-round bursts", burst=3, fire_delay=null,     dispersion=list(0.0, 0.6, 1.0)),
		list(mode_name="short bursts",   burst=5, fire_delay=null,     dispersion=list(0.6, 1.0, 1.0, 1.0, 1.2)),
		)


//Automatic firing
//Todo: Way more checks and safety here
/datum/firemode/automatic
	settings = list(burst = 1, suppress_delay_warning = TRUE, dispersion=list(0.6, 1.0, 1.0, 1.0, 1.2))
	//The full auto clickhandler we have
	var/datum/click_handler/fullauto/CH = null

/datum/firemode/automatic/update(var/force_state = null)
	var/mob/living/L
	if (gun && gun.is_held())
		L = gun.loc

	var/enable = FALSE
	//Force state is used for forcing it to be disabled in circumstances where it'd normally be valid
	if (!isnull(force_state))
		enable = force_state
	else if (L && L.client)

		//First of all, lets determine whether we're enabling or disabling the click handler


		//We enable it if the gun is held in the user's active hand and the safety is off
		if (L.get_active_hand() == gun)
			//Lets also make sure it can fire
			var/can_fire = TRUE

			//Safety stops it
			if (gun.safety)
				can_fire = FALSE

			//Projectile weapons need to have enough ammo to fire
			if(istype(gun, /obj/item/weapon/gun/projectile))
				var/obj/item/weapon/gun/projectile/P = gun
				if (!P.get_ammo())
					can_fire = FALSE

			//TODO: Centralise all this into some can_fire proc
			if (can_fire)
				enable = TRUE
		else
			enable = FALSE

	//Ok now lets set the desired state
	if (!enable)
		if (!CH)
			//If we're turning it off, but the click handler doesn't exist, then we have nothing to do
			return

		//Todo: make client click handlers into a list
		if (CH.owner) //Remove our handler from the client
			CH.owner.CH = null //wew
		QDEL_NULL(CH) //And delete it
		return

	else
		//We're trying to turn things on
		if (CH)
			return //The click handler exists, we dont need to do anything


		//Create and assign the click handler
		//A click handler intercepts mouseup/drag/down events which allow fullauto firing
		CH = new /datum/click_handler/fullauto()
		CH.reciever = gun //Reciever is the gun that gets the fire events
		L.client.CH = CH //Put it on the client
		CH.owner = L.client //And tell it where it is