class_name PlayerContainer
extends Control

@export var player_name_label: Label
@export var censorship_line: Sprite2D
@export var remove_button: Button

var frame_count: int = 0
var display_name: String = ""
var player_object: Player = null

func _ready() -> void:
	frame_count = int(censorship_line.texture.get_height() / censorship_line.region_rect.size.y)
	var random_index: int = randi_range(0, frame_count - 1)
	censorship_line.region_rect.position.y = random_index * censorship_line.region_rect.size.y

func player_added(new_display_name: String, p: Player) -> void:
	player_name_label.text = new_display_name
	display_name = new_display_name
	player_object = p
	censorship_line.visible = false
	remove_button.visible = true

func _on_remove_pressed() -> void:
	PlayerManager.remove_player(player_object)
	player_removed()

func player_removed() -> void:
	censorship_line.visible = true
	remove_button.visible = false
	player_name_label.text = ""
	display_name = ""
	await _censor()
	queue_free()

func _censor() -> void:
	censorship_line.material.set_shader_parameter("reveal", 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(
		censorship_line.material,
		"shader_parameter/reveal",
		1.0,
		0.35
	)
	await tween.finished
