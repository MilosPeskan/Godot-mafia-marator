class_name ProtectFromExecutionEffect
extends ActionEffect

func apply(source: Player, target: Player, night_phase: NightPhase, secondary_target: Player = null) -> void:
	target.protected_from_execution = true
