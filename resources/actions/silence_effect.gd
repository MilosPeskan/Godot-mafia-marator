class_name SilenceEffect
extends ActionEffect

func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	target.is_silenced = true
