class_name Role
extends Resource

enum RoleId { ADVISOR, AMNESIAC, AVENGER, BLACKMAILER, BODYGUARD, DETECTIVE, DOCTOR, DON, ESCORT, EXECUTIONER, FALSIFICATOR,
FOLLOWER, GRAVE_DIGGER, JAILOR, JUDGE, MADMAN, MAFIA, MAYOR, PARASITE, POISONER, PROSECUTOR, PYROMAN, REDACTOR, REPORTER, 
SERIAL_KILLER, SHERIF, SNIPER, SPY, TRACKER, VILLAGER, VISITOR, WITCH, CUSTOM }
enum Team { VILLAGE, MAFIA, NEUTRAL }
enum NightActionType {
	NONE,                    # nema noćnu akciju (uključujući dnevne role)
	KILL,                    # ubija metu
	PROTECT,                 # štiti metu od ubistva
	INVESTIGATE,             # otkriva tačnu/približnu ulogu ili pripadnost
	BLOCK,                   # sprečava metu da odigra svoju sposobnost
	CONTROL,                 # preusmerava tuđu akciju na drugu metu
	DOUSE,                   # polije metu (priprema za kasnije paljenje)
	IGNITE,                  # pali sve polivene mete (globalna akcija, ne bira metu)
	OBSERVE,                 # pasivno prati posete/kretanje bez biranja mete
	TRACK,                   # bira metu i saznaje koga je ona posetila
	CENSOR,                  # cenzuriše informacije o meti
	AUTOPSY,                 # istražuje MRTVOG igrača i saznaje njegovu stranu
	DECEIVE,                 # postavlja lažne informacije o meti za istraživače
	SILENCE,                 # meta ne može da govori sledećeg dana
	FRAME,                   # meta izgleda kao pripadnik Mafije pri istrazi
	JAIL,                    # zatvara metu (ne može da deluje niti bude ubijena)
	MARK,                    # označava metu (akumulira se, poseban win-condition trigger)
	INFEST,                  # bira metu; ako meta umre, preuzima njenu ulogu
	FOLLOW,                  # prati metu; ako meta umre, otkriva ubicu
	PROTECT_FROM_EXECUTION,  # štiti metu od pogubljenja SLEDEĆEG dana
	TAKE_ROLE,                # preuzima ulogu mrtvog igrača
}

@export var role_id: RoleId = RoleId.CUSTOM
@export var role_name: String = ""
@export var team: Team = Team.VILLAGE
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var night_priority: int = -1        # -1 = nema noćnu akciju; manji broj = deluje ranije
@export var is_unique: bool = true          # sme li postojati samo jednom po partiji
@export var can_act_at_night: bool = false
@export var action_label: String = ""       # tekst na dugmetu akcije u action_menu
@export_multiline var instruction_label: String = ""  # tekst instrukcije za ulogu tokom noci
@export var night_action_type: NightActionType = NightActionType.NONE

## true SAMO za role čiji noćni rezultat mora biti prikazan glumcu (akteru)
## PRE nego što narator može da nastavi na sledećeg igrača (npr. istraživačke
## role) — pauzira napredovanje poteza u NightPhase-u dok se ne pozove
## NightPhase.acknowledge_reveal().
@export var reveals_result_to_player: bool = false

## Opciono: ako je dodeljen, NightPhase poziva night_action_effect.apply()
## umesto starog match statement-a u _apply_action_effect(). null (default)
## znači "još nije migrirano — koristi stari fallback match".
@export var night_action_effect: ActionEffect = null
# --- Pravila biranja mete (koristi action_menu.gd _populate_targets) ---
# can_target_dead: true SAMO za role čija sposobnost zahteva biranje MRTVOG igrača
# (npr. Pogrebnik, Amnezičar). Podrazumevano false — većina rola bira žive igrače.
@export var can_target_dead: bool = false
# can_target_self: true SAMO za role kojima je dozvoljeno da izaberu SEBE kao metu.
# Podrazumevano false — većina rola ne može ciljati sebe.
@export var can_target_self: bool = false
# opposite_team_only: true SAMO za role čija sposobnost sme ciljati isključivo
# igrače sa DRUGAČIJIM timom od aktera (npr. ubistvo Mafije). Podrazumevano false.
@export var opposite_team_only: bool = false

static func get_team_name(team: Team) -> String:
	match team:
		Team.VILLAGE:
			return "Selo"
		Team.MAFIA:
			return "Mafija"
		Team.NEUTRAL:
			return "Neutralan"
	return ""
	
static func night_action_string(action_type: NightActionType) -> String:
	match action_type:
		NightActionType.NONE:
			return "none"
		NightActionType.KILL:
			return "kill"
		NightActionType.PROTECT:
			return "protect"
		NightActionType.INVESTIGATE:
			return "investigate"
		NightActionType.BLOCK:
			return "block"
		NightActionType.CONTROL:
			return "control"
		NightActionType.DOUSE:
			return "douse"
		NightActionType.IGNITE:
			return "ignite"
		NightActionType.OBSERVE:
			return "observe"
		NightActionType.TRACK:
			return "track"
		NightActionType.CENSOR:
			return "censor"
		NightActionType.AUTOPSY:
			return "autopsy"
		NightActionType.DECEIVE:
			return "decieve"
		NightActionType.SILENCE:
			return "silence"
		NightActionType.FRAME:
			return "frame"
		NightActionType.JAIL:
			return "jail"
		NightActionType.MARK:
			return "mark"
		NightActionType.INFEST:
			return "infest"
		NightActionType.FOLLOW:
			return "follow"
		NightActionType.PROTECT_FROM_EXECUTION:
			return "protect_from_execution"
		NightActionType.TAKE_ROLE:
			return "take_role"
	return ""
