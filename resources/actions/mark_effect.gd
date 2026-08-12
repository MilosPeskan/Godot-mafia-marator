class_name MarkEffect
extends ActionEffect

func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	target.is_marked = true
