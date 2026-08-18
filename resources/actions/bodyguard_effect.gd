class_name BodyguardEffect
extends ActionEffect

## Namerno NE dira target.protected_by — to je Doktorovo polje, sa
## drugačijim pravilom (otkazuje napad umesto da ga preusmeri). Ova dva
## polja se posebno proveravaju u NightPhase._resolve_single_kill().
func apply(source: Player, target: Player, night_phase: NightPhase, secondary_target: Player = null) -> void:
	target.guarded_by = source
