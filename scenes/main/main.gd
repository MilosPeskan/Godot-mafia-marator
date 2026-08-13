extends Node

@export var debug_mode: bool = false

@onready var scene_container: Control = $Control/UiRoot/SceneContainer

func _ready() -> void:
	Global.debug_mode = debug_mode
	SceneManager.container = scene_container
	RoleManager.load_all_roles()
	EventBus.game_ready.emit()
	SceneManager.switch_to("main_menu")
