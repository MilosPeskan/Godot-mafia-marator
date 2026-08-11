class_name GameRules
extends RefCounted

## Vraća Role.Team pobednika (int), ili -1 ako partija treba da se nastavi.
static func check_win_condition() -> int:
	var alive := PlayerManager.get_alive_players()
	var mafia_count := 0
	var village_count := 0

	for p in alive:
		if p.role == null:
			continue
		if p.role.team == Role.Team.MAFIA:
			mafia_count += 1
		else:
			village_count += 1

	if mafia_count == 0:
		return Role.Team.VILLAGE
	if mafia_count >= village_count:
		return Role.Team.MAFIA
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
