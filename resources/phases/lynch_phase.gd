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
## sa source = null. Ako source ipak postoji (npr. buduća upotreba),
## i dalje se proverava da nije mrtav.
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
