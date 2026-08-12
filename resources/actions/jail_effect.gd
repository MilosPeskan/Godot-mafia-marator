class_name JailEffect
extends ActionEffect

func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	target.is_jailed = true
