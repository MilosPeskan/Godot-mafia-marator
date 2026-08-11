extends Node

var container: Control = null      # postavlja main.gd pri _ready
var current_menu: Control = null

const MENU_SCENES := {
	"main_menu": preload("res://scenes/menus/main_menu/main_menu.tscn"),
	"player_menu": preload("res://scenes/menus/player_menu/player_menu.tscn"),
	"role_menu": preload("res://scenes/menus/role_menu/role_menu.tscn"),
	"role_reveal": preload("res://scenes/menus/role_reveal/role_reveal.tscn"),
	"day_menu": preload("res://scenes/menus/day_menu/day_menu.tscn"),
	"night_menu": preload("res://scenes/menus/night_menu/night_menu.tscn"),
	"lynch_menu": preload("res://scenes/menus/lynch_menu/lynch_menu.tscn"),
	"info_menu": preload("res://scenes/menus/info_menu/info_menu.tscn"),
}

func switch_to(menu_key: String) -> void:
	if not MENU_SCENES.has(menu_key):
		push_error("Nepoznat meni: %s" % menu_key)
		return

	if current_menu != null:
		current_menu.queue_free()
		current_menu = null

	var new_menu: Control = MENU_SCENES[menu_key].instantiate()
	container.add_child(new_menu)
	current_menu = new_menu
