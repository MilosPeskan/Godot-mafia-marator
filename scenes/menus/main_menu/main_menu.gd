extends Control

@onready var new_game_button: Button = $Background/VBoxContainer/NewGameButton
@onready var settings_button: Button = $Background/VBoxContainer/SettingsButton
@onready var info_button: Button = $Background/VBoxContainer/InfoButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	info_button.pressed.connect(_on_info_pressed)

func _on_new_game_pressed() -> void:
	PlayerManager.reset()
	RoleManager.reset_pool()
	PhaseStateMachine.transition_to(PhaseStateMachine.Phase.SETUP)
	SceneManager.switch_to("player_menu")

func _on_settings_pressed() -> void:
	print("Settings još nije implementiran.")

func _on_info_pressed() -> void:
	SceneManager.switch_to("info_menu")
