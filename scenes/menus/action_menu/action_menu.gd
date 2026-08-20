extends Control
class_name ActionMenu

const TARGET_PLAYER_CARD: PackedScene = preload("res://scenes/components/target_player/target_player_card.tscn")

# Dizajn-proporcija kartice (širina/visina) uzeta iz originalnog
# target_player_card.tscn (347x397) — koristi se da se izračuna visina
# kad se širina smanji, da kartica ne izgleda razvučeno/spljošteno.
const CARD_DESIGN_SIZE: Vector2 = Vector2(347.0, 397.0)
const CARDS_PER_ROW: int = 5

# Originalna veličina fonta PlayerNameLabel-a iz target_player_card.tscn
# (theme_override_font_sizes/font_size = 41 na tom node-u) — koristi se
# kao osnova za proporcionalno skaliranje kad se kartica smanji.
const NAME_LABEL_DESIGN_FONT_SIZE: int = 41
const NAME_LABEL_MIN_FONT_SIZE: int = 10

@onready var instruction_label: Label = $VBoxContainer/InstructionLabel
@onready var target_list: GridContainer = $VBoxContainer/TargetList
@onready var confirm_button: Button = $VBoxContainer/HBoxContainer/Control/ConfirmButton
@onready var ignite_control: Control = $VBoxContainer/HBoxContainer/IgniteControl   # samo za Pirmana (DOUSE tip), sakriven inače
@onready var ignite_button: Button = $VBoxContainer/HBoxContainer/IgniteControl/IgniteButton   # samo za Pirmana (DOUSE tip), sakriven inače
@onready var target_selection_container: VBoxContainer = $VBoxContainer


@onready var reveal_popup: Control = $RevealPopup
@onready var reveal_text_label: Label = $RevealPopup/RevealText
@onready var reveal_ok_button: Button = $RevealPopup/RevealOkButton

var actor: Player = null
var eligible_targets: Array[Player] = []
var target_cards: Array[TargetPlayerCard] = []
var selected_target: Player = null
var selected_card: TargetPlayerCard = null

# Stanje za CONTROL (Veštica) — dvostepeni izbor: prvo KOGA kontroliše, pa KA KOME ga usmerava.
var is_control_mode: bool = false
var control_step: int = 0
var control_victim: Player = null

# Stanje za reveal popup (Milestone 12).
var reveal_pending: bool = false
var pending_reveal_message: String = ""

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	ignite_button.pressed.connect(_on_ignite_pressed)
	ignite_control.visible = false

	reveal_popup.visible = false
	reveal_ok_button.pressed.connect(_on_reveal_ok_pressed)
	EventBus.night_info_result.connect(_on_night_info_result)

func setup(p_actor: Player) -> void:
	actor = p_actor
	var role: Role = actor.role

	is_control_mode = role.night_action_type == Role.NightActionType.CONTROL
	control_step = 0
	control_victim = null

	var no_target: bool = role.night_action_type == Role.NightActionType.OBSERVE

	ignite_control.visible = role.night_action_type == Role.NightActionType.DOUSE
	target_selection_container.visible = true
	target_list.visible = not no_target
	confirm_button.text = "Potvrdi" if no_target else role.action_label

	if is_control_mode:
		instruction_label.text = "%s (%s): koga kontrolišeš?" % [actor.player_name, role.role_name]
	else:
		instruction_label.text = "%s (%s) — %s" % [actor.player_name, role.role_name, role.action_label]

	if no_target:
		_clear_targets()
		return

	# Prvi (glavni) korak biranja mete uvek koristi pravila iz actor.role
	# (can_target_dead / can_target_self / opposite_team_only) — sada
	# preko deljenog TargetResolver-a (Milestone 13), umesto ručno
	# ponovljene logike ovde.
	_populate_targets(role.can_target_dead, actor, true)

func _clear_targets() -> void:
	eligible_targets.clear()
	target_cards.clear()
	selected_target = null
	selected_card = null
	for child in target_list.get_children():
		child.queue_free()

## Popunjava target_list karticama (TargetPlayerCard) igračima koje ova
## akcija sme da cilja.
##
## apply_role_filters == true (standardni slučaj, koristi se iz setup()):
##   Pool se dobija preko TargetResolver.get_eligible_targets(actor) —
##   ISTA logika (can_target_dead / can_target_self / opposite_team_only)
##   koju night_menu.gd koristi da PROVERI da li uopšte postoji meta,
##   pre nego što odluči da prikaže action_menu ili status panel.
##   dead_pool/exclude argumenti se u ovoj grani ignorišu.
##
## apply_role_filters == false (podrazumevano — koristi ga DRUGI korak
## CONTROL sposobnosti, vidi _advance_control_step): dead_pool ručno
## bira pool, exclude se UVEK izbacuje, bez čitanja pravila iz actor.role.
func _populate_targets(dead_pool: bool, exclude: Player, apply_role_filters: bool = false) -> void:
	_clear_targets()

	var pool: Array[Player] = []
	if apply_role_filters:
		pool = TargetResolver.get_eligible_targets(actor)
	else:
		var raw_pool: Array[Player] = PlayerManager.get_dead_players() if dead_pool else PlayerManager.get_alive_players()
		for p in raw_pool:
			if p == exclude:
				continue
			pool.append(p)

	for p in pool:
		eligible_targets.append(p)
		_create_target_card(p)

	# Odloženo — mora da se izvrši POSLE što Godot izračuna layout ove
	# scene, inače bi self.size mogao biti (0,0) ili zastareo.
	call_deferred("_resize_target_cards")

