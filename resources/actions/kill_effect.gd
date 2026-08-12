class_name KillEffect
extends ActionEffect

## Postavlja source.night_target = target — identično tome kako se
## trenutno beleži meta Serijskog ubice (NIJE isto što i grupni
## mafijaški kill, koji ide kroz _handle_group_kill_vote()).
## Ne razrešava smrt ovde — to i dalje radi
## NightPhase._resolve_night() / _resolve_single_kill(), bez izmena.
func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	source.night_target = target
