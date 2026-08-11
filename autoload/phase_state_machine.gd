extends Node

enum Phase { SETUP, ROLE_REVEAL, NIGHT, DAY_DISCUSSION, LYNCH, GAME_OVER }

var current_phase: Phase = Phase.SETUP
var current_phase_object: PhaseBase = null

func _ready() -> void:
	EventBus.action_submitted.connect(_on_action_submitted)

func transition_to(new_phase: Phase) -> void:
	var old_phase := current_phase

	if current_phase_object != null:
		current_phase_object.exit()

	current_phase_object = _create_phase_object(new_phase)
	current_phase = new_phase

	if current_phase_object != null:
		current_phase_object.enter()

	EventBus.phase_changed.emit(new_phase, old_phase)

func handle_action(source: Player, target: Player, action_type: String) -> void:
	if current_phase_object != null:
		current_phase_object.handle_action(source, target, action_type)

func _on_action_submitted(source: Player, target: Player, action_type: String) -> void:
	handle_action(source, target, action_type)

func _create_phase_object(phase: Phase) -> PhaseBase:
	match phase:
		Phase.NIGHT:
			return NightPhase.new(self)
		Phase.LYNCH:
			return LynchPhase.new(self)
		Phase.DAY_DISCUSSION:
			return DayPhase.new(self)
		_:
			# SETUP, ROLE_REVEAL, GAME_OVER trenutno nemaju posebnu logiku faze —
			# to su čisto UI/meni koraci, ne treba im PhaseBase objekat.
			return null
			
func get_current_phase() -> PhaseBase:
	return current_phase_object
