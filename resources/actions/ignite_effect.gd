class_name IgniteEffect
extends ActionEffect

## Piroman — pali sve trenutno polivene, žive igrače ODJEDNOM. NAMERNO
## zaobilazi is_jailed/protected_by/guarded_by u potpunosti — zapaljena
## smrt se ne može sprečiti nikakvom zaštitom
## (applyKills() eksplicitno preskače PROTECTED proveru za STATUS.IGNITED).
## target parametar se ne koristi — Piromanova akcija paljenja se poziva
## sa target = null (vidi action_menu.gd's action_submitted(actor, null, "ignite")).
func apply(source: Player, target: Player, night_phase: NightPhase, secondary_target: Player = null) -> void:
	for p in PlayerManager.players:
		if p.is_doused and p.is_alive:
			p.is_doused = false
			p.kill()
			EventBus.player_died.emit(p)
