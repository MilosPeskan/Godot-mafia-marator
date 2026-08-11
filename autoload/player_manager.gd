extends Node

var players: Array[Player] = []

func add_player(player_name: String) -> Player:
	var p := Player.new(player_name)
	players.append(p)
	EventBus.player_added.emit(p)
	return p

func remove_player(player: Player) -> void:
	var idx := players.find(player)
	if idx == -1:
		return
	players.remove_at(idx)
	EventBus.player_removed.emit(player)
	print(players)

func get_alive_players() -> Array[Player]:
	var result: Array[Player] = []
	for p in players:
		if p.is_alive:
			result.append(p)
	return result

func get_player_by_name(player_name: String) -> Player:
	for p in players:
		if p.player_name == player_name:
			return p
	return null

func reset() -> void:
	players.clear()
