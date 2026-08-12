class_name ActionEffect
extends Resource

## Bazna klasa za noćne efekte akcija (protect, block, kill...).
## Svaka konkretna akcija nasleđuje ovu klasu i implementira apply().
## NAMERNO ne referenciše nijednu konkretnu rolu, role_id ili role_name —
## ovo je čisto generički "oblik" koji NightPhase poziva kad je
## Role.night_action_effect dodeljen.
##
## Ova bazna implementacija se nikad ne treba pozvati direktno — svaka
## podklasa mora da je pregazi (override).
func apply(source: Player, target: Player, night_phase: NightPhase) -> void:
	push_error("ActionEffect.apply() nije implementiran — bazna klasa se ne sme koristiti direktno, napravi podklasu.")
