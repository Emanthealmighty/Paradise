/mob/living/simple_animal/hostile/alien
	name = "alien hunter"
	desc = "A strange alien. This one seems to be able to move really quickly."
	icon = 'icons/mob/alien.dmi'
	icon_state = "alienh_running"
	icon_living = "alienh_running"
	icon_dead = "alienh_dead"
	icon_gib = "syndicate_gib"
	response_help = "pokes the"
	response_disarm = "shoves the"
	response_harm = "hits the"
	speed = 0
	butcher_results = list(/obj/item/reagent_containers/food/snacks/xenomeat = 3)
	maxHealth = 100
	health = 50 //Aliens spawn with 50% health, and then regain it by standing on weeds.
	harm_intent_damage = 5
	obj_damage = 60
	melee_damage_lower = 25
	melee_damage_upper = 25
	attacktext = "slashes"
	speak_emote = list("hisses")
	a_intent = INTENT_HARM
	attack_sound = 'sound/weapons/bladeslice.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	heat_damage_per_tick = 20
	pressure_resistance = 100    //100 kPa difference required to push
	throw_pressure_limit = 120   //120 kPa difference required to throw
	faction = list("alien")
	status_flags = CANPUSH
	minbodytemp = 0
	see_in_dark = 8
	see_invisible = SEE_INVISIBLE_MINIMUM
	gold_core_spawnable = CHEM_MOB_SPAWN_HOSTILE
	death_sound = 'sound/voice/hiss6.ogg'
	deathmessage = "lets out a waning guttural screech, green blood bubbling from its maw..."


/mob/living/simple_animal/hostile/alien/drone
	name = "alien drone"
	desc = "A strange alien. This one seems to be less adept at fighting."
	icon_state = "aliend_running"
	icon_living = "aliend_running"
	icon_dead = "aliend_dead"
	health = 30 //Aliens spawn with 50% health, and then regain it by standing on weeds.
	maxHealth = 60
	melee_damage_lower = 15
	melee_damage_upper = 15
	var/plant_cooldown = 30
	var/plants_off = 0
	var/mob/living/carbon/eat_target
	var/biomass = 0
	var/busy = 0 // 1 is Moving to target, 2 is Eating

/mob/living/simple_animal/hostile/alien/drone/Life()
	if(stat != DEAD)
		plant_cooldown--

/mob/living/simple_animal/hostile/alien/drone/handle_automated_action()
	if(..())
		if((AIStatus == AI_IDLE) && (!client))
			if(!plants_off && prob(10) && plant_cooldown<=0)
				plant_cooldown = initial(plant_cooldown)
				SpreadPlants()
		if((AIStatus == AI_IDLE) && (!client))
			var/list/can_see = view(src, 10)
			if((busy == 0) && (AIStatus == AI_IDLE) && prob(30) && (!eat_target))	//30% chance to stop wandering and eat something
				for(var/mob/living/carbon/C in can_see)
					if((C.stat == DEAD) && (!istype(C,/mob/living/carbon/alien)))
						busy = 1
						eat_target = C
						AIStatus = AI_ON
						Goto(C, move_to_delay)
						GiveUp(C)
						return
			if(busy == 1 && eat_target)
				if(Adjacent(eat_target))
					busy = 2
					Eat()
		if((AIStatus == AI_IDLE) && (busy == 0))
			if(!client)
				if((stat != DEAD) && prob(10))
					if(biomass >2)
						morph_to_queen_verb()
		if((busy == 0) && (eat_target))
			eat_target = null

/mob/living/simple_animal/hostile/alien/drone/proc/GiveUp(var/C)
	spawn(100)
		if(busy == 1)
			if(eat_target == C && get_dist(src,eat_target) > 1)
				eat_target = null
				busy = 0
				AIStatus = AI_IDLE
				stop_automated_movement = 0
		if(busy == 2)    // don't give up if you're eating
			stop_automated_movement = 1
			canmove = 0
			return

/mob/living/simple_animal/hostile/alien/drone/verb/morph_to_queen_verb()
	set name = "Morph to Queen"
	set category = "Alien"
	set desc = "Morph into a Queen Alien, you can only do this if there is no existing intelligent Queen."

	// Queen check
	var/no_queen = 1
	for(var/mob/living/simple_animal/hostile/alien/queen/Q in GLOB.living_mob_list)
		if((!Q.key) && (!src.key)) // Mindless Queen exists, and Mindless Drone is trying to become a queen, return
			no_queen = 0
		if(Q.key) // Player Queen exists, no drone shall become another queen, return.
			no_queen = 0
		if((!Q.key) && (src.key)) // Mindless Queen exists, and Player Drone is trying to become a queen, continue
			no_queen = 1
