class_name DecieveEffect
extends ActionEffect

func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	target.is_deceived = true
