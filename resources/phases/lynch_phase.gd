class_name LynchPhase
extends PhaseBase

var votes_locked: bool = false

func enter() -> void:
	for p in PlayerManager.get_alive_players():
		p.reset_voting_state()
	votes_locked = false

func exit() -> void:
	pass

## source je NULLABLE — glasovi iz lynch_menu.gd predstavljaju usmena
## glasanja tokom diskusije, ne akciju konkretnog igrača, pa se šalju
## sa source = null. Ako source ipak postoji, i dalje se proverava da
## nije mrtav.
func handle_action(source: Player, target: Player, action_type: String) -> void:
	if votes_locked:
		return
	if source != null and not source.is_alive:
		return

	if action_type == "vote":
		target.votes_received += 1
		EventBus.vote_cast.emit(source, target)
	elif action_type == "unvote":
		if target.votes_received > 0:
			target.votes_received -= 1
			EventBus.vote_cast.emit(source, target)

## Poziva se eksplicitno iz lynch_menu.gd kad moderator zatvori glasanje.
func finalize_lynch() -> void:
	if votes_locked:
		return
	votes_locked = true

	var alive: Array[Player] = PlayerManager.get_alive_players()
	var lynched: Player = null
	var max_votes: int = 0
	var tie: bool = false

	for p in alive:
		if p.votes_received > max_votes:
			max_votes = p.votes_received
			lynched = p
			tie = false
		elif p.votes_received == max_votes and max_votes > 0:
			tie = true

	if lynched != null and not tie:
		# --- Sudija zaštita (Milestone 9) — MORA biti proveren PRE bilo
		# kog Milestone 7 win-condition bloka ispod, jer zaštićeni igrač
		# NIJE stvarno umro — ništa što pretpostavlja njegovu smrt sme
		# da se izvrši. Rani `return` sprečava GameRules.check_win_condition()
		# i prelazak u NIGHT ispod da se pokrenu na osnovu netačne pretpostavke.
		if lynched.protected_from_execution:
			EventBus.lynch_survived.emit(lynched, max_votes)
			lynched.protected_from_execution = false   # jednokratni štit — troši se odmah
			return

		# =====================================================================
		# REKONSTRUKCIJA MILESTONE 7 LOGIKE — NIJE STVARNI KOD IZ TOG MILESTONE-A.
		# Implementirajući model NIJE imao pristup pravom, mergovanom
		# lynch_phase.gd iz Milestone 7 (Madman/Executioner win-uslovi).
		# Ovaj blok je rekonstruisan iz JS reference (game-state.js,
		# checkLynchWinCondition) da bi kod uopšte bio kompletan i testabilan,
		# ali MORA biti proveren/zamenjen stvarnim Milestone 7 kodom od strane
		# reviewer-a pre merge-a. Vidi HANDOFF TO CODE REVIEWER.
		# =====================================================================
		if lynched.role != null and lynched.role.role_id == Role.RoleId.MADMAN:
			lynched.kill()
			EventBus.lynch_result.emit(lynched)
			EventBus.player_died.emit(lynched)
			EventBus.game_over.emit(Role.Team.NEUTRAL)
			state_machine.transition_to(PhaseStateMachine.Phase.GAME_OVER)
			return

		# Dželat (Executioner) — pobeđuje ako je NJEGOVA meta pogubljena.
		# NAPOMENA: ovde bi trebalo proveriti da li je `lynched` bio meta
		# NEKOG živog Dželata (execution_target polje na Dželatu, dodato u
		# Milestone 7 preko RoleManager.assign_special_targets()). Ta
		# provera NIJE implementirana ovde jer implementirajući model nema
		# uvid u tačan naziv/oblik tog polja iz stvarnog Milestone 7 koda —
		# namerno OSTAVLJENO KAO TODO, da se ne bi pogodilo pogrešno ime
		# polja i unelo tiho pogrešno ponašanje.
		# TODO(Milestone 7 reviewer): dodati proveru Dželatove mete ovde,
		# po uzoru na stvarni Milestone 7 kod.

		lynched.kill()
		EventBus.lynch_result.emit(lynched)
		EventBus.player_died.emit(lynched)
	else:
		EventBus.lynch_result.emit(null)

	var winner: int = GameRules.check_win_condition()
	if winner != -1:
		EventBus.game_over.emit(winner)
		state_machine.transition_to(PhaseStateMachine.Phase.GAME_OVER)
		return

	state_machine.transition_to(PhaseStateMachine.Phase.NIGHT)
	SceneManager.switch_to("night_menu")
