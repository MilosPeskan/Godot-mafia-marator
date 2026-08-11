extends Control
class_name ActionMenu

@onready var instruction_label: Label = $InstructionLabel
@onready var target_list: ItemList = $TargetList
@onready var confirm_button: Button = $ConfirmButton
@onready var ignite_button: Button = $IgniteButton   # samo za Pirmana (DOUSE tip), sakriven inače

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
		target_list.clear()
		return

	_populate_targets(role.targets_dead_players, actor)

func _populate_targets(dead_pool: bool, exclude: Player) -> void:
	eligible_targets.clear()
	target_list.clear()

	var pool: Array[Player] = PlayerManager.get_dead_players() if dead_pool else PlayerManager.get_alive_players()

	for p in pool:
		if p == exclude:
			continue   # pojednostavljenje: niko trenutno ne cilja sebe (videti napomenu u sekciji 21)
		eligible_targets.append(p)
		target_list.add_item(p.player_name)

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
		_populate_targets(false, control_victim)   # ne sme da usmeri metu ka samoj sebi
		return

	var forced_target: Player = chosen
	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase != null:
		night_phase.submit_control_action(actor, control_victim, forced_target)

func _on_ignite_pressed() -> void:
	EventBus.action_submitted.emit(actor, null, "ignite")
