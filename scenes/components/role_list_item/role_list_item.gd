extends Control
class_name RoleContainer

@onready var role_icon: TextureRect = $MarginContainer/RoleBorder/MarginContainer/RoleIcon
@onready var role_name_label: Label = $MarginContainer/RoleBorder/RoleNamePlate/RoleName
@onready var role_name_plate: Sprite2D = $MarginContainer/RoleBorder/RoleNamePlate
@onready var role_description_label: Label = $MarginContainer/RoleBorder/RoleDescription
@onready var role_team_label: Label = $MarginContainer/RoleBorder/RoleTeam
@onready var maximum_stamp: TextureRect = $MarginContainer/RoleBorder/MaximumStamp
@onready var add_button: Button = $MarginContainer/RoleBorder/Controls/VBoxContainer/Add
@onready var count_label: Label = $MarginContainer/RoleBorder/Controls/VBoxContainer/Count
@onready var remove_button: Button = $MarginContainer/RoleBorder/Controls/VBoxContainer/Remove
@onready var role_border: TextureRect = $MarginContainer/RoleBorder

const BORDERS: Array[Texture2D] = [
	preload("res://assets/images/role borders/border1.png"),
	preload("res://assets/images/role borders/border2.png"),
	preload("res://assets/images/role borders/border3.png"),
	preload("res://assets/images/role borders/border4.png"),
	preload("res://assets/images/role borders/border5.png"),
	preload("res://assets/images/role borders/border6.png"),
	preload("res://assets/images/role borders/border7.png"),
	preload("res://assets/images/role borders/border8.png")
]
var card_role: Role = null
var frame_count: int = 0
var is_debug: bool = false

func _ready() -> void:
	# Vizuelni "flavor" (nasumična varijanta pečata/nagib) — ne zavisi od card_role,
	# pa je bezbedno ovde bez obzira na redosled setup()/add_child().
	frame_count = int(role_name_plate.texture.get_height() / role_name_plate.region_rect.size.y)
	var random_index: int = randi_range(0, frame_count - 1)
	role_name_plate.region_rect.position.y = random_index * role_name_plate.region_rect.size.y
	role_name_plate.rotation_degrees = randf_range(-3.0, 3.0)
	
	maximum_stamp.rotation_degrees = randf_range(-35.0, 13.0)
	
	role_border.texture = BORDERS.pick_random()
	
	add_button.pressed.connect(_on_add_pressed)
	remove_button.pressed.connect(_on_remove_pressed)

## VAŽNO: pozivati OVU funkciju tek POSLE add_child(), jer čita @onready reference
## (role_icon, role_name_label...) koje ne postoje pre nego što node uđe u scensko stablo.
## p_is_debug: kad je true, dodavanje/uklanjanje ove role kartice takođe
## kreira/uklanja odgovarajućeg Player-a (vidi _on_add_pressed/_on_remove_pressed).
func setup(role: Role, p_is_debug: bool = false) -> void:
	card_role = role
	is_debug = p_is_debug
	role_icon.texture = role.icon
	role_name_label.text = role.role_name
	role_description_label.text = role.description
	role_team_label.text = Role.get_team_name(role.team)
	maximum_stamp.visible = role.is_unique
	_refresh_count()

func _on_add_pressed() -> void:
	var added: bool = RoleManager.add_role_to_pool(card_role)
	if not added:
		return   # unique rola je već u pool-u — RoleManager je tiho odbio, nema šta da se doda

	if is_debug:
		# Broj se čita POSLE add_role_to_pool(), pa novi igrač dobija NOVI, veći broj.
		var new_count: int = 0
		for r in RoleManager.role_pool_for_session:
			if r == card_role:
				new_count += 1
		var player_name: String = "%s%d" % [card_role.role_name, new_count]
		PlayerManager.add_player_with_role(player_name, card_role)

	_refresh_count()
	print("added")

func _on_remove_pressed() -> void:
	if is_debug:
		# Broj se čita PRE remove_role_from_pool(), da bismo obrisali igrača
		# sa brojem koji upravo NESTAJE, ne onim posle uklanjanja.
		var count_before: int = 0
		for r in RoleManager.role_pool_for_session:
			if r == card_role:
				count_before += 1
		if count_before > 0:
			var player_name: String = "%s%d" % [card_role.role_name, count_before]
			var p: Player = PlayerManager.get_player_by_name(player_name)
			if p != null:
				PlayerManager.remove_player(p)

	RoleManager.remove_role_from_pool(card_role)
	_refresh_count()

func _refresh_count() -> void:
	var count: int = 0
	for r in RoleManager.role_pool_for_session:
		if r == card_role:
			count += 1
	count_label.text = str(count)
	remove_button.disabled = count == 0
	add_button.disabled = card_role.is_unique and count >= 1
