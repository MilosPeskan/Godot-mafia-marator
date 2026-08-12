class_name ProtectEffect
extends ActionEffect

## Postavlja target.protected_by = source — identično staroj "protect"
## grani u NightPhase._apply_action_effect(). Ne dodaje novo ponašanje.
func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	target.protected_by = source
