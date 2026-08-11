class_name NightTurn
extends RefCounted

var actors: Array[Player] = []     # obično 1 igrač; više za zajedničku mafijašku odluku
var is_group_kill: bool = false

func _init(p_actors: Array[Player], p_is_group_kill: bool = false) -> void:
	actors = p_actors
	is_group_kill = p_is_group_kill

func contains(player: Player) -> bool:
	return actors.has(player)
