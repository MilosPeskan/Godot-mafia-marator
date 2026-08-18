class_name TargetResolver
extends RefCounted

## Vraća listu igrača koje data rola sme da cilja, primenjujući ISTA
## pravila kao action_menu.gd's _populate_targets() (Milestone 3):
## can_target_dead / can_target_self / opposite_team_only. Deljeno
## između action_menu.gd (popunjava mrežu kartica) i night_menu.gd
## (proverava DA LI uopšte postoji validna meta, pre nego što odluči
## da li da prikaže action_menu ili status panel).
static func get_eligible_targets(actor: Player) -> Array[Player]:
	if actor.role == null:
		return []
	var role: Role = actor.role
	var pool: Array[Player] = PlayerManager.get_dead_players() if role.can_target_dead else PlayerManager.get_alive_players()
	var eligible: Array[Player] = []
	for p in pool:
		if not role.can_target_self and p == actor:
			continue
		if role.opposite_team_only and p.role != null and p.role.team == role.team:
			continue
		eligible.append(p)
	return eligible
