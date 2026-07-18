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

var player_money: float = STARTING_MONEY
var dollar_rate: float = STARTING_DOLLAR_RATE
var inflation: float = STARTING_INFLATION


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
