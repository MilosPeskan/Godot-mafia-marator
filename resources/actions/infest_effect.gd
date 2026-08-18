class_name InfestEffect
extends ActionEffect

## Parazit — samo OZNAČAVA metu ove noći. Ne menja ulogu ovde — stvarno
## preuzimanje uloge (ako meta zaista umre te noći) se dešava odloženo,
## u NightPhase._resolve_single_kill(), koje čita target.infested_by.
func apply(source: Player, target: Player, night_phase: NightPhase, secondary_target: Player = null) -> void:
	target.is_infested = true
	target.infested_by = source
