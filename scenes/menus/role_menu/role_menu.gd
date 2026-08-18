extends Control

@export var role_container_scene: PackedScene
@export var roles_per_leaf: int = 4

@onready var start_game_button: Button = $MarginContainer/StartGameButton
@onready var status_label: Label = $MarginContainer/StatusLabel
@onready var prev_page_button: Button = $MarginContainer/PageControls/PrevPageButton
@onready var next_page_button: Button = $MarginContainer/PageControls/NextPageButton
@onready var page_label: Label = $MarginContainer/PageControls/PageLabel

@onready var dossier_background: TextureRect = $MarginContainer/DossierFrame/DossierBackground
@onready var left_viewport: SubViewport = $MarginContainer/LeftLeafViewportContainer/SubViewport
@onready var right_viewport: SubViewport = $MarginContainer/RightLeafViewportContainer/SubViewport
@onready var left_grid: GridContainer = $MarginContainer/LeftLeafViewportContainer/SubViewport/LeftLeafGrid
@onready var right_grid: GridContainer = $MarginContainer/RightLeafViewportContainer/SubViewport/RightLeafGrid
@onready var page_turn_overlay: PageTurnOverlay = $MarginContainer/PageTurnOverlay
@onready var left_container: Control = $MarginContainer/LeftLeafViewportContainer
@onready var right_container: Control = $MarginContainer/RightLeafViewportContainer
@onready var preview_viewport: SubViewport = $MarginContainer/PreviewViewportContainer/SubViewport
@onready var preview_grid: GridContainer = $MarginContainer/PreviewViewportContainer/SubViewport/PreviewGrid


var current_page: int = 0
var is_transitioning: bool = false
var is_debug_mode: bool = false

func _ready() -> void:
	start_game_button.pressed.connect(_on_start_game_pressed)
	prev_page_button.pressed.connect(_on_prev_page_pressed)
	next_page_button.pressed.connect(_on_next_page_pressed)
	status_label.text = ""
	page_turn_overlay.visible = false
	
	call_deferred("_populate_initial_pages")

func _populate_initial_pages() -> void:
	var total_pages: int = _total_pages()
	_populate_leaf(left_grid, 0, false)
	_populate_leaf(right_grid, 0, true)
	_update_page_controls(total_pages)

## Poziva ga SceneManager.switch_to("role_menu", true) iz main_menu.gd
## kad je debug dugme pritisnuto — vidi Milestone 6 mehanizam.
func setup(data) -> void:
	is_debug_mode = data

func _total_pages() -> int:
	var roles_per_spread: int = roles_per_leaf * 2
	var role_count: int = RoleManager.available_roles.size()
	if role_count == 0:
		return 1
	return int(ceil(float(role_count) / float(roles_per_spread)))

## Napreduje ka sledećem spread-u; animira SAMO desni list.
func _on_next_page_pressed() -> void:
	if is_transitioning:
		return
	var total_pages: int = _total_pages()
	if current_page >= total_pages - 1:
		return
	await _flip_leaf(1)

## Vraća se na prethodni spread; animira SAMO levi list.
func _on_prev_page_pressed() -> void:
	if is_transitioning:
		return
	if current_page <= 0:
		return
	await _flip_leaf(-1)
	
func _flip_leaf(direction: int) -> void:
	is_transitioning = true
	prev_page_button.disabled = true
	next_page_button.disabled = true

	var is_right_leaf: bool = direction == 1
	var reveal_viewport: SubViewport = right_viewport if is_right_leaf else left_viewport
	var reveal_grid: GridContainer = right_grid if is_right_leaf else left_grid
	var landing_grid: GridContainer = left_grid if is_right_leaf else right_grid

	# 1) FRONT tekstura = STARI sadržaj strane sa koje list kreće — mora se snimiti PRE bilo kakve izmene.
	var front_snapshot: Texture2D = _capture_snapshot(reveal_viewport)

	current_page += direction

	# 2) Strana sa koje list ODLAZI dobija novi sadržaj ODMAH — vidljiv je tek kad ga overlay discard-uje.
	_populate_leaf(reveal_grid, current_page, is_right_leaf)

	# 3) Strana na koju list SLEĆE se NE dira — umesto toga, novi sadržaj se renderuje u skriveni PreviewGrid
	#    da bismo dobili BACK tehnicru bez diranja vidljivog landing_viewport-a.
	_populate_leaf(preview_grid, current_page, not is_right_leaf)

	await get_tree().process_frame
	await get_tree().process_frame

	var back_snapshot: Texture2D = _capture_snapshot(preview_viewport)

	for child in preview_grid.get_children():
		child.queue_free()

	var total_pages: int = _total_pages()
	await page_turn_overlay.play(front_snapshot, back_snapshot, direction)

	# 4) TEK SADA menjamo stvarni sadržaj strane na koju je list sleteo — bešavno, jer se poklapa sa back teksturom.
	_populate_leaf(landing_grid, current_page, not is_right_leaf)

	is_transitioning = false
	_update_page_controls(total_pages)
func _capture_snapshot(viewport: SubViewport) -> Texture2D:
	var img: Image = viewport.get_texture().get_image()
	return ImageTexture.create_from_image(img)

## Popunjava JEDAN list (levi ili desni) rolama za dati spread.
func _populate_leaf(grid: GridContainer, page: int, is_right: bool) -> void:
	for child in grid.get_children():
		child.queue_free()

	var spread_start: int = page * roles_per_leaf * 2
	var leaf_start: int = spread_start + (roles_per_leaf if is_right else 0)
	var leaf_end: int = mini(leaf_start + roles_per_leaf, RoleManager.available_roles.size())

	for i in range(leaf_start, leaf_end):
		var role: Role = RoleManager.available_roles[i]
		var role_container: RoleContainer = role_container_scene.instantiate() as RoleContainer
		grid.add_child(role_container)
		role_container.setup(role, is_debug_mode)
		
func _update_page_controls(total_pages: int) -> void:
	page_label.text = "Strana %d / %d" % [current_page + 1, total_pages]
	prev_page_button.disabled = current_page == 0
	next_page_button.disabled = current_page >= total_pages - 1

func _on_start_game_pressed() -> void:
	var player_count: int = PlayerManager.players.size()
	var role_count: int = RoleManager.role_pool_for_session.size()

	if player_count == 0:
		status_label.text = "Nema dodatih igrača — vrati se na prethodni ekran."
		return

	if role_count > player_count:
		status_label.text = "Izabrano je više uloga (%d) nego igrača (%d) — ukloni neku ulogu." % [role_count, player_count]
		return

	if role_count < player_count:
		RoleManager.fill_remaining_with_villagers(player_count)

	# DEBUG MODE: igrači su već ručno dobili tačno određenu rolu preko
	# role_list_item.gd (add_player_with_role) — ne mešamo/ne dodeljujemo
	# ponovo, samo preskačemo shuffle. assign_special_targets() se i
	# dalje poziva u OBA slučaja (npr. za Dželata/Executioner metu).
	if not is_debug_mode:
		RoleManager.assign_roles(PlayerManager.players)
#	RoleManager.assign_special_targets(PlayerManager.players)

	if is_debug_mode:
		PhaseStateMachine.transition_to(PhaseStateMachine.Phase.NIGHT)
		SceneManager.switch_to("night_menu")
	else:
		PhaseStateMachine.transition_to(PhaseStateMachine.Phase.ROLE_REVEAL)
		SceneManager.switch_to("role_reveal")
