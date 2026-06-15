/// Produce after_image and loud footsteps for bull charges
/datum/action/ability/xeno_action/proc/afterimage(atom/A, atom/OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	new/obj/effect/temp_visual/after_image(get_turf(xeno_owner), xeno_owner)
	playsound(xeno_owner, SFX_ALIEN_FOOTSTEP_LARGE, 50)

// ***************************************
// *********** Acid Charge
// ***************************************
/datum/action/ability/xeno_action/acid_charge
	name = "Acid Charge"
	desc = "The acid charge, deal small damage to yourself and start leaving acid puddles after your steps."
	action_icon_state = "bull_charge"
	action_icon = 'icons/Xeno/actions/bull.dmi'
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_ACIDCHARGE,
	)
	cooldown_duration = 15 SECONDS
	ability_cost = 60
	var/charge_duration
	var/obj/effect/abstract/particle_holder/particle_holder

/particles/bull_selfslash
	icon = 'icons/effects/effects.dmi'
	icon_state = "redslash"
	scale = 1.3
	count = 1
	spawning = 1
	lifespan = 4
	fade = 4
	rotation = -160
	friction = 0.6

/datum/action/ability/xeno_action/acid_charge/can_use_action()
	if(xeno_owner.bull_charging)
		return FALSE
	return ..()

/datum/action/ability/xeno_action/acid_charge/action_activate()
	if(!do_after(xeno_owner, 0.5 SECONDS, IGNORE_LOC_CHANGE, xeno_owner, BUSY_ICON_DANGER))
		if(!xeno_owner.stat)
			xeno_owner.set_canmove(TRUE)
		return fail_activate()
	particle_holder = new(xeno_owner, /particles/bull_selfslash)
	particle_holder.pixel_y = 12
	particle_holder.pixel_x = 18
	START_PROCESSING(SSprocessing, src)
	QDEL_NULL_IN(src, particle_holder, 5)
	playsound(xeno_owner,'sound/weapons/alien_bite1.ogg', 75, 1)
	xeno_owner.emote("hiss")
	xeno_owner.set_canmove(TRUE)
	xeno_owner.bull_charging = TRUE
	xeno_owner.add_movespeed_modifier(MOVESPEED_ID_BULL_ACID_CHARGE, TRUE, 0, NONE, TRUE, xeno_owner.xeno_caste.speed * 1.2)
	charge_duration = addtimer(CALLBACK(src, PROC_REF(acid_charge_deactivate)), 2 SECONDS,  TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)
	RegisterSignals(xeno_owner, list(COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_STAGGER), PROC_REF(acid_charge_deactivate))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_MOVED, PROC_REF(acid_puddle))
	xeno_owner.icon_state = "[xeno_owner.xeno_caste.caste_name] Charging"

	succeed_activate()
	add_cooldown()

/datum/action/ability/xeno_action/acid_charge/proc/acid_charge_deactivate()
	SIGNAL_HANDLER
	xeno_owner.remove_movespeed_modifier(MOVESPEED_ID_BULL_ACID_CHARGE)
	xeno_owner.update_icons()
	xeno_owner.bull_charging = FALSE

	UnregisterSignal(owner, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_LIVING_STATUS_PARALYZE,
		COMSIG_LIVING_STATUS_STAGGER,))

/datum/action/ability/xeno_action/acid_charge/proc/acid_puddle(atom/A, atom/OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	new/obj/effect/temp_visual/after_image(get_turf(xeno_owner), xeno_owner)
	new /obj/effect/xenomorph/spray(get_turf(xeno_owner), 5 SECONDS, XENO_ACID_CHARGE_DAMAGE)
	for(var/obj/O in get_turf(xeno_owner))
		O.acid_spray_act(xeno_owner)
		playsound(xeno_owner, SFX_ALIEN_FOOTSTEP_LARGE, 50)

// ***************************************
// *********** Headbutt Charge
// ***************************************
/datum/action/ability/xeno_action/headbutt
	name = "Headbutt Charge"
	desc = "The headbutt charge, when it hits a host, stops your charge while push them away."
	action_icon_state = "bull_headbutt"
	action_icon = 'icons/Xeno/actions/bull.dmi'
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLHEADBUTT,
	)
	cooldown_duration = 10 SECONDS
	ability_cost = 60
	var/turf/last_turf
	var/charge_duration

/datum/action/ability/xeno_action/headbutt/can_use_action()
	if(xeno_owner.bull_charging)
		return FALSE
	return ..()

