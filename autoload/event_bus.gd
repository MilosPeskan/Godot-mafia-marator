extends Node

signal game_ready()
signal phase_changed(new_phase: int, old_phase: int)
signal player_added(player: Player)
signal player_removed(player: Player)
signal player_died(player: Player)
signal role_assigned(player: Player, role: Role)
signal action_submitted(player: Player, target: Player, action_type: String)
signal lynch_result(player: Player)
signal lynch_survived(player: Player, votes: int)
signal game_over(winning_team: int)
signal save_requested()
signal load_requested(slot: String)
signal night_turn_started(player: Player)                      # ko je trenutno na potezu noću
signal night_resolved(killed_players: Array[Player], saved_players: Array[Player])
signal vote_cast(source: Player, target: Player)   # za live prikaz broja glasova u lynch_menu

# Zajednička mafijaška odluka o ubistvu — grupni turn, ne pojedinačni night_turn_started.
signal night_group_turn_started(actors: Array[Player])

# Generički signal za sve "informativne" noćne rezultate (investigate, track,
# autopsy, follow, observe...). Zamenjuje četiri posebna signala
# (investigation_result, track_result, autopsy_result, follow_reveal) —
# svaka nova informativna rola ubuduće koristi OVAJ isti signal, razlikovan
# samo preko info_type i payload sadržaja, umesto da traži novi signal.
# target je null kad rezultat nema jedinstvenu metu (npr. Špijunovo "observe").
signal night_info_result(source: Player, target: Player, info_type: String, payload: Dictionary)

# FOLLOW (Reporter) — killer je null ako je smrt kolektivna mafijaška odluka (ne pripisuje se
# jednom igraču), inače konkretan Player (npr. Serijski ubica). Emituje se preko
# night_info_result sa info_type = "follow" — vidi night_phase.gd _resolve_single_kill().
