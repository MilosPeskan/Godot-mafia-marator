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
@onready var role_polaroid_icon: TextureRect = $RolePolaroidBackground/RolePolaroidIcon
@onready var role_name_label: Label = $RolePolaroidBackground/RoleNameLabel
@onready var role_action_label: Label = $InfoCardBackground/RoleActionLabel
@onready var role_instruction_label: Label = $InfoCardBackground/RoleInstructionLabel
@onready var night_number_label: Label = $NightNumberLabel

# Status panel (Milestone 13) — prikazuje se umesto action_menu-a kad
# glumac ne može da deluje: nema mete, blokiran je, ili je zatvoren.
@onready var status_panel: Control = $StatusPanel
@onready var status_label: Label = $StatusPanel/StatusLabel
@onready var continue_button: Button = $StatusPanel/ContinueButton

# Sažetak kraja noći (Milestone 15) — prikazuje se KAD SE CELA NOĆ
# razreši, PRE prelaska na dnevnu fazu. Narator mora eksplicitno da
# potvrdi da bi se scena promenila na day_menu.
@onready var summary_panel: Control = $SummaryPanel
@onready var summary_label: Label = $SummaryPanel/SummaryLabel
@onready var summary_continue_button: Button = $SummaryPanel/ContinueButton

var current_action_menu: ActionMenu = null
var group_eligible_targets: Array[Player] = []
var current_group_actors: Array[Player] = []

func _ready() -> void:
	EventBus.night_turn_started.connect(_on_night_turn_started)
	EventBus.night_group_turn_started.connect(_on_night_group_turn_started)
	EventBus.night_resolved.connect(_on_night_resolved)
	EventBus.night_info_result.connect(_on_night_info_result)

	propose_button.pressed.connect(_on_propose_pressed)
	kum_override_button.pressed.connect(_on_kum_override_pressed)
	confirm_group_button.pressed.connect(_on_confirm_group_pressed)

	status_panel.visible = false
	continue_button.pressed.connect(_on_continue_pressed)

	summary_panel.visible = false
	summary_continue_button.pressed.connect(_on_summary_continue_pressed)

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

## Redosled provera: ZATVOREN pre BLOKIRAN (isti redosled kao stari
## "actor.is_blocked or actor.is_jailed" uslov u night_phase.gd), zatim
## dostupnost mete (samo ako rola uopšte zahteva metu — OBSERVE/Špijun
## nema jedinstvenu metu, pa se ta provera preskače za njega), i tek
## na kraju normalni action_menu.
func _show_solo_actor(player: Player) -> void:
	mafia_group_panel.visible = false
	status_panel.visible = false
	result_label.text = ""
	header_label.text = "Na potezu: %s (%s)" % [player.player_name, player.role.role_name]
	role_name_label.text = player.role.role_name
	role_polaroid_icon.texture = player.role.icon
	role_action_label.text = player.role.action_label
	role_instruction_label.text = player.role.instruction_label

	if player.is_jailed:
		_show_status(player, "ZATVOREN — ne može da deluje noćas.")
		return
	if player.is_blocked:
		_show_status(player, "BLOKIRAN — ne može da deluje noćas.")
		return

	var needs_target: bool = player.role.night_action_type != Role.NightActionType.OBSERVE
	if needs_target:
		var eligible: Array[Player] = TargetResolver.get_eligible_targets(player)
		if eligible.is_empty():
			_show_status(player, "Nema dostupnu metu ove noći.")
			return

	_show_action_menu_for(player)

func _show_status(player: Player, reason: String) -> void:
	if current_action_menu != null:
		current_action_menu.queue_free()
		current_action_menu = null
	action_menu_container.visible = false
	status_panel.visible = true
	status_label.text = "%s (%s): %s" % [player.player_name, player.role.role_name, reason]

func _show_action_menu_for(player: Player) -> void:
	action_menu_container.visible = true
	status_panel.visible = false
	if current_action_menu != null:
		current_action_menu.queue_free()
		current_action_menu = null
	var action_menu: ActionMenu = ACTION_MENU_SCENE.instantiate() as ActionMenu
	action_menu_container.add_child(action_menu)
	action_menu.setup(player)
	current_action_menu = action_menu

func _on_continue_pressed() -> void:
	status_panel.visible = false
	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase != null:
		night_phase.skip_turn()

func _on_night_group_turn_started(actors: Array[Player]) -> void:
	if current_action_menu != null:
		current_action_menu.queue_free()
		current_action_menu = null

	result_label.text = ""
	status_panel.visible = false
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

func _on_night_info_result(source: Player, target: Player, info_type: String, payload: Dictionary) -> void:
	result_label.text = NightInfoFormatter.format(source, target, info_type, payload)

## Sada gradi i prikazuje sažetak kraja noći umesto da samo čisti UI
## stanje. Scena se NE menja ovde — čeka se _on_summary_continue_pressed().
func _on_night_resolved(killed: Array[Player], saved: Array[Player]) -> void:
	if current_action_menu != null:
		current_action_menu.queue_free()
		current_action_menu = null
	mafia_group_panel.visible = false
	status_panel.visible = false
	header_label.text = "Noć se završava..."

	summary_label.text = _build_summary_text(killed, saved)
	summary_panel.visible = true

## Namerno jednostavan tekst — samo imena, bez detalja o uzroku smrti
## (npr. ko je koga ubio, ko je zaštitio koga). Bogatiji prikaz je
## moguće buduće poboljšanje, van obima ove milestone-a.
func _build_summary_text(killed: Array[Player], saved: Array[Player]) -> String:
	var lines: Array[String] = []
	if killed.is_empty():
		lines.append("Niko nije umro ove noći.")
	else:
		var killed_names: Array[String] = []
		for p in killed:
			killed_names.append(p.player_name)
		lines.append("Umrli: %s" % ", ".join(killed_names))
	if not saved.is_empty():
		var saved_names: Array[String] = []
		for p in saved:
			saved_names.append(p.player_name)
		lines.append("Napadnuti, ali preživeli: %s" % ", ".join(saved_names))
	return "\n".join(lines)

func _on_summary_continue_pressed() -> void:
	summary_panel.visible = false
	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	print("continue pressed")
	if night_phase != null:
		print("call night phase")
		night_phase.acknowledge_night_summary()