//		no_queen = 1

	if(stat != DEAD)
		if(no_queen == 1)
			if(biomass > 2)
				morph_to_queen()
			else
				to_chat(src, "<span class='warning'>Not enough biomass!</span>")
		if(no_queen == 0)
			to_chat(src, "<span class='warning'>There is a queen as smart as you already!</span>")

/mob/living/simple_animal/hostile/alien/drone/proc/morph_to_queen()
	src.visible_message("<span class='alertalien'>\the [src] evolves!</span>")
	canmove = 0
	stop_automated_movement = 1
	anchored = 1 // needed for some reason
	spawn(2)
		var/mob/living/simple_animal/hostile/alien/queen/Q = new /mob/living/simple_animal/hostile/alien/queen(src.loc)
		if(mind)
			mind.transfer_to(Q)
		qdel(src)

/mob/living/simple_animal/hostile/alien/drone/verb/Eat()
	set name = "Eat"
	set category = "Alien"
	set desc = "Eat prey to increase your biomass"

	if(client)
		if(stat != DEAD)
			var/list/choices = list()
			for(var/mob/living/carbon/L in view(1,src))
				if((Adjacent(L)) && ((L.stat == DEAD) && (!istype(L,/mob/living/carbon/alien/))))
					choices += L
			eat_target = input(src,"What do you wish to eat? You won't be able to move after initiating this.", name) as null|mob in choices

	if((eat_target && busy == 2) || (eat_target && client))
		if(Adjacent(eat_target))
			src.visible_message("<span class='alertalien'>\the [src] settles down and begins to eat \the [eat_target].</span>")
			dir = get_cardinal_dir(src, eat_target)
			stop_automated_movement = 1
			canmove = 0
			busy = 2
			spawn(150)
				if(busy == 2)
					if(eat_target && get_dist(src,eat_target) <= 1)
						eat_target.gib()
						biomass++
						visible_message("<span class='alertalien'>\the [src] viciously rends and eats \the [eat_target], causing a fountain of gore!</span>")
						dir = null
				eat_target = null
				busy = 0
				stop_automated_movement = 0
				canmove = 1
				AIStatus = AI_IDLE
				dir = null

/mob/living/simple_animal/hostile/alien/drone/verb/Weed()
	set name = "Lay weeds"
	set category = "Alien"
	set desc = "Lay weeds that heal you and other aliens with time"

	if(stat == DEAD)
		return

	if(!plants_off && plant_cooldown<=0)
		plant_cooldown = initial(plant_cooldown)
		SpreadPlants()
	else
		to_chat(src, "<span class='warning'>This ability is still recharging.</span>")

/mob/living/simple_animal/hostile/alien/sentinel
	name = "alien sentinel"
	desc = "A strange alien. This one has two green glowing sacs on its crest."
	icon_state = "aliens_running"
	icon_living = "aliens_running"
	icon_dead = "aliens_dead"
	health = 60 //Aliens spawn with 50% health, and then regain it by standing on weeds.
	maxHealth = 120
	melee_damage_lower = 15
	melee_damage_upper = 15
	ranged = 1
	retreat_distance = 5
	minimum_distance = 5
	projectiletype = /obj/item/projectile/neurotox
	projectilesound = 'sound/weapons/pierce.ogg'


/mob/living/simple_animal/hostile/alien/queen
	name = "alien queen"
	desc = "A huge alien. This one seems to be a jack of all trades, its only drawback being its size."
	icon_state = "alienq_running"
	icon_living = "alienq_running"
	icon_dead = "alienq_dead"
	health = 60 //Queens spawn with the maxhealth of drones, and then regain it by standing on weeds.
	maxHealth = 250
	melee_damage_lower = 15
	melee_damage_upper = 15
	ranged = 1
	retreat_distance = 5
	minimum_distance = 5
	move_to_delay = 4
	projectiletype = /obj/item/projectile/neurotox
	projectilesound = 'sound/weapons/pierce.ogg'
	status_flags = 0
	var/sterile = 0
	var/plants_off = 0
	var/egg_cooldown = 180
	var/plant_cooldown = 30

/mob/living/simple_animal/hostile/alien/queen/Life()
	if(stat != DEAD)
		plant_cooldown--
		egg_cooldown--

