class_name NightInfoFormatter
extends RefCounted

## Formatira tekst poruke za dati night_info_result payload. Deljeno
## između night_menu.gd (prikaz naratoru) i action_menu.gd (reveal popup
## prikazan akteru) — postoji SAMO OVDE, da bi obe strane uvek prikazivale
## identičan tekst bez dupliranja match-statement logike na dva mesta.
static func format(source: Player, target: Player, info_type: String, payload: Dictionary) -> String:
	match info_type:
		"investigate":
			var verdict: String = "PRIPADA mafiji" if payload["is_mafia"] else "NE pripada mafiji"
			return "%s je istražio/la %s: %s" % [source.player_name, target.player_name, verdict]
		"track":
			var visited_target: Player = payload["visited_target"]
			var visited_name: String = visited_target.player_name if visited_target != null else "nikog"
			return "%s je pratio/la %s — posetio/la je: %s" % [source.player_name, target.player_name, visited_name]
		"autopsy":
			var team: int = payload["team"]
			var team_name: String = Role.get_team_name(team) if team != -1 else "Nepoznato"
			return "%s je obdukovao/la %s — pripadao/la je: %s" % [source.player_name, target.player_name, team_name]
		"follow":
			var killer: Player = payload["killer"]
			var killer_name: String = killer.player_name if killer != null else "mafiju (kolektivno)"
			return "%s je pratio/la %s — ubica: %s" % [source.player_name, target.player_name, killer_name]
		"observe":
			var visited_by_mafia: Array = payload["visited_by_mafia"]
			var names: Array[String] = []
			for p in visited_by_mafia:
				names.append(p.player_name)
			var names_text: String = ", ".join(names) if names.size() > 0 else "nikog"
			return "%s je uočio/la posete mafije: %s" % [source.player_name, names_text]
		"take_role":
			return "%s je preuzeo/la novu ulogu: %s" % [source.player_name, payload["new_role_name"]]
		_:
			push_error("Nepoznat info_type u NightInfoFormatter: %s" % info_type)
			return ""
