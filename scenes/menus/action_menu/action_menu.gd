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
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var ignite_button: Button = $VBoxContainer/IgniteButton   # samo za Pirmana (DOUSE tip), sakriven inače

var actor: Player = null
var eligible_targets: Array[Player] = []
var target_cards: Array[TargetPlayerCard] = []
var selected_target: Player = null
var selected_card: TargetPlayerCard = null

# Stanje za CONTROL (Veštica) — dvostepeni izbor: prvo KOGA kontroliše, pa KA KOME ga usmerava.
var is_control_mode: bool = false
var control_step: int = 0
var control_victim: Player = null

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	ignite_button.pressed.connect(_on_ignite_pressed)
	ignite_button.visible = false

func setup(p_actor: Player) -> void:
	actor = p_actor
	var role: Role = actor.role

	is_control_mode = role.night_action_type == Role.NightActionType.CONTROL
	control_step = 0
	control_victim = null

	var no_target: bool = role.night_action_type == Role.NightActionType.OBSERVE

	ignite_button.visible = role.night_action_type == Role.NightActionType.DOUSE
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
	# (can_target_dead / can_target_self / opposite_team_only).
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
##   Pool i filteri se izvode DIREKTNO iz actor.role — dead_pool argument
##   se u tom slučaju ignoriše (naveden je samo radi čitljivosti poziva).
##   - pool = mrtvi ako actor.role.can_target_dead, inače živi
##   - exclude se izbacuje SAMO ako actor.role.can_target_self == false
##   - ako actor.role.opposite_team_only, dodatno se izbacuju igrači
##     istog tima kao actor.role.team
##
## apply_role_filters == false (podrazumevano — koristi ga DRUGI korak
## CONTROL sposobnosti, vidi _advance_control_step): dead_pool ručno
## bira pool, exclude se UVEK izbacuje, bez čitanja pravila iz actor.role.
func _populate_targets(dead_pool: bool, exclude: Player, apply_role_filters: bool = false) -> void:
	_clear_targets()

	var role: Role = actor.role
	var use_dead_pool: bool = role.can_target_dead if apply_role_filters else dead_pool
	var pool: Array[Player] = PlayerManager.get_dead_players() if use_dead_pool else PlayerManager.get_alive_players()

	for p in pool:
		if apply_role_filters:
			if not role.can_target_self and p == exclude:
				continue
			if role.opposite_team_only and p.role != null and p.role.team == role.team:
				continue
		else:
			if p == exclude:
				continue

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
##
## Širina se računa na osnovu self.size (ActionMenu-ov sopstveni,
## FIKSNI pravougaonik — dobija ga od svog roditelja u night_menu.tscn),
## a NE na osnovu target_list.size, jer bi to bilo kružno: širina grida
## zavisi od dece, a mi upravo pokušavamo da kontrolišemo veličinu dece.
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

	# Isti razmer (card_width / dizajn širina) primenjen na dizajn
	# veličinu fonta — kartica i tekst se skaliraju zajedno.
	var scale_factor: float = card_width / CARD_DESIGN_SIZE.x
	var font_size: int = int(round(NAME_LABEL_DESIGN_FONT_SIZE * scale_factor))
	font_size = max(font_size, NAME_LABEL_MIN_FONT_SIZE)

	for card in target_cards:
		card.custom_minimum_size = Vector2(card_width, card_height)
		card.set_name_font_size(font_size)

	target_list.queue_sort()

## GridContainer nema ugrađen koncept "selektovane stavke" (za razliku od
## ItemList-a) — zato ovde ručno pratimo koja je kartica trenutno izabrana
## i ponašamo se kao radio-dugmad: biranje nove kartice poništava staru.
func _on_target_card_selected(player: Player, card: TargetPlayerCard) -> void:
	if selected_card != null and selected_card != card:
		selected_card.mark_unselected()
	card.mark_selected()
	selected_card = card
	selected_target = player

func _on_confirm_pressed() -> void:
	var role: Role = actor.role

	if role.night_action_type == Role.NightActionType.OBSERVE:
		EventBus.action_submitted.emit(actor, null, "observe")
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

func _on_ignite_pressed() -> void:
	EventBus.action_submitted.emit(actor, null, "ignite")