/datum/action/ability/xeno_action/headbutt/action_activate()
	if(!do_after(xeno_owner, 0.5 SECONDS, IGNORE_LOC_CHANGE, xeno_owner, BUSY_ICON_DANGER))
		if(!xeno_owner.stat)
			xeno_owner.set_canmove(TRUE)
		return fail_activate()
	xeno_owner.emote("roar")
	xeno_owner.set_canmove(TRUE)
	xeno_owner.bull_charging = TRUE
	xeno_owner.add_movespeed_modifier(MOVESPEED_ID_BULL_HEADBUTT_CHARGE, TRUE, 0, NONE, TRUE, xeno_owner.xeno_caste.speed * 1.2)
	charge_duration = addtimer(CALLBACK(src, PROC_REF(headbutt_charge_deactivate)), 3 SECONDS, TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)
	RegisterSignals(xeno_owner, list(COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_STAGGER), PROC_REF(headbutt_charge_deactivate))
	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_ATTACK_LIVING, PROC_REF(bull_charge_slash))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_MOVED, PROC_REF(afterimage))
	xeno_owner.icon_state = "[xeno_owner.xeno_caste.caste_name] Charging"
	succeed_activate()
	add_cooldown()

/datum/action/ability/xeno_action/headbutt/proc/bull_charge_slash(datum/source, mob/living/target, damage, list/damage_mod)
	var/headbutt_throw_range = 6

	if(target.stat == DEAD)
		return

	target.knockback(xeno_owner, headbutt_throw_range, 1)
	target.Paralyze(1 SECONDS)

	playsound(target,'sound/weapons/alien_knockdown.ogg', 75, 1)
	xeno_owner.visible_message(span_danger("[xeno_owner] pushed away [target]!"),
		span_xenowarning("We push away [target] and skid to a halt!"))
	headbutt_charge_deactivate()

/datum/action/ability/xeno_action/headbutt/proc/headbutt_charge_deactivate()
	SIGNAL_HANDLER
	xeno_owner.remove_movespeed_modifier(MOVESPEED_ID_BULL_HEADBUTT_CHARGE)
	xeno_owner.update_icons()
	xeno_owner.bull_charging = FALSE

	UnregisterSignal(owner, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_LIVING_STATUS_PARALYZE,
		COMSIG_LIVING_STATUS_STAGGER,))

// ***************************************
// *********** Gore Charge
// ***************************************
/datum/action/ability/xeno_action/gore
	name = "Gore Charge"
	desc = "The gore charge, when it hits a host, stops your charge while dealing a large amount of damage."
	action_icon_state = "bull_gore"
	action_icon = 'icons/Xeno/actions/bull.dmi'
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLGORE,
	)
	cooldown_duration = 8 SECONDS
	ability_cost = 60
	var/turf/last_turf
	var/charge_duration

/datum/action/ability/xeno_action/gore/can_use_action()
	if(xeno_owner.bull_charging)
		return FALSE
	return ..()

/datum/action/ability/xeno_action/gore/action_activate()
	if(!do_after(xeno_owner, 0.5 SECONDS, IGNORE_LOC_CHANGE, xeno_owner, BUSY_ICON_DANGER))
		if(!xeno_owner.stat)
			xeno_owner.set_canmove(TRUE)
		return fail_activate()
	xeno_owner.emote("roar")
	xeno_owner.set_canmove(TRUE)
	xeno_owner.bull_charging = TRUE
	xeno_owner.add_movespeed_modifier(MOVESPEED_ID_BULL_GORE_CHARGE, TRUE, 0, NONE, TRUE, xeno_owner.xeno_caste.speed * 1.2)
	charge_duration = addtimer(CALLBACK(src, PROC_REF(gore_charge_deactivate)), 2 SECONDS, TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)
	RegisterSignals(xeno_owner, list(COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_STAGGER), PROC_REF(gore_charge_deactivate))
	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_ATTACK_LIVING, PROC_REF(bull_charge_slash))
	RegisterSignal(xeno_owner, COMSIG_MOVABLE_MOVED, PROC_REF(afterimage))
	xeno_owner.icon_state = "[xeno_owner.xeno_caste.caste_name] Charging"

	succeed_activate()
	add_cooldown()

/datum/action/ability/xeno_action/gore/proc/bull_charge_slash(datum/source, mob/living/target, damage, list/damage_mod)
	if(target.stat == DEAD)
		return

	damage = xeno_owner.xeno_caste.melee_damage * xeno_owner.xeno_melee_damage_modifier * 2.6
	target.apply_damage(damage, BRUTE, xeno_owner.zone_selected, MELEE)
	playsound(target,'sound/weapons/alien_tail_attack.ogg', 75, 1)
	target.emote_gored()
	xeno_owner.visible_message(span_danger("[xeno_owner] gores [target]!"),
		span_xenowarning("We gore [target] and skid to a halt!"))
	gore_charge_deactivate()

