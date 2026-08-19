class_name NightPhase
extends PhaseBase

var turn_order: Array[NightTurn] = []
var current_turn_index: int = 0

# Zajednička mafijaška odluka — dva odvojena predloga, Kum pobeđuje ako se razlikuju.
var pending_mafia_target: Player = null
var pending_kum_target: Player = null

# Igrači koje je neki efekat ubio ODMAH, tokom sopstvenog poteza, van
# normalnog _resolve_night()/_resolve_single_kill() toka (trenutno
# samo IgniteEffect). Beleže se ovde da bi se svejedno pojavili u
# sažetku kraja noći — vidi record_immediate_death() i _resolve_night().
var immediate_deaths: Array[Player] = []

func enter() -> void:
	for p in PlayerManager.get_alive_players():
		p.reset_nightly_state()
	_build_turn_order()
	current_turn_index = 0
	pending_mafia_target = null
	pending_kum_target = null
	immediate_deaths = []
	_prompt_current_or_resolve()

func exit() -> void:
	pass

## Za night_menu.gd — pojedinačni glumac trenutnog poteza (null za grupni mafijaški potez
## ili kad je noć gotova — proveri get_current_turn().is_group_kill pre ovoga).
func get_current_actor() -> Player:
	var turn: NightTurn = get_current_turn()
	if turn == null or turn.actors.is_empty():
		return null
	return turn.actors[0]

func get_current_turn() -> NightTurn:
	if current_turn_index >= turn_order.size():
		return null
	return turn_order[current_turn_index]

func _build_turn_order() -> void:
	var solo_actors: Array[Player] = []
	var mafia_kill_actors: Array[Player] = []

	for p in PlayerManager.get_alive_players():
		if p.role == null or not p.role.can_act_at_night:
			continue
		var is_mafia_kill: bool = p.role.team == Role.Team.MAFIA and p.role.night_action_type == Role.NightActionType.KILL
		if is_mafia_kill:
			mafia_kill_actors.append(p)
		else:
			solo_actors.append(p)

	solo_actors.sort_custom(func(a: Player, b: Player) -> bool: return a.role.night_priority < b.role.night_priority)

	var kill_group_priority: int = 999
	for actor in mafia_kill_actors:
		kill_group_priority = mini(kill_group_priority, actor.role.night_priority)

	turn_order.clear()
	var kill_group_inserted: bool = false

	for actor in solo_actors:
		if not kill_group_inserted and not mafia_kill_actors.is_empty() and actor.role.night_priority >= kill_group_priority:
			turn_order.append(NightTurn.new(mafia_kill_actors, true))
			kill_group_inserted = true
		turn_order.append(NightTurn.new([actor], false))

	if not kill_group_inserted and not mafia_kill_actors.is_empty():
		turn_order.append(NightTurn.new(mafia_kill_actors, true))

func _prompt_current_or_resolve() -> void:
	var turn: NightTurn = get_current_turn()
	if turn == null:
		_resolve_night()
		return

	if turn.is_group_kill:
		EventBus.night_group_turn_started.emit(turn.actors)
		return

	var actor: Player = turn.actors[0]

	# CONTROL (Veštica) je već preusmerila ovog igrača — preskoči ručni unos, primeni odmah.
	if actor.forced_target != null:
		var forced: Player = actor.forced_target
		actor.forced_target = null
		var action_type: String = Role.night_action_string(actor.role.night_action_type)
		handle_action(actor, forced, action_type, true)
		return

	EventBus.night_turn_started.emit(actor)

func handle_action(source: Player, target: Player, action_type: String, skip_reveal_pause: bool = false) -> void:
	var turn: NightTurn = get_current_turn()
	if turn == null:
		return

	if turn.is_group_kill:
		_handle_group_kill_vote(source, target)
		return

	var expected_actor: Player = turn.actors[0]
	if source != expected_actor or not source.is_alive:
		return

	_apply_action_effect(source, target, action_type)

	source.has_acted_tonight = true
	source.last_night_action_target = target
	if target != null:
		target.night_visitors.append(source)

	var must_pause_for_reveal: bool = source.role != null and source.role.reveals_result_to_player and not skip_reveal_pause
	if must_pause_for_reveal:
		return   # čeka se acknowledge_reveal() poziv iz action_menu.gd (narator odbacio popup)

	current_turn_index += 1
	_prompt_current_or_resolve()

## Poziva ga action_menu.gd nakon što narator odbaci reveal popup za
## rolu sa reveals_result_to_player == true. Nastavlja napredovanje
## poteza koje je handle_action() namerno preskočio za tu akciju.
func acknowledge_reveal() -> void:
	current_turn_index += 1
	_prompt_current_or_resolve()

