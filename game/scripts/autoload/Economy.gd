extends Node
## Stan ekonomiczny gracza: gotówka, inflacja, kurs dolara, reformy walutowe.
## Startowe wartości wg realiów gry: 1 stycznia 1918, Londyn.
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 6, docs/DODATKOWE_MECHANIKI.md.

signal currency_reform(ratio: float)

const STARTING_MONEY := 50000.0
const STARTING_DOLLAR_RATE := 4.0  ## marek za dolara
const STARTING_INFLATION := 0.07  ## 7%

## Reforma zbliża się, gdy kurs dolara przekroczy tę wartość.
const REFORM_WARNING_DOLLAR_RATE := 14.0
const REFORM_RATIO := 5.0  ## zgodnie z realiami gry (przelicznik 5:1)
const REFORM_CHANCE_PER_WEEK := 0.15  ## szansa reformy w tygodniu, gdy grozi

const NEW_YEAR_MONEY_RANGE := Vector2(1000.0, 5000.0)
const NEW_YEAR_PAINTING_CHANCE := 0.15  ## docs/DODATKOWE_MECHANIKI.md — Noworoczna Loteria

## Bankructwo: przegrana, jeśli gotówka pozostaje ujemna przez tyle dni
## z rzędu — docs/GDD.md pkt. 6.
const BANKRUPTCY_THRESHOLD_DAYS := 60

var player_money: float = STARTING_MONEY
var dollar_rate: float = STARTING_DOLLAR_RATE
var inflation: float = STARTING_INFLATION
var days_in_debt: int = 0


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)
	Calendar.new_year.connect(_on_new_year)


func reset_new_game() -> void:
	player_money = STARTING_MONEY
	dollar_rate = STARTING_DOLLAR_RATE
	inflation = STARTING_INFLATION
	days_in_debt = 0


func is_bankrupt() -> bool:
	return days_in_debt >= BANKRUPTCY_THRESHOLD_DAYS


func is_reform_imminent() -> bool:
	return dollar_rate >= REFORM_WARNING_DOLLAR_RATE


## Wywoływać gdy silnik decyzyjny gry uzna, że reforma powinna nastąpić
## (np. po przekroczeniu progu przez dłuższy czas). ratio np. 5.0 = reforma 5:1.
## Dotyka gotówki WSZYSTKICH graczy (Players.apply_reform_to_all), nie tylko
## aktywnego — to zdarzenie globalne, nie efekt czyjejś tury.
func apply_currency_reform(ratio: float) -> void:
	dollar_rate /= ratio
	Players.apply_reform_to_all(ratio)
	currency_reform.emit(ratio)


func can_afford(amount: float) -> bool:
	return player_money >= amount


func spend(amount: float) -> bool:
	if not can_afford(amount):
		return false
	player_money -= amount
	return true


func earn(amount: float) -> void:
	player_money += amount


## Tor A — wspólne dla wszystkich graczy: kurs dolara, inflacja, reforma
## walutowa. Zostaje podłączone do Calendar.day_advanced (globalny zegar) bez
## zmian — te zjawiska naprawdę dzieją się "w świecie", nie osobno dla
## każdego gracza.
func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	var weeks: float = float(days_elapsed) / 7.0
	dollar_rate *= 1.0 + inflation * 0.01 * weeks
	inflation += randf_range(-0.002, 0.004) * weeks
	inflation = max(0.0, inflation)

	if is_reform_imminent() and randf() < REFORM_CHANCE_PER_WEEK * weeks:
		apply_currency_reform(REFORM_RATIO)


## Tor B — osobiste dla aktywnego gracza: dni w długu. Wydzielone z
## _on_day_advanced (patrz wyżej) i wywoływane wprost przez
## Players.advance_active_player_time — bez tego zadłużenie gracza
## "doganiającego" resztę liczyłoby się na podstawie delty świata, a nie
## jego własnych dni.
func apply_player_days_elapsed(days_elapsed: int) -> void:
	if player_money < 0.0:
		days_in_debt += days_elapsed
	else:
		days_in_debt = 0


## Noworoczna Loteria (Neujahrstombola) — docs/GDD.md pkt. 4.8,
## docs/DODATKOWE_MECHANIKI.md. Trafia w losowego gracza (Players), niekoniecznie
## akurat aktywnego — to też zdarzenie globalne, nie efekt czyjejś tury. Wynik
## trafia do Lottery.gd (patrz ten plik) — czeka tam do najbliższego wejścia
## do Huba, które pokazuje animowany ekran NewYearLottery.gd (fajerwerki,
## konfetti, kalendarz przewracający rok), ZANIM zbuduje resztę Huba —
## dokładnie ten sam wzorzec co YearlyReport.gd/WorldEvents.gd.
func _on_new_year(year: int) -> void:
	var money_bonus := randf_range(NEW_YEAR_MONEY_RANGE.x, NEW_YEAR_MONEY_RANGE.y)
	var result := Players.grant_new_year_to_random_player(money_bonus, NEW_YEAR_PAINTING_CHANCE)
	result["year"] = year
	Lottery.set_pending(result)
