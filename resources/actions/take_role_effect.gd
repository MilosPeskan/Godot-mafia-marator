class_name TakeRoleEffect
extends ActionEffect

## Amnezičar — trenutno preuzima ulogu izabranog MRTVOG igrača. Meta je
## garantovano mrtva zahvaljujući amnesiac.tres pravilima (can_target_dead
## = true, can_target_self = false, izvršenim preko TargetResolver-a).
## Emituje night_info_result sa "take_role", što action_menu.gd (Milestone
## 12) automatski prikazuje kao reveal popup, jer je
## reveals_result_to_player = true na amnesiac.tres.
func apply(source: Player, target: Player, night_phase: NightPhase, secondary_target: Player = null) -> void:
	var new_role: Role = target.role
	source.assign_role(new_role)
	EventBus.night_info_result.emit(source, target, "take_role", {"new_role_name": new_role.role_name if new_role != null else "Nepoznato"})
