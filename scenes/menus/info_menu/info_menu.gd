extends Control

@onready var player_name_label: Label = $PlayerNameLabel
@onready var role_name_label: Label = $RoleNameLabel
@onready var team_label: Label = $TeamLabel
@onready var description_label: Label = $DescriptionLabel
@onready var back_button: Button = $BackButton

var current_player: Player = null

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

## Poziva ga SceneManager.switch_to("info_menu", player) — vidi
## scene_manager.gd izmenu koja poziva setup() ako scena tu metodu ima.
func setup(player: Player) -> void:
	current_player = player

	if player == null or player.role == null:
		player_name_label.text = ""
		role_name_label.text = ""
		team_label.text = ""
		description_label.text = ""
		return

	player_name_label.text = player.player_name
	role_name_label.text = player.role.role_name
	team_label.text = Role.get_team_name(player.role.team)
	description_label.text = player.role.description

## NAPOMENA: povratak je namerno hardkodovan na "day_menu" — info_menu
## je u ovoj milestone dostupan SAMO iz day_menu. Vidi "FLAGGED FOR
## PROJECT OWNER DECISION" u odgovoru za detalje.
func _on_back_pressed() -> void:
	SceneManager.switch_to("day_menu")
