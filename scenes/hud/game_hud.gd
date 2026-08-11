extends Control

func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	visible = false

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	# Sakriven na MAIN_MENU i SETUP (dok se biraju igrači/role), vidljiv od ROLE_REVEAL nadalje
	visible = new_phase != PhaseStateMachine.Phase.SETUP
