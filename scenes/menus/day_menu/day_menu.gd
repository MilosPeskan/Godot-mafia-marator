extends Control

@onready var header_label: Label = $HeaderLabel
@onready var player_list: ItemList = $PlayerList
@onready var selected_player_info: Label = $SelectedPlayerInfo
@onready var show_roles_button: Button = $ShowRolesButton
@onready var roles_overview_dialog: AcceptDialog = $RolesOverviewDialog
@onready var roles_overview_list: RichTextLabel = $RolesOverviewDialog/RolesOverviewList
@onready var call_lynch_button: Button = $CallLynchButton
@onready var start_night_button: Button = $StartNightButton
@onready var view_details_button: Button = $ViewDetailsButton

var selected_player: Player = null

func _ready() -> void:
	header_label.text = "Dnevna diskusija"
	player_list.item_selected.connect(_on_player_selected)
	show_roles_button.pressed.connect(_on_show_roles_pressed)
	call_lynch_button.pressed.connect(_on_call_lynch_pressed)
	start_night_button.pressed.connect(_on_start_night_pressed)
	view_details_button.pressed.connect(_on_view_details_pressed)

	selected_player_info.text = ""
	view_details_button.disabled = true
	_refresh_player_list()

func _refresh_player_list() -> void:
	player_list.clear()
	for p in PlayerManager.players:
		var status: String = "" if p.is_alive else " (mrtav)"
		player_list.add_item(p.player_name + status)

func _on_player_selected(index: int) -> void:
	var player: Player = PlayerManager.players[index]
	selected_player = player
	view_details_button.disabled = false

	if player.role == null:
		selected_player_info.text = "%s: rola nepoznata" % player.player_name
		return
	selected_player_info.text = "%s — %s\n%s" % [player.player_name, player.role.role_name, player.role.description]

func _on_show_roles_pressed() -> void:
	var seen_ids: Dictionary = {}
	var lines: Array[String] = []
	for role in RoleManager.role_pool_for_session:
		if seen_ids.has(role.role_id):
			continue
		seen_ids[role.role_id] = true
		lines.append("[b]%s[/b]: %s" % [role.role_name, role.description])
	roles_overview_list.text = "\n\n".join(lines)
	roles_overview_dialog.popup_centered()

func _on_call_lynch_pressed() -> void:
	PhaseStateMachine.transition_to(PhaseStateMachine.Phase.LYNCH)
	SceneManager.switch_to("lynch_menu")

func _on_start_night_pressed() -> void:
	PhaseStateMachine.transition_to(PhaseStateMachine.Phase.NIGHT)
	SceneManager.switch_to("night_menu")

func _on_view_details_pressed() -> void:
	if selected_player == null:
		return
	SceneManager.switch_to("info_menu", selected_player)
