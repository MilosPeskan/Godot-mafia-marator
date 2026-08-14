extends Control
class_name TargetPlayerCard

@onready var player_name_label: Label = $MarginContainer/VBoxContainer/PlayerNameLabel
@onready var player_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/PlayerIcon
@onready var select_button: Button = $SelectButton
@onready var selected: TextureRect = $Selected



func _init(player: Player) -> void:
	player_name_label.text = player.player_name
	player_icon.texture = player.player_icon
	select_button.button_down.connect(_select)
	
func _select() -> void:
	selected.visible = true
	
func _deselect() -> void:
	selected.visible = false
