extends Node

signal game_ready()
signal phase_changed(new_phase: int, old_phase: int)
signal player_added(player: Player)
signal player_removed(player: Player)
signal player_died(player: Player)
signal role_assigned(player: Player, role: Role)
signal action_submitted(player: Player, target: Player, action_type: String)
signal lynch_result(player: Player)
signal game_over(winning_team: int)
signal save_requested()
signal load_requested(slot: String)
signal night_turn_started(player: Player)                      # ko je trenutno na potezu noću
signal night_resolved(killed_players: Array[Player], saved_players: Array[Player])
signal investigation_result(source: Player, target: Player, is_mafia: bool)
signal vote_cast(source: Player, target: Player)   # za live prikaz broja glasova u lynch_menu

# Zajednička mafijaška odluka o ubistvu — grupni turn, ne pojedinačni night_turn_started.
signal night_group_turn_started(actors: Array[Player])

# TRACK (Tragač) — tracked_target može biti null ako meta nikog nije target-ovala noćas.
signal track_result(source: Player, target: Player, tracked_target: Player)

# AUTOPSY (Pogrebnik) — team je Role.Team int, ili -1 ako mrtvi igrač nema dodeljenu rolu.
signal autopsy_result(source: Player, target: Player, team: int)

# FOLLOW (Reporter) — killer je null ako je smrt kolektivna mafijaška odluka (ne pripisuje se
# jednom igraču), inače konkretan Player (npr. Serijski ubica).
signal follow_reveal(follower: Player, victim: Player, killer: Player)
