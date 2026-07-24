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
const GANGSTER_SUCCESS_CHANCE := 0.4  ## "nie zawsze dostarczają towar"

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
	if randf() < WEEKLY_THEFT_CHANCE_UNPROTECTED * weeks:
		var numbers := Paintings.catalogued_numbers
		var stolen_number: int = numbers[randi() % numbers.size()]
		numbers.erase(stolen_number)
		painting_stolen_from_player.emit(stolen_number)


## Wysyła gangstera po obraz rywala. Zwraca true tylko przy sukcesie —
## opłata (GANGSTER_COST) przepada niezależnie od wyniku.
func send_gangster(rival_id: String) -> bool:
	if not Economy.spend(GANGSTER_COST):
		return false
	var rival: Dictionary = AIPlayers.get_rival(rival_id)
	if rival.is_empty():
		gangster_attempt_failed.emit()
		return false
	var rival_paintings: Array = rival.get("paintings", [])
	if rival_paintings.is_empty() or randf() >= GANGSTER_SUCCESS_CHANCE:
		gangster_attempt_failed.emit()
		return false
	var stolen_number: int = rival_paintings[randi() % rival_paintings.size()]
	rival_paintings.erase(stolen_number)
	if not Paintings.catalogued_numbers.has(stolen_number):
		Paintings.catalogue(stolen_number)
	gangster_attempt_succeeded.emit(stolen_number)
	return true
