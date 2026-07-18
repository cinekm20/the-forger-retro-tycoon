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

var player_money: float = STARTING_MONEY
var dollar_rate: float = STARTING_DOLLAR_RATE
var inflation: float = STARTING_INFLATION


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)
	Calendar.new_year.connect(_on_new_year)


func reset_new_game() -> void:
	player_money = STARTING_MONEY
	dollar_rate = STARTING_DOLLAR_RATE
	inflation = STARTING_INFLATION


func is_reform_imminent() -> bool:
	return dollar_rate >= REFORM_WARNING_DOLLAR_RATE


## Wywoływać gdy silnik decyzyjny gry uzna, że reforma powinna nastąpić
## (np. po przekroczeniu progu przez dłuższy czas). ratio np. 5.0 = reforma 5:1.
func apply_currency_reform(ratio: float) -> void:
	player_money /= ratio
	dollar_rate /= ratio
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


func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	var weeks: float = float(days_elapsed) / 7.0
	dollar_rate *= 1.0 + inflation * 0.01 * weeks
	inflation += randf_range(-0.002, 0.004) * weeks
	inflation = max(0.0, inflation)

	if is_reform_imminent() and randf() < REFORM_CHANCE_PER_WEEK * weeks:
		apply_currency_reform(REFORM_RATIO)


## Noworoczna Loteria (Neujahrstombola) — docs/GDD.md pkt. 4.8,
## docs/DODATKOWE_MECHANIKI.md.
func _on_new_year(_year: int) -> void:
	earn(randf_range(NEW_YEAR_MONEY_RANGE.x, NEW_YEAR_MONEY_RANGE.y))
	if randf() < NEW_YEAR_PAINTING_CHANCE:
		var available_numbers: Array[int] = []
		for number in Paintings.CATALOG.keys():
			if not Paintings.catalogued_numbers.has(number):
				available_numbers.append(number)
		if not available_numbers.is_empty():
			Paintings.catalogue(available_numbers[randi() % available_numbers.size()])
