class_name Player
extends RefCounted

var player_name: String = ""
var player_icon: Texture2D
var role: Role = null              # referenca na deljeni Role resurs (read-only template)
var is_alive: bool = true

# Polja relevantna za noćne akcije / glasanje:
var night_target: Player = null    # koga je ovaj igrač izabrao kao metu prošle noći
var protected_by: Player = null    # ko ga štiti ove noći (npr. doktor), resetuje se svako veče
# Telohranitelj koji čuva ovog igrača ove noći, ako postoji — ako je ovaj
# igrač napadnut, TELOHRANITELJ umire umesto njega, a ovaj igrač preživljava.
# Odvojeno polje od protected_by, jer su pravila drugačija (redirekcija
# umesto potpunog otkazivanja napada) — vidi NightPhase._resolve_single_kill().
var guarded_by: Player = null
# Parazit koji je označio ovog igrača ove noći, ako postoji — ako ovaj
# igrač UMRE tokom noćnog razrešenja ubistava, PARAZIT nasleđuje njegovu
# ulogu u tom trenutku. Vidi NightPhase._resolve_single_kill().
var infested_by: Player = null
var votes_received: int = 0        # glasovi primljeni tokom trenutnog lynch glasanja
var has_acted_tonight: bool = false

# CONTROL (Veštica) — ako je postavljeno, NightPhase._prompt_current_or_resolve()
# preskače ručni unos za ovog igrača i njegova akcija se automatski primenjuje
# na ovog forced_target-a. Postavlja ga NightPhase.submit_control_action().
var forced_target: Player = null

# Statusna polja koja postavlja NightPhase._apply_action_effect() —
# svako predstavlja efekat jedne noćne akcije primenjene NA ovog igrača kao metu.
var is_blocked: bool = false                  # ne može da koristi svoju sposobnost ove noći
var is_doused: bool = false                   # poliven benzinom (Piroman) — spreman za paljenje
var is_censored: bool = false                 # informacije o njemu su cenzurisane
var is_deceived: bool = false                 # istraživanja o njemu vraćaju lažan rezultat
var is_silenced: bool = false                 # ne može da govori sledećeg dana
var is_framed: bool = false                   # izgleda kao mafija pri istraživanju
var is_jailed: bool = false                   # zatvoren — ne deluje i ne može biti ubijen
var is_marked: bool = false                   # označen (Posetilac) — akumulira se
var is_infested: bool = false                 # ako umre, Parazit preuzima njegovu ulogu
var followed_by: Array[Player] = []           # igrači koji prate ovog igrača (Reporter)
var protected_from_execution: bool = false    # zaštićen od pogubljenja sledećeg dana (Sudija)

# Polja koja koristi ActionMenu/NightMenu za prikaz rezultata (van night_phase.gd,
# ali čitaju se preko Player-a):
var last_night_action_target: Player = null
var night_visitors: Array[Player] = []

func _init(p_name: String = "", p_role: Role = null) -> void:
	player_name = p_name
	role = p_role

func assign_role(new_role: Role) -> void:
	role = new_role

func kill() -> void:
	is_alive = false

func reset_nightly_state() -> void:
	night_target = null
	protected_by = null
	guarded_by = null
	infested_by = null
	has_acted_tonight = false
	forced_target = null
	last_night_action_target = null
	night_visitors = []

	is_blocked = false
	is_censored = false
	is_deceived = false
	is_silenced = false
	is_framed = false
	is_jailed = false
	is_marked = false
	is_infested = false
	followed_by = []
	# protected_from_execution nije resetovan ovde — namerno traje do sledećeg
	# dnevnog linč glasanja (Sudija ga postavlja noću da zaštiti metu SLEDEĆI dan).
	# Trenutno LynchPhase još ne čita ovo polje; kad se to doda, treba ga resetovati
	# u LynchPhase nakon što se linč razreši, ne ovde.

func reset_voting_state() -> void:
	votes_received = 0

func to_dict() -> Dictionary:
	# koristi save_manager za serijalizaciju partije
	return {
		"player_name": player_name,
		"role_name": role.role_name if role else "",
		"is_alive": is_alive,
	}
