extends Control

const ACTION_MENU_SCENE: PackedScene = preload("res://scenes/menus/action_menu/action_menu.tscn")

@onready var header_label: Label = $HeaderLabel
@onready var result_label: Label = $InvestigationResultLabel
@onready var action_menu_container: Control = $ActionMenuContainer
@onready var mafia_group_panel: Control = $MafiaGroupPanel
@onready var mafia_members_label: Label = $MafiaGroupPanel/MafiaMembersLabel
@onready var group_target_list: ItemList = $MafiaGroupPanel/GroupTargetList
@onready var propose_button: Button = $MafiaGroupPanel/ProposeButton
@onready var kum_override_button: Button = $MafiaGroupPanel/KumOverrideButton
@onready var confirm_group_button: Button = $MafiaGroupPanel/ConfirmGroupButton

var current_action_menu: ActionMenu = null
var group_eligible_targets: Array[Player] = []
var current_group_actors: Array[Player] = []

func _ready() -> void:
	EventBus.night_turn_started.connect(_on_night_turn_started)
	EventBus.night_group_turn_started.connect(_on_night_group_turn_started)
	EventBus.night_resolved.connect(_on_night_resolved)
	EventBus.investigation_result.connect(_on_investigation_result)
	EventBus.track_result.connect(_on_track_result)
	EventBus.autopsy_result.connect(_on_autopsy_result)
	EventBus.follow_reveal.connect(_on_follow_reveal)

	propose_button.pressed.connect(_on_propose_pressed)
	kum_override_button.pressed.connect(_on_kum_override_pressed)
	confirm_group_button.pressed.connect(_on_confirm_group_pressed)

	header_label.text = "Noć pada nad gradom..."
	result_label.text = ""
	mafia_group_panel.visible = false

	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase == null:
		return

	var turn: NightTurn = night_phase.get_current_turn()
	if turn == null:
		return
	if turn.is_group_kill:
		_on_night_group_turn_started(turn.actors)
	else:
		var actor: Player = night_phase.get_current_actor()
		if actor != null:
			_show_solo_actor(actor)

func _on_night_turn_started(player: Player) -> void:
	_show_solo_actor(player)

func _show_solo_actor(player: Player) -> void:
	mafia_group_panel.visible = false
	result_label.text = ""
	header_label.text = "Na potezu: %s (%s)" % [player.player_name, player.role.role_name]

	if current_action_menu != null:
		current_action_menu.queue_free()
		current_action_menu = null

	var action_menu: ActionMenu = ACTION_MENU_SCENE.instantiate() as ActionMenu
	action_menu_container.add_child(action_menu)
	action_menu.setup(player)
	current_action_menu = action_menu

func _on_night_group_turn_started(actors: Array[Player]) -> void:
	if current_action_menu != null:
		current_action_menu.queue_free()
		current_action_menu = null

	result_label.text = ""
	header_label.text = "Mafija bira zajedničku metu"
	mafia_group_panel.visible = true
	current_group_actors = actors

	var names: Array[String] = []
	var has_kum: bool = false
	for a in actors:
		names.append("%s (%s)" % [a.player_name, a.role.role_name])
		if a.role.overrides_mafia_kill_vote:
			has_kum = true

	mafia_members_label.text = "Na potezu: " + ", ".join(names)
	kum_override_button.visible = has_kum

	group_target_list.clear()
	group_eligible_targets.clear()
	for p in PlayerManager.get_alive_players():
		if actors.has(p):
			continue
		group_eligible_targets.append(p)
		group_target_list.add_item(p.player_name)

func _get_selected_group_target() -> Player:
	var selected: PackedInt32Array = group_target_list.get_selected_items()
	if selected.is_empty():
		return null
	return group_eligible_targets[selected[0]]

func _on_propose_pressed() -> void:
	var target: Player = _get_selected_group_target()
	if target == null:
		return
	var mafia_source: Player = null
	for a in current_group_actors:
		if not a.role.overrides_mafia_kill_vote:
			mafia_source = a
			break
	if mafia_source == null:
		return

	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase != null:
		night_phase.handle_action(mafia_source, target, "kill")

func _on_kum_override_pressed() -> void:
	var target: Player = _get_selected_group_target()
	if target == null:
		return
	var kum_source: Player = null
	for a in current_group_actors:
		if a.role.overrides_mafia_kill_vote:
			kum_source = a
			break
	if kum_source == null:
		return

	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase != null:
		night_phase.handle_action(kum_source, target, "kill")

func _on_confirm_group_pressed() -> void:
	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase != null:
		night_phase.finalize_group_kill()

func _on_investigation_result(source: Player, target: Player, is_mafia: bool) -> void:
	var verdict: String = "PRIPADA mafiji" if is_mafia else "NE pripada mafiji"
	result_label.text = "%s je istražio/la %s: %s" % [source.player_name, target.player_name, verdict]

func _on_track_result(source: Player, target: Player, tracked_target: Player) -> void:
	var visited_name: String = tracked_target.player_name if tracked_target != null else "nikog"
	result_label.text = "%s je pratio/la %s — posetio/la je: %s" % [source.player_name, target.player_name, visited_name]

func _on_autopsy_result(source: Player, target: Player, team: int) -> void:
	var team_name: String = Role.get_team_name(team) if team != -1 else "Nepoznato"
	result_label.text = "%s je obdukovao/la %s — pripadao/la je: %s" % [source.player_name, target.player_name, team_name]

func _on_follow_reveal(follower: Player, victim: Player, killer: Player) -> void:
	var killer_name: String = killer.player_name if killer != null else "mafiju (kolektivno)"
	result_label.text = "%s je pratio/la %s — ubica: %s" % [follower.player_name, victim.player_name, killer_name]

func _on_night_resolved(killed: Array[Player], saved: Array[Player]) -> void:
	if current_action_menu != null:
		current_action_menu.queue_free()
		current_action_menu = null
	mafia_group_panel.visible = false
	header_label.text = "Noć se završava..."