## Preskače trenutni potez BEZ primene ikakve akcije — koristi se za DVA
## slučaja koja night_menu.gd tretira kao "ovaj glumac ne može da deluje":
## (1) nema dostupnih meta, (2) glumac je blokiran ili zatvoren. Oba
## slučaja predstavljaju "potez se završava bez efekta", pa dele ISTU
## metodu umesto dve odvojene.
func skip_turn() -> void:
	var turn: NightTurn = get_current_turn()
	if turn == null or turn.is_group_kill:
		return
	var actor: Player = turn.actors[0]
	if not actor.is_alive:
		return
	actor.has_acted_tonight = true
	current_turn_index += 1
	_prompt_current_or_resolve()

## Poziva ga night_menu.gd nakon što narator odbaci sažetak kraja noći.
## Izvršava fazni prelaz i promenu scene koje je _resolve_night()
## namerno odložio.
func acknowledge_night_summary() -> void:
	state_machine.transition_to(PhaseStateMachine.Phase.DAY_DISCUSSION)
	SceneManager.switch_to("day_menu")

## Poziva ga efekat (trenutno samo IgniteEffect) koji ubija igrače
## ODMAH tokom sopstvenog poteza, van normalnog
## _resolve_night()/_resolve_single_kill() toka — da bi ta smrt ipak
## bila ispravno prikazana u sažetku kraja noći. Proverava da igrač
## već nije zabeležen, da ne bi bio duplo naveden u slučaju da je i na
## neki drugi način ušao u killed[] listu.
func record_immediate_death(player: Player) -> void:
	if not immediate_deaths.has(player):
		immediate_deaths.append(player)

## CONTROL (Veštica) — poseban ulaz jer zahteva DVA izbora (koga kontroliše + nova meta),
## ne uklapa se u standardni handle_action(source, target, action_type) oblik. Pozvano
## direktno iz action_menu.gd (isti obrazac kao LynchPhase.finalize_lynch() — direktan poziv
## na fazu za koordinaciju koja ne staje u "jedna akcija, jedna meta").
func submit_control_action(source: Player, controlled: Player, forced_target: Player) -> void:
	var turn: NightTurn = get_current_turn()
	if turn == null or turn.is_group_kill or turn.actors[0] != source or not source.is_alive:
		return

	controlled.forced_target = forced_target
	source.has_acted_tonight = true

	current_turn_index += 1
	_prompt_current_or_resolve()

## Mafijaška grupa predlaže metu — ne završava potez dok night_menu.gd ne pozove
## finalize_group_kill() (moderator eksplicitno potvrđuje, isto kao kod linča).
func _handle_group_kill_vote(source: Player, target: Player) -> void:
	var turn: NightTurn = get_current_turn()
	if turn == null or not turn.contains(source) or not source.is_alive:
		return

	if source.role.overrides_mafia_kill_vote:
		pending_kum_target = target
	else:
		pending_mafia_target = target

func finalize_group_kill() -> void:
	var turn: NightTurn = get_current_turn()
	if turn == null or not turn.is_group_kill:
		return

	var final_target: Player = pending_kum_target if pending_kum_target != null else pending_mafia_target

	if final_target != null:
		for actor in turn.actors:
			actor.night_target = final_target
			actor.has_acted_tonight = true
			actor.last_night_action_target = final_target
			final_target.night_visitors.append(actor)

	current_turn_index += 1
	_prompt_current_or_resolve()

