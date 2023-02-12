// Step with intent help
/mob/living/proc/handle_micro_bump_helping(mob/living/target)
	// Check for human user
	if(!ishuman(src))
		return FALSE

	// Define human user
	var/mob/living/carbon/human/user = src

	// Check if target is pulled by user
	if(target.pulledby == user)
		return FALSE

	// Define target's location
	var/turf/turf_target = target.loc

	// Iterate over location contents
	for(var/possible_table in turf_target.contents)
		// Check if iteration is a table
		if(istype(possible_table, /obj/structure/table))
			return TRUE

	// Check if both users are micros
	if(get_size(user) <= RESIZE_A_TINYMICRO && get_size(target) <= RESIZE_A_TINYMICRO)
		// Stop pushing
		now_pushing = 0

		// Move user to target's location
		user.forceMove(target.loc)

		// Return
		return TRUE

	// Check if the initiator is twice the size of the target
	if(COMPARE_SIZES(user, target) >= 2)
		// Stop pushing
		now_pushing = 0

		// Move user to target's location
		user.forceMove(target.loc)

		// Check for slithering tauric body
		if(user.dna.features["taur"] == "Naga" || user.dna.features["taur"] == "Tentacle")
			// Display slither visible message
			target.visible_message(span_notice("[src] carefully slithers around [target]."), span_notice("[src]'s huge tail slithers besides you."))

		// No slithering tauric body found
		else
			// Display step visible message
			target.visible_message(span_notice("[src] carefully steps over [target]."), span_notice("[src] steps over you carefully."))

		// Return
		return TRUE

	// Check if target is twice the size of the initiator
	else if(COMPARE_SIZES(target, user) >= 2)
		// Stop pushing
		now_pushing = 0

		// Move user to target's location
		user.forceMove(target.loc)

		// Move user under target
		micro_step_under(target)

		// Return
		return TRUE

// Step with non-help intent
// Now optimized!
/mob/living/proc/handle_micro_bump_other(mob/living/target)
	// Check for living target
	ASSERT(isliving(target))

	// Check for human user
	if(!ishuman(src))
		return FALSE

	// Define human user
	var/mob/living/carbon/human/user = src

	// Check if target is pulled by user
	if(target.pulledby == user)
		return FALSE

	// Define target's location
	var/turf/turf_target = target.loc

	// Iterate over location contents
	for(var/possible_table in turf_target.contents)
		// Check if iteration is a table
		if(istype(possible_table, /obj/structure/table))
			return TRUE

	// Check if both users are micros
	if(get_size(user) <= RESIZE_A_TINYMICRO && get_size(target) <= RESIZE_A_TINYMICRO)
		// Stop pushing
		now_pushing = 0

		// Move user to target's location
		user.forceMove(turf_target)

		// Return
		return TRUE

	// Check if the initiator is twice the size of the target
	else if(COMPARE_SIZES(user, target) >= 2)
		// Check if user can step
		if(!(CHECK_MOBILITY(user, MOBILITY_MOVE) && !user.buckled))
			return FALSE

		// Log combat interaction
		log_combat(user, target, "stepped on", addition="[user.a_intent] trample")

		// Define user's slither status
		var/user_can_slither = (user.dna?.features["taur"] == "Naga" || user.dna?.features["taur"] == "Tentacle") || FALSE

		// Set pushing status
		now_pushing = 0

		// Move user to target's location
		user.forceMove(turf_target)

		// Set move-speed modifier
		user.add_movespeed_modifier(/datum/movespeed_modifier/stomp, TRUE) // Full stop

		// Set target stamina loss
		user.sizediffStamLoss(target)

		// Move user to target's location
		user.forceMove(turf_target)

		// Define move-speed modifier duration
		var/movespeed_modifier_duration = 30 // 3 second placeholder

		// Define owner pronouns
		var/user_their = user.p_their()

		// Check intent type
		switch(user.a_intent)
			// Disarm intent
			if(INTENT_DISARM)
				// Set move-speed modifier duration
				movespeed_modifier_duration = 3 // 0.3 seconds

				// Check if user can slither
				if(user_can_slither)
					target.visible_message(span_danger("[user] carefully rolls [user_their] tail over [target]!"), span_danger("[user]'s huge tail rolls over you!"))

				// User cannot slither
				else
					target.visible_message(span_danger("[user] carefully steps on [target]!"), span_danger("[user] steps onto you with force!"))

			// Harm intent
			if(INTENT_HARM)
				// Set move-speed modifier duration
				movespeed_modifier_duration = 10 // 1 second

				// Check if user can slither
				if(user_can_slither)
					target.visible_message(span_danger("[user] mows down [target] under [user_their] tail!"), span_userdanger("[user] plows [user_their] tail over you mercilessly!"))

				// User cannot slither
				else
					target.visible_message(span_danger("[user] slams [user_their] foot down on [target], crushing them!"), span_userdanger("[user] crushes you under [user_their] foot!"))

				// Cause brute damage to target
				user.sizediffBruteloss(target)

				// Play sound effect
				playsound(loc, 'sound/misc/splort.ogg', 50, 1)

			// Grab intent
			if(INTENT_GRAB)
				// Set move-speed modifier duration
				movespeed_modifier_duration = 7 // ~3/4th of a second

				// Stun the target
				user.sizediffStun(target)

				// Check for non-exposed feet
				if(!user.has_feet(REQUIRE_EXPOSED))
					// Check if user can slither
					if(user_can_slither)
						target.visible_message(span_danger("[user] pins [target] under [user_their] tail!"), span_danger("[user] pins you beneath [user_their] tail!"))

					// User cannot slither
					else
						target.visible_message(span_danger("[user] pins [target] helplessly underfoot!"), span_danger("[user] pins you underfoot!"))

				// User has exposed feet
				else
					// Check if user can slither
					if(user_can_slither)
						target.visible_message(span_danger("[user] snatches up [target] underneath [user_their] tail!"), span_userdanger("[user]'s tail winds around you and snatches you in its coils!"))

					// User cannot slither
					else
						target.visible_message(span_danger("[user] stomps down on [target], curling [user_their] toes and picking them up!"), span_userdanger("[user]'s toes pin you down and curl around you, picking you up!"))

					// Pick up target with user's feet
					SEND_SIGNAL(target, COMSIG_MICRO_PICKUP_FEET, user)

		// Set move-speed modifier removal callback
		addtimer(CALLBACK(user, /mob/.proc/remove_movespeed_modifier, MOVESPEED_ID_STOMP, TRUE), movespeed_modifier_duration)

		// Return
		return TRUE

	// Check if target is twice the size of the initiator
	else if(COMPARE_SIZES(target, user) >= 2)
		// Stop pushing
		now_pushing = 0

		// Move user to target's location
		user.forceMove(target.loc)

		// Move user under target
		micro_step_under(target)

		// Return
		return TRUE