/datum/action/ability/xeno_action/gore/proc/gore_charge_deactivate()
	SIGNAL_HANDLER
	xeno_owner.remove_movespeed_modifier(MOVESPEED_ID_BULL_GORE_CHARGE)
	xeno_owner.update_icons()
	xeno_owner.bull_charging = FALSE

	UnregisterSignal(owner, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_LIVING_STATUS_PARALYZE,
		COMSIG_LIVING_STATUS_STAGGER,))

// ***************************************
// *********** Bull Turret Ability
// ***************************************
/datum/action/ability/xeno_action/bull_turret
	name = "Bull Turret"
	desc = "Spawns a mobile sticky resin turret that follows you and fires sticky resin at nearby enemies."
	action_icon = 'icons/Xeno/acid_turret.dmi'
	action_icon_state = "resin_turret"
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLTURRET,
	)
	cooldown_duration = 5 SECONDS
	ability_cost = 100

	// Храним ссылку на турель прямо внутри этой способности
	var/obj/structure/xeno/turret/sticky/bull/my_turret = null

/datum/action/ability/xeno_action/bull_turret/action_activate()
	if(!xeno_owner || !xeno_owner.loc)
		return fail_activate()

	// Быстрая проверка на существование турели
	if(my_turret && !QDELETED(my_turret))
		xeno_owner.visible_message(span_xenowarning("[xeno_owner]'s sticky turret is already deployed!"),
			span_xenowarning("Your sticky turret is already deployed!"))
		return fail_activate()

	// Спавним новую турель
	var/obj/structure/xeno/turret/sticky/bull/new_turret = new(xeno_owner.loc, xeno_owner.hivenumber)

	my_turret = new_turret
	new_turret.set_master(xeno_owner)

	xeno_owner.visible_message(span_xenowarning("[xeno_owner] deploys a sticky turret!"),
		span_xenowarning("You deploy a sticky turret!"))

	succeed_activate()
	add_cooldown()


// ***************************************
// *********** Bull Turret Object
// ***************************************
/obj/structure/xeno/turret/sticky/bull
	name = "Bull Sticky Turret"
	desc = "A sticky resin turret deployed by a Bull xenomorph. It fires sticky resin at enemies."
	icon = 'icons/Xeno/acid_turret.dmi'
	icon_state = "resin_turret"
	density = FALSE
	layer = MOB_LAYER + 0.1
	pixel_y = 8 // Смещение спрайта турели
	var/mob/living/carbon/xenomorph/master = null

/obj/structure/xeno/turret/sticky/bull/proc/set_master(mob/living/carbon/xenomorph/M)
	if(!M)
		return
	master = M

	if(master.loc)
		src.forceMove(master.loc)

	// --- ИНИЦИАЛИЗАЦИЯ И АНИМАЦИЯ ПОЯВЛЕНИЯ ---
	// 1. Задаем начальную точку: турель полностью прозрачная и сжата в 0
	src.alpha = 0
	var/matrix/M_start = matrix()
	M_start.Scale(0, 0)
	src.transform = M_start

	// 2. Создаем целевую матрицу: уменьшенная до 70% турель
	var/matrix/M_target = matrix()
	M_target.Scale(0.7, 0.7)

	// 3. Запускаем анимацию на 2 секунды
	// Плавное появление (alpha = 255) и увеличение до целевой матрицы с эффектом плавного затухания скорости (EASE_OUT)
	animate(src, transform = M_target, alpha = 255, time = 2 SECONDS, easing = EASE_OUT)
	// ------------------------------------------

	// Синхронизация движений через сигналы
	RegisterSignal(master, COMSIG_MOVABLE_MOVED, PROC_REF(follow_master))
	START_PROCESSING(SSobj, src)

/obj/structure/xeno/turret/sticky/bull/proc/follow_master(datum/source, atom/old_loc, dir)
	SIGNAL_HANDLER
	if(!master || !master.loc || master.stat == DEAD)
		qdel(src)
		return

	src.forceMove(master.loc)

/obj/structure/xeno/turret/sticky/bull/process()
	if(!master || !master.loc || master.stat == DEAD)
		qdel(src)
		return

	if(src.loc != master.loc)
		src.forceMove(master.loc)

	. = ..()

/obj/structure/xeno/turret/sticky/bull/Destroy()
	if(master)
		UnregisterSignal(master, COMSIG_MOVABLE_MOVED)
	master = null
	return ..()
