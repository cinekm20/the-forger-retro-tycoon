extends Node
## Kradzieże obrazów i ochrona (bodyguard) — mechanika udokumentowana w
## docs/DODATKOWE_MECHANIKI.md (pochodzi z sequela *Vermeer: Die Kunst zu
## erben*, 1997; tam odłożona jako "post-MVP", teraz wdrożona).
##
## Uproszczenia: ryzyko kradzieży sprawdzane jest tylko dla AKTYWNEGO gracza
## (spójne z resztą efektów zależnych od czasu, patrz Players.gd), a
## "gangster" wysłany na rywala nie zawsze się udaje — źródło wprost mówi,
## że gangsterzy "nie mają słynnego honoru wśród złodziei" i nie zawsze
## dostarczają towar.

signal painting_stolen_from_player(number: int)
signal gangster_attempt_failed()
signal gangster_attempt_succeeded(number: int)

const WEEKLY_THEFT_CHANCE_UNPROTECTED := 0.05  ## 5% szans/tydzień bez ochrony
const BODYGUARD_COST := 5000.0
const GANGSTER_COST := 3000.0

## Zgłoszenie użytkownika: nieudana próba (gangster nie dostarcza towaru) ma
## czasem oznaczać, że TWÓJ gangster wpada — dodatkowa grzywna NA CIEBIE,
## rywal zostaje bez zmian. Osobna szansa OD szansy powodzenia samego skoku
## (Gangsters.get_success_chance) — to dwa niezależne rzuty: "czy się udało"
## i, jeśli nie, "czy w ogóle się wsypał".
const CAUGHT_CHANCE_ON_FAILURE := 0.5
const CAUGHT_FINE := 2000.0

var has_bodyguard: bool = false


func reset_new_game() -> void:
	has_bodyguard = false


func hire_bodyguard() -> bool:
	if has_bodyguard:
		return false
	if not Economy.spend(BODYGUARD_COST):
		return false
	has_bodyguard = true
	return true


## Tor B — ryzyko kradzieży sprawdzane dla aktywnego gracza wg jego WŁASNYCH
## dni, wywoływane wprost przez Players.advance_active_player_time (NIE
## podłączone do Calendar.day_advanced).
func apply_player_days_elapsed(days_elapsed: int) -> void:
	if has_bodyguard or Paintings.catalogued_numbers.is_empty():
		return
	var weeks: float = float(days_elapsed) / 7.0
	if randf() < WEEKLY_THEFT_CHANCE_UNPROTECTED * weeks * Difficulty.risk_multiplier():
		var numbers := Paintings.catalogued_numbers
		var stolen_number: int = numbers[randi() % numbers.size()]
		numbers.erase(stolen_number)
		painting_stolen_from_player.emit(stolen_number)


## Rozstrzyga próbę skoku OD RAZU (przed animacją HeistView) — dokładnie ten
## sam podział co Races.gd::_pick_winner_index()/RaceTrackView: wynik jest
## ustalony PRZED zbudowaniem widoku, HeistView tylko go wizualizuje, nigdy
## nie zmienia. ŻADNYCH skutków ubocznych tutaj (ani kradzieży obrazu, ani
## grzywny) — patrz apply_gangster_result(), wołane DOPIERO po animacji.
## Zwraca Dictionary {"success", "caught", "stolen_number", "rival_id"}.
func resolve_gangster_attempt(gangster_id: String, rival_id: String) -> Dictionary:
	var rival: Dictionary = AIPlayers.get_rival(rival_id)
	var rival_paintings: Array = rival.get("paintings", [])
	var success := (
		not rival.is_empty()
		and not rival_paintings.is_empty()
		and randf() < Gangsters.get_success_chance(gangster_id)
	)
	var stolen_number := -1
	if success:
		stolen_number = rival_paintings[randi() % rival_paintings.size()]

	## "Twój gangster wpada" — zgłoszenie użytkownika: nieudana próba CZASEM
	## kończy się złapaniem TWOJEGO gangstera (dodatkowa grzywna na Ciebie),
	## rywal zostaje bez zmian. Sprawdzane tylko przy porażce — udany skok
	## nigdy nie kończy się złapaniem.
	var caught := not success and randf() < CAUGHT_CHANCE_ON_FAILURE * Difficulty.risk_multiplier()

	return {"success": success, "caught": caught, "stolen_number": stolen_number, "rival_id": rival_id}


## Nakłada faktyczne skutki JUŻ rozstrzygniętej próby (patrz
## resolve_gangster_attempt) — wołane PO zakończeniu animacji HeistView,
## dokładnie tak jak Races.gd::_on_race_finished nalicza wypłatę dopiero po
## animacji wyścigu. GANGSTER_COST płacony wcześniej, osobno, w
## SecurityScreen.gd (jak zakład w Races.gd) — tu tylko konsekwencje wyniku.
func apply_gangster_result(result: Dictionary) -> void:
	if result["success"]:
		var rival: Dictionary = AIPlayers.get_rival(result["rival_id"])
		var rival_paintings: Array = rival.get("paintings", [])
		rival_paintings.erase(result["stolen_number"])
		if not Paintings.catalogued_numbers.has(result["stolen_number"]):
			Paintings.catalogue(result["stolen_number"])
		gangster_attempt_succeeded.emit(result["stolen_number"])
	else:
		if result["caught"]:
			Economy.spend(CAUGHT_FINE)
		gangster_attempt_failed.emit()