## Centralni dispatcher za sve tipove noćnih akcija. CONTROL nije ovde — ima svoj
## submit_control_action() jer ne staje u oblik (source, target, action_type).
##
## "ignite" se posebno proverava PRE opšte per-role dispatch provere —
## Piroman ima SAMO JEDAN night_action_effect slot (zauzet DouseEffect-om
## za polivanje), pa paljenje mora biti dispatchovano direktno preko
## action_type-a, zaobilazeći taj slot. Ovo je NAMERAN, uzak izuzetak —
## ne generalizovati ovaj obrazac (dispatch preko action_type-a mimo
## per-role efekta) na druge role bez sličnog strukturnog razloga.
##
## Zatim proverava da li rola izvršioca ima dodeljen night_action_effect (novi,
## Resource-bazirani sistem iz Milestone 2). Ako ima, koristi ga i vraća se odmah.
## Ako nema (null), pada dole na stari match statement — nepromenjen fallback za
## sve role koje još nisu migrirane.
func _apply_action_effect(source: Player, target: Player, action_type: String) -> void:
	if action_type == "ignite":
		var ignite := IgniteEffect.new()
		ignite.apply(source, target, self)
		return

	if source.role != null and source.role.night_action_effect != null:
		source.role.night_action_effect.apply(source, target, self)
		return

	match action_type:
		"protect":
			target.protected_by = source
		"investigate":
			var appears_mafia: bool = target.role != null and (target.role.team == Role.Team.MAFIA or target.is_framed)
			if target.is_deceived:
				appears_mafia = not appears_mafia
			EventBus.night_info_result.emit(source, target, "investigate", {"is_mafia": appears_mafia})
		"block":
			target.is_blocked = true
		"douse":
			target.is_doused = true
		"ignite":
			_resolve_ignite()
		"observe":
			var visited: Array[Player] = []
			for p in PlayerManager.players:
				for visitor in p.night_visitors:
					if visitor.role != null and visitor.role.team == Role.Team.MAFIA:
						visited.append(p)
						break
			EventBus.night_info_result.emit(source, null, "observe", {"visited_by_mafia": visited})
		"track":
			EventBus.night_info_result.emit(source, target, "track", {"visited_target": target.last_night_action_target})
		"censor":
			target.is_censored = true
		"autopsy":
			var team_result: int = target.role.team if target.role != null else -1
			EventBus.night_info_result.emit(source, target, "autopsy", {"team": team_result})
		"deceive":
			target.is_deceived = true
		"silence":
			target.is_silenced = true
		"frame":
			target.is_framed = true
		"jail":
			target.is_jailed = true
		"mark":
			target.is_marked = true
		"infest":
			target.is_infested = true
		"follow":
			target.followed_by.append(source)
		"protect_from_execution":
			target.protected_from_execution = true
		"take_role":
			source.assign_role(target.role)
		_:
			push_error("Nepoznat action_type: %s" % action_type)

func _resolve_ignite() -> void:
	for p in PlayerManager.get_alive_players():
		if p.is_doused:
			p.kill()
			EventBus.player_died.emit(p)
			p.is_doused = false

func _resolve_single_kill(target: Player, killed: Array[Player], saved: Array[Player], killer: Player) -> void:
	if not target.is_alive:
		return   # već mrtav (npr. i mafija i Serijski ubica cilja istog)
	if target.is_jailed:
		saved.append(target)
		return
	if target.protected_by != null:
		saved.append(target)
		return
	if target.guarded_by != null:
		var guardian: Player = target.guarded_by
		guardian.kill()
		killed.append(guardian)
		EventBus.player_died.emit(guardian)
		saved.append(target)
		return

	var inherited_role: Role = target.role
	var parasite: Player = target.infested_by

	target.kill()
	killed.append(target)
	EventBus.player_died.emit(target)

	for follower in target.followed_by:
		EventBus.night_info_result.emit(follower, target, "follow", {"victim": target, "killer": killer})

	if parasite != null and parasite.is_alive:
		parasite.assign_role(inherited_role)
		EventBus.night_info_result.emit(parasite, target, "take_role", {"new_role_name": inherited_role.role_name if inherited_role != null else "Nepoznato"})

func _resolve_night() -> void:
	var killed: Array[Player] = []
	var saved: Array[Player] = []

	var mafia_kill_target: Player = pending_kum_target if pending_kum_target != null else pending_mafia_target
	if mafia_kill_target != null:
		_resolve_single_kill(mafia_kill_target, killed, saved, null)

	# Serijski ubica (Neutralna, KILL, priority 55) ubija NEZAVISNO od mafije — nije u
	# mafia_kill_actors grupi (nije MAFIA tim), prošao je kroz solo_actors i njegov
	# night_target je već postavljen kroz standardni handle_action() poziv.
	for p in PlayerManager.get_alive_players():
		if p.role != null and p.role.team == Role.Team.NEUTRAL and p.role.night_action_type == Role.NightActionType.KILL and p.night_target != null:
			_resolve_single_kill(p.night_target, killed, saved, p)

	# Spaja odmah-ubijene igrače (trenutno samo od IgniteEffect-a) u
	# killed[] pre nego što se emituje sažetak — inače bi zapaljene
	# smrti bile nevidljive u night_menu.gd's SummaryPanel-u, iako su
	# se stvarno dogodile. Provera "not killed.has(p)" sprečava
	# duplo navođenje ako je igrač nekim slučajem već u killed[].
	for p in immediate_deaths:
		if not killed.has(p):
			killed.append(p)

	EventBus.night_resolved.emit(killed, saved)

	var winner: int = GameRules.check_win_condition()
	if winner != -1:
		EventBus.game_over.emit(winner)
		state_machine.transition_to(PhaseStateMachine.Phase.GAME_OVER)
		return

	# Namerno NE prelazi u DAY_DISCUSSION i NE menja scenu ovde —
	# night_menu.gd prvo prikazuje sažetak (SummaryPanel) i poziva
	# acknowledge_night_summary() tek kad narator pritisne Nastavi.