func _create_target_card(p: Player) -> void:
	var card: TargetPlayerCard = TARGET_PLAYER_CARD.instantiate() as TargetPlayerCard
	target_list.add_child(card)
	card.setup(p)
	card.target_selected.connect(_on_target_card_selected)
	target_cards.append(card)

## Smanjuje svaku karticu tako da tačno CARDS_PER_ROW (5) stane u širinu
## dostupnog prostora, umesto da kartice "iscure" van grida. Takođe
## proporcionalno smanjuje font imena igrača na svakoj kartici, koristeći
## ISTI faktor skaliranja kao i sama kartica.
func _resize_target_cards() -> void:
	if target_cards.is_empty():
		return

	var available_width: float = size.x
	if available_width <= 0.0:
		return

	var h_separation: float = float(target_list.get_theme_constant("h_separation"))
	var total_separation: float = h_separation * (CARDS_PER_ROW - 1)
	var card_width: float = (available_width - total_separation) / CARDS_PER_ROW
	card_width = max(card_width, 1.0)

	var aspect_ratio: float = CARD_DESIGN_SIZE.y / CARD_DESIGN_SIZE.x
	var card_height: float = card_width * aspect_ratio

	var scale_factor: float = card_width / CARD_DESIGN_SIZE.x
	var font_size: int = int(round(NAME_LABEL_DESIGN_FONT_SIZE * scale_factor))
	font_size = max(font_size, NAME_LABEL_MIN_FONT_SIZE)

	for card in target_cards:
		card.custom_minimum_size = Vector2(card_width, card_height)
		card.set_name_font_size(font_size)

	target_list.queue_sort()

func _on_target_card_selected(player: Player, card: TargetPlayerCard) -> void:
	if selected_card != null and selected_card != card:
		selected_card.mark_unselected()
	card.mark_selected()
	selected_card = card
	selected_target = player

func _on_night_info_result(source: Player, target: Player, info_type: String, payload: Dictionary) -> void:
	if source != actor:
		return
	if actor.role == null or not actor.role.reveals_result_to_player:
		return
	pending_reveal_message = NightInfoFormatter.format(source, target, info_type, payload)
	reveal_pending = true

func _on_confirm_pressed() -> void:
	var role: Role = actor.role

	if role.night_action_type == Role.NightActionType.OBSERVE:
		EventBus.action_submitted.emit(actor, null, "observe")
		if reveal_pending:
			reveal_pending = false
			_show_reveal_popup()
		return

	if selected_target == null:
		return

	var chosen: Player = selected_target

	if is_control_mode:
		_advance_control_step(chosen)
		return

	var action_type: String = Role.night_action_string(role.night_action_type)
	if role.night_action_type == Role.NightActionType.DOUSE:
		action_type = "douse"   # Confirm dugme uvek znači "polij", Ignite dugme (ispod) šalje "ignite"

	EventBus.action_submitted.emit(actor, chosen, action_type)

	if reveal_pending:
		reveal_pending = false
		_show_reveal_popup()
		return

func _advance_control_step(chosen: Player) -> void:
	if control_step == 0:
		control_victim = chosen
		control_step = 1
		instruction_label.text = "Ka kome usmeravaš %s?" % control_victim.player_name
		# NOTE: second CONTROL step targets based on the redirected
		# player's context, not the actor's own role rules — left as an
		# explicit exception until multi-target actions are generalized
		_populate_targets(false, control_victim)
		return

	var forced_target: Player = chosen
	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase != null:
		night_phase.submit_control_action(actor, control_victim, forced_target)

func _show_reveal_popup() -> void:
	reveal_text_label.text = pending_reveal_message
	reveal_popup.visible = true
	confirm_button.disabled = true
	if is_instance_valid(ignite_button):
		ignite_button.disabled = true
	target_selection_container.visible = false

func _on_reveal_ok_pressed() -> void:
	reveal_popup.visible = false
	var phase: PhaseBase = PhaseStateMachine.get_current_phase()
	var night_phase: NightPhase = phase as NightPhase
	if night_phase != null:
		night_phase.acknowledge_reveal()

func _on_ignite_pressed() -> void:
	EventBus.action_submitted.emit(actor, null, "ignite")
