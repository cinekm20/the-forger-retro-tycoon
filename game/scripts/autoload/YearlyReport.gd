extends Node
## Podsumowanie roku — jak "MONATSBERICHT" na przełomie roku w oryginale
## (zrzut ekranu użytkownika: kursy 4 linii żeglugowych, ceny 4 towarów,
## inflacja, kurs dolara). Migawka gospodarki robiona w momencie, gdy
## Calendar zgłosi przejście do nowego roku (Calendar.new_year) —
## `pending` czeka tam do najbliższego wejścia do Huba, które pokazuje
## pełnoekranowy raport ZANIM zbuduje resztę UI Huba (patrz Hub.gd _ready).
## Osobny autoload zamiast dopisywania do Economy.gd — inflacja/kurs
## dolara to już własność Economy, ale kursy linii żeglugowych i ceny
## towarów należą do innych autoloadów, a to jest czysto UI-owa migawka
## na potrzeby jednego ekranu, nie dane gospodarki jako takiej.

var pending: Dictionary = {}


func _ready() -> void:
	Calendar.new_year.connect(_on_new_year)


func reset_new_game() -> void:
	pending = {}


func has_pending() -> bool:
	return not pending.is_empty()


## Wywoływać RAZ, tuż przed zbudowaniem ekranu podsumowania — czyści
## `pending`, żeby ten sam raport nie pokazał się drugi raz przy kolejnym
## wejściu do Huba.
func consume_pending() -> Dictionary:
	var data := pending
	pending = {}
	return data


func _on_new_year(year: int) -> void:
	var shipping: Dictionary = {}
	for company_id in ShippingCompanies.COMPANIES.keys():
		shipping[company_id] = ShippingCompanies.get_price(company_id)
	var crops: Dictionary = {}
	for crop in Crops.CROPS:
		crops[crop] = Crops.get_price(crop)
	pending = {
		"year": year - 1,  ## new_year niesie już NOWY rok — raport dotyczy poprzedniego, właśnie zakończonego
		"shipping": shipping,
		"crops": crops,
		"inflation": Economy.inflation,
		"dollar_rate": Economy.dollar_rate,
	}
