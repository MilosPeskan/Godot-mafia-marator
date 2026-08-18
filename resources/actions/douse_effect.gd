class_name DouseEffect
extends ActionEffect

func apply(source: Player, target: Player, night_phase: NightPhase, secondary_target: Player = null) -> void:
	target.is_doused = true
