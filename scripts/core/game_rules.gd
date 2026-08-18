class_name GameRules
extends RefCounted

## Vraća Role.Team pobednika (int), ili -1 ako partija treba da se nastavi.
static func check_win_condition() -> int:
	var alive := PlayerManager.get_alive_players()
	var mafia_count := 0
	var village_count := 0
	var neutral_killing := 0
	var neutral_killing_roles: Array = [Role.RoleId.SERIAL_KILLER, Role.RoleId.PYROMAN]

	for p in alive:
		if p.role == null:
			continue
		if p.role.team == Role.Team.MAFIA:
			mafia_count += 1
		elif p.role.team == Role.Team.VILLAGE:
			village_count += 1
		elif p.role.role_id in neutral_killing_roles:
			neutral_killing += 1
	
	if mafia_count == 0 and neutral_killing == 0 and village_count > 0:
		return Role.Team.VILLAGE
	if mafia_count > 0 and mafia_count >= village_count and neutral_killing == 0:
		return Role.Team.MAFIA
	if neutral_killing > 0 and mafia_count == 0 and neutral_killing >= village_count:
		return Role.RoleId.SERIAL_KILLER
	return -1

## Pomoćna funkcija za prikaz u UI (game_over ekran i sl.) — pretvara enum u tekst za moderatora.
static func team_to_display_name(team: int) -> String:
	match team:
		Role.Team.MAFIA:
			return "Mafija"
		Role.Team.VILLAGE:
			return "Građani"
		Role.Team.NEUTRAL:
			return "Neutralni"
		_:
			return "Nepoznato"
