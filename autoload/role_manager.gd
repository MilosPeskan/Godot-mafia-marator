extends Node

var available_roles: Array[Role] = []       # sve role učitane iz res://resources/roles/
var role_pool_for_session: Array[Role] = []  # koje je moderator izabrao za TRENUTNU partiju

const ROLE_PATHS := [
	"res://resources/roles/advisor.tres",
	"res://resources/roles/amnesiac.tres",
	"res://resources/roles/avenger.tres",
	"res://resources/roles/blackmailer.tres",
	"res://resources/roles/bodyguard.tres",
	"res://resources/roles/detective.tres",
	"res://resources/roles/doctor.tres",
	"res://resources/roles/don.tres",
	"res://resources/roles/escort.tres",
	"res://resources/roles/executioner.tres",
	"res://resources/roles/falsificator.tres",
	"res://resources/roles/follower.tres",
	"res://resources/roles/grave_digger.tres",
	"res://resources/roles/jailor.tres",
	"res://resources/roles/judge.tres",
	"res://resources/roles/madman.tres",
	"res://resources/roles/mafia.tres",
	"res://resources/roles/mayor.tres",
	"res://resources/roles/parasite.tres",
	"res://resources/roles/poisoner.tres",
	"res://resources/roles/prosecutor.tres",
	"res://resources/roles/pyroman.tres",
	"res://resources/roles/redactor.tres",
	"res://resources/roles/reporter.tres",
	"res://resources/roles/serial_killer.tres",
	"res://resources/roles/sherif.tres",
	"res://resources/roles/sniper.tres",
	"res://resources/roles/spy.tres",
	"res://resources/roles/tracker.tres",
	"res://resources/roles/villager.tres",
	"res://resources/roles/visitor.tres",
	"res://resources/roles/witch.tres"
]

func load_all_roles() -> void:
	available_roles.clear()
	for path in ROLE_PATHS:
		var role: Role = load(path)
		if role != null:
			available_roles.append(role)

func get_role_by_name(role_name: String) -> Role:
	for r in available_roles:
		if r.role_name == role_name:
			return r
	return null
	
func get_role_by_id(role_id: int) -> Role:
	for r in available_roles:
		if r.role_id == role_id:
			return r
	return null

## Dodaje rolu u pool za trenutnu partiju. Vraća false ako je unique rola već u pool-u
## (koristi ovo u role_menu.gd da spreči korisnika da doda npr. dva Doktora).
func add_role_to_pool(role: Role) -> bool:
	if role.is_unique and role_pool_for_session.has(role):
		return false
	role_pool_for_session.append(role)
	return true

func remove_role_from_pool(role: Role) -> void:
	var idx := role_pool_for_session.find(role)
	if idx != -1:
		role_pool_for_session.remove_at(idx)

## Dopunjava role_pool_for_session sa Villager rolama dok ne dostigne target_count.
## Koristi se kad moderator izabere manje uloga nego što ima igrača — Villager
## je bezbedan default jer nema noćnu akciju i is_unique = false (može ih biti više).
func fill_remaining_with_villagers(target_count: int) -> void:
	var villager_role: Role = get_role_by_id(Role.RoleId.VILLAGER)
	if villager_role == null:
		push_error("Nema učitane Villager role — proveri role_id polje u villager.tres.")
		return

	while role_pool_for_session.size() < target_count:
		role_pool_for_session.append(villager_role)

func reset_pool() -> void:
	role_pool_for_session.clear()

## Provera da pool ne sadrži istu unique rolu više puta (odbrana od greške u kodu,
## ne oslanja se samo na add_role_to_pool disciplinu).
func validate_role_pool() -> bool:
	var seen_unique := {}
	for r in role_pool_for_session:
		if r.is_unique:
			if seen_unique.has(r.role_name):
				push_error("Rola '%s' je unique ali se pojavljuje više puta u pool-u." % r.role_name)
				return false
			seen_unique[r.role_name] = true
	return true

## Nasumično dodeljuje role iz role_pool_for_session igračima.
## Zahteva da broj rola u pool-u tačno odgovara broju igrača.
func assign_roles(players: Array[Player]) -> void:
	if role_pool_for_session.size() != players.size():
		push_error("Broj rola u pool-u (%d) ne odgovara broju igrača (%d)." % [role_pool_for_session.size(), players.size()])
		return

	if not validate_role_pool():
		return

	var shuffled_pool: Array[Role] = role_pool_for_session.duplicate()
	shuffled_pool.shuffle()

	for i in players.size():
		var player := players[i]
		var role := shuffled_pool[i]
		player.assign_role(role)
		EventBus.role_assigned.emit(player, role)
