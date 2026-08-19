class_name TargetGridPanel
extends Control

const TARGET_PLAYER_CARD: PackedScene = preload("res://scenes/components/target_player/target_player_card.tscn")

## Emitted when the narrator selects a card and presses Confirm.
signal target_confirmed(player: Player)
signal player_selected_for_info(player: Player)

@onready var grid: GridContainer = $VBoxContainer/GridContainer
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton

var cards: Array[TargetPlayerCard] = []
var selected_card: TargetPlayerCard = null
var selected_player: Player = null

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirm_button.disabled = true

## Populates the grid with one card per player in `players`,
## clearing any previous selection/cards first. Caller is responsible
## for passing an already-filtered player list (e.g. via
## TargetResolver.get_eligible_targets()) -- this panel has no
## awareness of targeting rules, roles, or game phases.
func populate(players: Array[Player]) -> void:
	for c in cards:
		c.queue_free()
	cards.clear()
	selected_card = null
	selected_player = null
	confirm_button.disabled = true

	for p in players:
		var card: TargetPlayerCard = TARGET_PLAYER_CARD.instantiate() as TargetPlayerCard
		grid.add_child(card)
		card.setup(p)
		card.target_selected.connect(_on_card_selected)
		cards.append(card)

func _on_card_selected(player: Player, card: TargetPlayerCard) -> void:
	if selected_card != null and selected_card != card:
		selected_card.mark_unselected()
	card.mark_selected()
	selected_card = card
	selected_player = player
	player_selected_for_info.emit(selected_player)
	confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	if selected_player == null:
		return
	target_confirmed.emit(selected_player)
