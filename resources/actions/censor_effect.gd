class_name CensorEffect
extends ActionEffect

func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	target.is_censored = true
