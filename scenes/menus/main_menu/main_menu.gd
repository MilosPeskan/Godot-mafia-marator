extends Control

@onready var new_game_button: Button = $Background/NewGame/NewGameButton
@onready var settings_button: Button = $Background/Settings/SettingsButton
@onready var info_button: Button = $Background/Info/InfoButton
@onready var debug_button: Button = $Background/DebugButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	info_button.pressed.connect(_on_info_pressed)

	debug_button.visible = Global.debug_mode
	debug_button.pressed.connect(_on_debug_pressed)

func _on_new_game_pressed() -> void:
	PlayerManager.reset()
	RoleManager.reset_pool()
	PhaseStateMachine.transition_to(PhaseStateMachine.Phase.SETUP)
	SceneManager.switch_to("player_menu")

func _on_settings_pressed() -> void:
	print("Settings još nije implementiran.")

func _on_info_pressed() -> void:
	SceneManager.switch_to("info_menu")

## DEBUG MODE: preskače player_menu i ide direktno na role_menu sa
## praznom listom igrača — igrači se kreiraju automatski dok se dodaju
## role u role_menu.gd / role_list_item.gd.
func _on_debug_pressed() -> void:
	PlayerManager.reset()
	RoleManager.reset_pool()
	PhaseStateMachine.transition_to(PhaseStateMachine.Phase.SETUP)
	SceneManager.switch_to("role_menu", true)
