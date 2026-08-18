extends Control

@onready var progress_label: Label = $ProgressLabel
@onready var current_player_label: Label = $CurrentPlayerLabel
@onready var role_card: Control = $RoleCard
@onready var role_name_label: Label = $RoleCard/RoleNameLabel
@onready var role_team_label: Label = $RoleCard/RoleTeamLabel
@onready var description_label: Label = $RoleCard/DescriptionLabel
@onready var execution_target_label: Label = $RoleCard/ExecutionTargetLabel
@onready var hold_button: Control = $HoldToRevealButton
@onready var next_button: Button = $NextPlayerButton
@onready var role_visibility_controls: Control = $RoleVisibilityControls
@onready var role_polaroid_overlay: Sprite2D = $RoleVisibilityControls/RolePolaroidOverlay
@onready var censorship: Sprite2D = $RoleVisibilityControls/Censorship


@export var development_duration: float = 4.0   # gornja granica trajanja PUNE animacije (0.0 -> 1.0)
@export var development_delay: float = 0.5      # pauza pre početka, SAMO pri startu od 0.0

const REVEAL_THRESHOLD: float = 0.1   # development_progress posle kog role_card postaje vidljiv

var current_index: int = 0
var progress_tween: Tween = null

var mat: ShaderMaterial
var censored: ShaderMaterial

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	hold_button.hold_started.connect(_on_hold_started)
	hold_button.hold_stopped.connect(_on_hold_stopped)

	mat = _get_shader_material(role_polaroid_overlay)
	censored = _get_shader_material(censorship)
	if mat != null:
		mat.set_shader_parameter("development_progress", 0.0)
	if censored != null:
		censored.set_shader_parameter("reveal", 0.0)

	if PlayerManager.players.is_empty():
		push_error("Nema igrača u PlayerManager — role_reveal ne treba da se otvori bez igrača.")
		return

	_show_current_player()

func _get_shader_material(node) -> ShaderMaterial:
	var shadermaterial: ShaderMaterial = node.material as ShaderMaterial
	if shadermaterial == null:
		push_error("Missing ShaderMaterial on this node!")
	return shadermaterial

func _current_development_progress() -> float:
	if mat == null:
		return 0.0
	return float(mat.get_shader_parameter("development_progress"))

func _set_development_progress(value: float) -> void:
	if mat == null:
		return
	mat.set_shader_parameter("development_progress", value)
	censored.set_shader_parameter("reveal", value)

	var should_show_role: bool = value >= REVEAL_THRESHOLD
	role_card.visible = should_show_role

func _show_current_player() -> void:
	role_card.visible = false
	execution_target_label.visible = false
	role_visibility_controls.visible = true
	next_button.disabled = true

	if progress_tween != null and progress_tween.is_valid():
		progress_tween.kill()

	if mat != null:
		mat.set_shader_parameter("development_progress", 0.0)
		censored.set_shader_parameter("reveal", 0.0)

	var player: Player = PlayerManager.players[current_index]
	var total: int = PlayerManager.players.size()

	progress_label.text = "Igrač %d od %d" % [current_index + 1, total]
	current_player_label.text = "Daj telefon igraču: %s" % player.player_name

func _on_hold_started() -> void:
	var player: Player = PlayerManager.players[current_index]
	var role: Role = player.role

	if role == null:
		push_error("Igrač '%s' nema dodeljenu rolu — proveri role_manager.assign_roles()." % player.player_name)
		return

	role_name_label.text = role.role_name
	role_team_label.text = Role.get_team_name(role.team)
	description_label.text = role.description

	if role.role_id == Role.RoleId.EXECUTIONER and player.execution_target != null:
		execution_target_label.text = "Tvoja meta je: %s" % player.execution_target.player_name
		execution_target_label.visible = true
	else:
		execution_target_label.visible = false

	if mat == null:
		return

	if progress_tween != null and progress_tween.is_valid():
		progress_tween.kill()

	var current_progress: float = _current_development_progress()
	var remaining: float = 1.0 - current_progress
	var duration: float = development_duration * remaining

	progress_tween = create_tween()
	progress_tween.set_ease(Tween.EASE_OUT)
	progress_tween.set_trans(Tween.TRANS_QUAD)

	if current_progress <= 0.0:
		progress_tween.tween_interval(development_delay)

	progress_tween.tween_method(_set_development_progress, current_progress, 1.0, duration)
	progress_tween.finished.connect(_on_development_finished)

func _on_hold_stopped() -> void:
	if mat == null:
		return

	if progress_tween != null and progress_tween.is_valid():
		progress_tween.kill()

	var current_progress: float = _current_development_progress()
	var duration: float = development_duration * current_progress   # proporcionalno preostalom putu nazad

	progress_tween = create_tween()
	progress_tween.set_ease(Tween.EASE_IN)
	progress_tween.set_trans(Tween.TRANS_QUAD)
	progress_tween.tween_method(_set_development_progress, current_progress, 0.0, duration)

func _on_development_finished() -> void:
	next_button.disabled = false

func _on_next_pressed() -> void:
	current_index += 1
	if current_index >= PlayerManager.players.size():
		PhaseStateMachine.transition_to(PhaseStateMachine.Phase.NIGHT)
		SceneManager.switch_to("night_menu")
		return
	_show_current_player()
