class_name Player
extends RefCounted

var player_name: String = ""
var role: Role = null              # referenca na deljeni Role resurs (read-only template)
var is_alive: bool = true

# Polja relevantna za noćne akcije / glasanje:
var night_target: Player = null    # koga je ovaj igrač izabrao kao metu prošle noći
var protected_by: Player = null    # ko ga štiti ove noći (npr. doktor), resetuje se svako veče
var votes_received: int = 0        # glasovi primljeni tokom trenutnog lynch glasanja
var has_acted_tonight: bool = false

func _init(p_name: String = "", p_role: Role = null) -> void:
	player_name = p_name
	role = p_role

func assign_role(new_role: Role) -> void:
	role = new_role

func kill() -> void:
	is_alive = false

func reset_nightly_state() -> void:
	night_target = null
	protected_by = null
	has_acted_tonight = false

func reset_voting_state() -> void:
	votes_received = 0

func to_dict() -> Dictionary:
	# koristi save_manager za serijalizaciju partije
	return {
		"player_name": player_name,
		"role_name": role.role_name if role else "",
		"is_alive": is_alive,
	}
