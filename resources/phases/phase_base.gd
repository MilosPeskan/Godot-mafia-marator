class_name PhaseBase
extends RefCounted

## Referenca na PhaseStateMachine autoload — ubrizgava se kroz _init.
## Omogućava fazi da sama pozove state_machine.transition_to() kad zaključi da je gotova.
var state_machine: Node = null

func _init(p_state_machine: Node) -> void:
	state_machine = p_state_machine

## Poziva se jednom kad faza postane aktivna. Ovde ide setup (reset stanja, redosled poteza...).
func enter() -> void:
	pass

## Poziva se jednom kad se napušta faza. Ovde ide cleanup ako je potreban.
func exit() -> void:
	pass

## Poziva se kad neki UI meni emituje EventBus.action_submitted dok je ova faza aktivna.
## Svaka faza sama odlučuje da li je akcija za nju relevantna i šta znači.
func handle_action(source: Player, target: Player, action_type: String) -> void:
	pass
