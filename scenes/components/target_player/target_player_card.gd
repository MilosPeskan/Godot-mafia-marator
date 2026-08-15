extends Control
class_name TargetPlayerCard

## Emitovan kad narator tapne na ovu kartu — ActionMenu sluša ovaj signal
## da bi znao koji je Player trenutno izabran (GridContainer, za razliku
## od ItemList-a, nema ugrađen koncept "selektovane stavke").
signal target_selected(player: Player, card: TargetPlayerCard)

@onready var player_name_label: Label = $MarginContainer/VBoxContainer/PlayerNameLabel
@onready var player_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PlayerIcon
@onready var select_button: Button = $SelectButton
@onready var selected: TextureRect = $MarginContainer2/Selected

var player: Player = null

## VAŽNO: pozivati OVU funkciju tek POSLE add_child(), jer čita @onready
## reference (player_name_label, player_icon...) koje ne postoje pre nego
## što node uđe u scensko stablo. Ranije se ovo pogrešno radilo u _init(),
## koji se poziva PRE ulaska u scensko stablo — @onready polja tada još
## ne postoje, pa bi ovo pucalo ili tiho ne radilo ništa.
func setup(p_player: Player) -> void:
	player = p_player
	player_name_label.text = player.player_name
	if player.player_icon != null:
		player_icon.texture = player.player_icon
	selected.visible = false
	select_button.pressed.connect(_on_select_pressed)

func _on_select_pressed() -> void:
	target_selected.emit(player, self)

func mark_selected() -> void:
	selected.visible = true

func mark_unselected() -> void:
	selected.visible = false

## Menja veličinu fonta SAMO na ovoj kartici (theme override), bez
## diranja deljenog Theme resursa koji koriste sve ostale kartice/labele
## u projektu. Poziva ga ActionMenu._resize_target_cards() kad smanjuje
## karticu, da bi tekst pratio novu, manju veličinu.
func set_name_font_size(size_px: int) -> void:
	player_name_label.add_theme_font_size_override("font_size", size_px)