/mob/living/simple_animal/hostile/alien/queen/handle_automated_action()
	if(..())
		egg_cooldown--
		plant_cooldown--
		if((AIStatus == AI_IDLE) && (!client) && (stat != DEAD))
			if(!plants_off && prob(10) && plant_cooldown<=0)
				plant_cooldown = initial(plant_cooldown)
				SpreadPlants()
			if(!sterile && prob(10) && egg_cooldown<=0)
				egg_cooldown = initial(egg_cooldown)
				LayEggs()

/mob/living/simple_animal/hostile/alien/proc/SpreadPlants()
	if(!isturf(loc) || istype(loc, /turf/space))
		return
	if(locate(/obj/structure/alien/weeds/node) in get_turf(src))
		to_chat(src, "<span class='warning'>There is a node here already!</span>")
		return
	visible_message("<span class='alertalien'>[src] has planted some alien weeds!</span>")
	new /obj/structure/alien/weeds/node(loc)

/mob/living/simple_animal/hostile/alien/proc/LayEggs()
	if(!isturf(loc) || istype(loc, /turf/space))
		return
	if(locate(/obj/structure/alien/dumbegg) in get_turf(src))
		return
	visible_message("<span class='alertalien'>[src] has laid an egg!</span>")
	var/obj/structure/alien/dumbegg/D = new /obj/structure/alien/dumbegg(src.loc)
	D.faction = faction
	D.master_commander = master_commander

/mob/living/simple_animal/hostile/alien/queen/verb/Weed()
	set name = "Lay weeds"
	set category = "Alien"
	set desc = "Lay weeds that heal you and other aliens with time"

	if(stat == DEAD)
		return

	if(!plants_off && plant_cooldown<=0)
		plant_cooldown = initial(plant_cooldown)
		SpreadPlants()
	else
		to_chat(src, "<span class='warning'>This ability is still recharging.</span>")

/mob/living/simple_animal/hostile/alien/queen/verb/LayEggs_Verb()
	set name = "Lay eggs"
	set category = "Alien"
	set desc = "Lay eggs that hatch into new aliens with time"

	if(stat == DEAD)
		return

	if(sterile == 1)
		to_chat(src, "<span class='warning'>You are sterile, and can't lay eggs!</span>")
		return

	if(!isturf(loc) || istype(loc, /turf/space))
		return

	if(locate(/obj/structure/alien/dumbegg) in get_turf(src))
		return

	if(egg_cooldown<=0)
		egg_cooldown = initial(egg_cooldown)
		LayEggs()
	else
		to_chat(src, "<span class='warning'>This ability is still recharging.</span>")

/mob/living/simple_animal/hostile/alien/queen/large
	name = "alien empress"
	icon = 'icons/mob/alienlarge.dmi'
	icon_state = "queen_s"
	icon_living = "queen_s"
	icon_dead = "queen_dead"
	move_to_delay = 4
	maxHealth = 400
	health = 400
	mob_size = MOB_SIZE_LARGE
	gold_core_spawnable = CHEM_MOB_SPAWN_INVALID

/obj/item/projectile/neurotox
	name = "neurotoxin"
	damage = 30
	icon_state = "toxin"

/mob/living/simple_animal/hostile/alien/Life() // Turn dead aliens into husk after some time
	if(stat == DEAD)
		spawn(1200)
			if(icon_state == "alienq_dead")
				icon_state = "alienq_husked"
			if(icon_state == "aliend_dead")
				icon_state = "aliend_husked"
			if(icon_state == "aliens_dead")
				icon_state = "aliens_husked"
			if(icon_state == "alienh_dead")
				icon_state = "alienh_husked"
			else
				return
	if(stat != DEAD && (getBruteLoss() || getFireLoss())) // Heal aliens standing on weeds
		if (locate(/obj/structure/alien/weeds) in get_turf(src))
			adjustBruteLoss(-1)
			adjustFireLoss(-1)

/mob/living/simple_animal/hostile/alien/maid
	name = "lusty xenomorph maid"
	melee_damage_lower = 0
	melee_damage_upper = 0
	a_intent = INTENT_HELP
	friendly = "caresses"
	obj_damage = 0
	environment_smash = 0
	icon_state = "maid"
	icon_living = "maid"
	icon_dead = "maid_dead"
	gold_core_spawnable = CHEM_MOB_SPAWN_INVALID //no fun allowed

/mob/living/simple_animal/hostile/alien/maid/AttackingTarget()
	if(istype(target, /atom/movable))
		if(istype(target, /obj/effect/decal/cleanable))
			visible_message("<span class='notice'>\The [src] cleans up \the [target].</span>")
			qdel(target)
			return
		var/atom/movable/M = target
		M.clean_blood()
		visible_message("<span class='notice'>\The [src] polishes \the [target].</span>")