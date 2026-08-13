extends Control

@onready var header_label: Label = $HeaderLabel
@onready var vote_rows: VBoxContainer = $VoteRows
@onready var total_votes_label: Label = $TotalVotesLabel
@onready var confirm_lynch_button: Button = $ConfirmLynchButton
@onready var confirm_dialog: AcceptDialog = $ConfirmDialog
@onready var cancel_button: Button = $CancelButton

# Mapira Player -> Label sa brojem glasova, da bismo mogli da
# ažuriramo samo taj red bez ponovnog crtanja cele liste.
var vote_labels: Dictionary = {}

func _ready() -> void:
	header_label.text = "Ko se glasa za pogubljenje?"
	confirm_lynch_button.pressed.connect(_on_confirm_lynch_pressed)
	confirm_dialog.confirmed.connect(_on_confirm_dialog_confirmed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	_build_vote_rows()
	_update_total_label()

func _build_vote_rows() -> void:
	for child in vote_rows.get_children():
		child.queue_free()
	vote_labels.clear()

	for p in PlayerManager.get_alive_players():
		var row: HBoxContainer = HBoxContainer.new()

		var name_label: Label = Label.new()
		name_label.text = p.player_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var votes_label: Label = Label.new()
		votes_label.text = str(p.votes_received)
		vote_labels[p] = votes_label

		var minus_button: Button = Button.new()
		minus_button.text = "-"
		minus_button.set_meta("player", p)
		minus_button.pressed.connect(_on_minus_pressed.bind(p))

		var plus_button: Button = Button.new()
		plus_button.text = "+"
		plus_button.set_meta("player", p)
		plus_button.pressed.connect(_on_plus_pressed.bind(p))

		row.add_child(name_label)
		row.add_child(minus_button)
		row.add_child(votes_label)
		row.add_child(plus_button)

		vote_rows.add_child(row)

func _get_lynch_phase() -> LynchPhase:
	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	return phase as LynchPhase

func _on_plus_pressed(player: Player) -> void:
	var lynch_phase: LynchPhase = _get_lynch_phase()
	if lynch_phase == null:
		return
	lynch_phase.handle_action(null, player, "vote")
	_refresh_row(player)

func _on_minus_pressed(player: Player) -> void:
	var lynch_phase: LynchPhase = _get_lynch_phase()
	if lynch_phase == null:
		return
	lynch_phase.handle_action(null, player, "unvote")
	_refresh_row(player)

func _refresh_row(player: Player) -> void:
	if vote_labels.has(player):
		vote_labels[player].text = str(player.votes_received)
	_update_total_label()

func _update_total_label() -> void:
	var total: int = 0
	for p in PlayerManager.get_alive_players():
		total += p.votes_received
	total_votes_label.text = "Ukupno glasova: %d" % total

func _on_confirm_lynch_pressed() -> void:
	confirm_dialog.popup_centered()

func _on_confirm_dialog_confirmed() -> void:
	var lynch_phase: LynchPhase = _get_lynch_phase()
	if lynch_phase == null:
		return
	lynch_phase.finalize_lynch()

func _on_cancel_pressed() -> void:
	SceneManager.switch_to("day_menu")
