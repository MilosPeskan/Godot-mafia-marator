extends Control
class_name ActionMenu

@onready var instruction_label: Label = $VBoxContainer/InstructionLabel
@onready var target_list: GridContainer = $VBoxContainer/TargetList
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var ignite_button: Button = $VBoxContainer/IgniteButton   # samo za Pirmana (DOUSE tip), sakriven inače
const TARGET_PLAYER_CARD = preload("res://scenes/components/target_player/target_player_card.tscn")


var actor: Player = null
var eligible_targets: Array[Player] = []

# Stanje za CONTROL (Veštica) — dvostepeni izbor: prvo KOGA kontroliše, pa KA KOME ga usmerava.
var is_control_mode: bool = false
var control_step: int = 0
var control_victim: Player = null

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	ignite_button.pressed.connect(_on_ignite_pressed)
	ignite_button.visible = false

func setup(p_actor: Player) -> void:
	actor = p_actor
	var role: Role = actor.role

	is_control_mode = role.night_action_type == Role.NightActionType.CONTROL
	control_step = 0
	control_victim = null

	var no_target: bool = role.night_action_type == Role.NightActionType.OBSERVE

	ignite_button.visible = role.night_action_type == Role.NightActionType.DOUSE
	target_list.visible = not no_target
	confirm_button.text = "Potvrdi" if no_target else role.action_label

	if is_control_mode:
		instruction_label.text = "%s (%s): koga kontrolišeš?" % [actor.player_name, role.role_name]
	else:
		instruction_label.text = "%s (%s) — %s" % [actor.player_name, role.role_name, role.action_label]

	if no_target:
		eligible_targets.clear()
		for child in target_list.get_children():
			child.queue_free()
		return

	# Prvi (glavni) korak biranja mete uvek koristi pravila iz actor.role
	# (can_target_dead / can_target_self / opposite_team_only).
	_populate_targets(role.can_target_dead, actor, true)

## Popunjava target_list igračima koje ova akcija sme da cilja.
##
## apply_role_filters == true (standardni slučaj, koristi se iz setup()):
##   Pool i filteri se izvode DIREKTNO iz actor.role — dead_pool argument
##   se u tom slučaju ignoriše (naveden je samo radi čitljivosti poziva).
##   - pool = mrtvi ako actor.role.can_target_dead, inače živi
##   - exclude se izbacuje SAMO ako actor.role.can_target_self == false
##   - ako actor.role.opposite_team_only, dodatno se izbacuju igrači
##     istog tima kao actor.role.team
##
## apply_role_filters == false (podrazumevano — koristi ga DRUGI korak
## CONTROL sposobnosti, vidi _advance_control_step): ponaša se kao PRE
## ove izmene — dead_pool ručno bira pool, exclude se UVEK izbacuje,
## bez čitanja pravila iz actor.role.
func _populate_targets(dead_pool: bool, exclude: Player, apply_role_filters: bool = false) -> void:
	eligible_targets.clear()
	
	for child in target_list.get_children():
		child.queue_free()

	var role: Role = actor.role
	var use_dead_pool: bool = role.can_target_dead if apply_role_filters else dead_pool
	var pool: Array[Player] = PlayerManager.get_dead_players() if use_dead_pool else PlayerManager.get_alive_players()

	for p in pool:
		if apply_role_filters:
			if not role.can_target_self and p == exclude:
				continue
			if role.opposite_team_only and p.role != null and p.role.team == role.team:
				continue
		else:
			if p == exclude:
				continue

		eligible_targets.append(p)
		create_target_player_card(p)
		
func create_target_player_card(p: Player):
	var target: TargetPlayerCard = TARGET_PLAYER_CARD.instantiate() as TargetPlayerCard
	target_list.add_child(target)
	target._init(p)

func _on_confirm_pressed() -> void:
	var role: Role = actor.role
	var selected: PackedInt32Array = target_list.get_selected_items()

	if role.night_action_type == Role.NightActionType.OBSERVE:
		EventBus.action_submitted.emit(actor, null, "observe")
		return

	if selected.is_empty():
		return

	var chosen: Player = eligible_targets[selected[0]]

	if is_control_mode:
		_advance_control_step(chosen)
		return

	var action_type: String = Role.night_action_string(role.night_action_type)
	if role.night_action_type == Role.NightActionType.DOUSE:
		action_type = "douse"   # Confirm dugme uvek znači "polij", Ignite dugme (ispod) šalje "ignite"

	EventBus.action_submitted.emit(actor, chosen, action_type)

func _advance_control_step(chosen: Player) -> void:
	if control_step == 0:
		control_victim = chosen
		control_step = 1
		instruction_label.text = "Ka kome usmeravaš %s?" % control_victim.player_name
		# NOTE: second CONTROL step targets based on the redirected
		# player's context, not the actor's own role rules — left as an
		# explicit exception until multi-target actions are generalized
		_populate_targets(false, control_victim)
		return

	var forced_target: Player = chosen
	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase != null:
		night_phase.submit_control_action(actor, control_victim, forced_target)

func _on_ignite_pressed() -> void:
	EventBus.action_submitted.emit(actor, null, "ignite")
