class_name BlockEffect
extends ActionEffect

## Postavlja target.is_blocked = true — identično staroj "block"
## grani u NightPhase._apply_action_effect(). Ne dodaje novo ponašanje.
func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	target.is_blocked = true
