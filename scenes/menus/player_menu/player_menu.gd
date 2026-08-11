extends Control

const PLAYER_CONTAINER: PackedScene = preload("res://scenes/components/player_list_container/player_container.tscn")
const MAX_PLAYERS: int = 20

@onready var add_player_button: Button = $AddPlayerButton
@onready var player_name_input: LineEdit = $PlayerNameImput
@onready var next_button: Button = $NextButton
@onready var status_label: Label = $StatusLabel
@onready var player_grid: GridContainer = $PlayerGrid

func _ready() -> void:
	add_player_button.pressed.connect(_on_add_player_pressed)
	player_name_input.text_submitted.connect(_on_line_edit_text_submitted)
	next_button.pressed.connect(_on_next_pressed)
	EventBus.player_added.connect(_on_player_added)
	EventBus.player_removed.connect(_on_player_removed)

	status_label.text = ""
	_update_add_state()

func _on_add_player_pressed() -> void:
	var player_name: String = player_name_input.text.strip_edges()

	if player_name.is_empty():
		return

	if PlayerManager.players.size() >= MAX_PLAYERS:
		status_label.text = "Dostignut je maksimalan broj igrača (%d)." % MAX_PLAYERS
		return

	if _is_name_taken(player_name):
		status_label.text = "Igrač sa imenom '%s' već postoji." % player_name
		return

	PlayerManager.add_player(player_name)
	player_name_input.text = ""
	status_label.text = ""

func _on_line_edit_text_submitted(_new_text: String) -> void:
	_on_add_player_pressed()

func _is_name_taken(player_name: String) -> bool:
	for p in PlayerManager.players:
		if p.player_name.to_lower() == player_name.to_lower():
			return true
	return false

func _on_player_added(p: Player) -> void:
	var container: PlayerContainer = PLAYER_CONTAINER.instantiate() as PlayerContainer
	container.player_added(p.player_name, p)
	player_grid.add_child(container)
	_update_add_state()

func _on_player_removed(_p: Player) -> void:
	_update_add_state()

func _update_add_state() -> void:
	var at_limit: bool = PlayerManager.players.size() >= MAX_PLAYERS
	add_player_button.disabled = at_limit
	player_name_input.editable = not at_limit
	if at_limit:
		status_label.text = "Dostignut je maksimalan broj igrača (%d)." % MAX_PLAYERS

func _on_next_pressed() -> void:
	if PlayerManager.players.size() == 0:
		status_label.text = "Dodaj bar jednog igrača."
		return
	SceneManager.switch_to("role_menu")