/mob/living/proc/macro_step_around(mob/living/target)
	if(ishuman(src))
		var/mob/living/carbon/human/validmob = src
		if(validmob?.dna?.features["taur"] == "Naga" || validmob?.dna?.features["taur"] == "Tentacle")
			visible_message(span_notice("[validmob] carefully slithers around [target]."), span_notice("You carefully slither around [target]."))
		else
			visible_message(span_notice("[validmob] carefully steps around [target]."), span_notice("You carefully steps around [target]."))

//smaller person stepping under another person... TO DO, fix and allow special interactions with naga legs to be seen
/mob/living/proc/micro_step_under(mob/living/target)
	if(ishuman(src))
		var/mob/living/carbon/human/validmob = src
		if(validmob?.dna?.features["taur"] == "Naga" || validmob?.dna?.features["taur"] == "Tentacle")
			visible_message(span_notice("[validmob] bounds over [target]'s tail."), span_notice("You jump over [target]'s thick tail."))
		else
			visible_message(span_notice("[validmob] runs between [target]'s legs."), span_notice("You run between [target]'s legs."))

//Proc for scaling stamina damage on size difference
/mob/living/carbon/proc/sizediffStamLoss(mob/living/carbon/target)
	var/S = COMPARE_SIZES(src, target) * 25 //macro divided by micro, times 25
	target.Knockdown(S) //final result in stamina knockdown

//Proc for scaling stuns on size difference (for grab intent)
/mob/living/carbon/proc/sizediffStun(mob/living/carbon/target)
	var/T = COMPARE_SIZES(src, target) * 2 //Macro divided by micro, times 2
	target.Stun(T)

//Proc for scaling brute damage on size difference
/mob/living/carbon/proc/sizediffBruteloss(mob/living/carbon/target)
	var/B = COMPARE_SIZES(src, target) * 3 //macro divided by micro, times 3
	target.adjustBruteLoss(B) //final result in brute loss

//Proc for instantly grabbing valid size difference. Code optimizations soon(TM)
/*
/mob/living/proc/sizeinteractioncheck(mob/living/target)
	if(abs(get_effective_size()/target.get_effective_size())>=2.0 && get_effective_size()>target.get_effective_size())
		return 0
	else
		return 1
*/
//Clothes coming off at different sizes, and health/speed/stam changes as well
