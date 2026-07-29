extends Node
## Dane upraw: plony referencyjne wg miasta, koszty transportu, sezonowość.
## Źródło liczb: docs/MECHANIKI_EKONOMICZNE.md pkt. 3, 7.1;
## sezonowość i mnożnik rzeki: docs/DODATKOWE_MECHANIKI.md.

## "contraband" (docs/DODATKOWE_MECHANIKI.md, tipy do sequela: "ukryte,
## nielegalne lokalne uprawy, w sequelu: konopie w Ankarze") — zgłoszenie
## użytkownika: bez nazywania konkretnej substancji, dostępna w Ankarze I
## Gwatemali (nie tylko jednym mieście jak w materiale źródłowym). Celowo w
## TEJ SAMEJ liście co zwykłe uprawy (nie osobnym systemie) — wszystkie
## generyczne mechanizmy (Warehouse.gd/Market.gd/StockMarket.gd/SaveGame.gd/
## YearlyReport.gd, `for crop in Crops.CROPS`) obsługują ją bez zmian.
## Jedyne miejsce z REALNYM ograniczeniem to Plantation.gd (dropdown "Sadzić"
## filtrowany przez is_crop_available) i REFERENCE_YIELD niżej (0 = brak
## wpisu poza Ankarą/Gwatemalą, więc nawet gdyby ktoś ją tam zasadził,
## calculate_harvest i tak nie da żadnego plonu).
const CONTRABAND_CROP := "contraband"
const CROPS := ["coffee", "tobacco", "tea", "cocoa", CONTRABAND_CROP]

const CROP_NAMES := {
	"coffee": "Kawa",
	"tobacco": "Tytoń",
	"tea": "Herbata",
	"cocoa": "Kakao",
	"contraband": "Przemycana uprawa",
}

## crop -> lista miast, w których WOLNO ją sadzić (patrz Plantation.gd). Brak
## wpisu = uprawa dostępna wszędzie (4 zwykłe uprawy) — tylko "contraband"
## ma tu wpis, więc to jedyna ograniczona uprawa w grze na razie.
const RESTRICTED_CROP_CITIES := {
	"contraband": ["ankara", "guatemala"],
}


func is_crop_available(crop: String, city_id: String) -> bool:
	if not RESTRICTED_CROP_CITIES.has(crop):
		return true
	return RESTRICTED_CROP_CITIES[crop].has(city_id)

## Plon referencyjny (total, przy 500 robotnikach / 30 dniach, pola przy rzece).
## Dane oryginału — świadomie NIE kopiujemy 1:1 przechyłu na rzecz tytoniu,
## patrz GDD.md pkt. 11 (balans do wyrównania przy strojeniu Economy).
const REFERENCE_YIELD := {
	## "contraband" TYLKO w ankara/guatemala (brak wpisu w pozostałych miastach
	## niżej = 0 = brak plonu, patrz PlayerPlantations.calculate_harvest) —
	## celowo skromny plon (rząd wielkości kawy w Ankarze, nie tytoniu) —
	## mały, wysoko wyceniony przemyt, nie masowa uprawa towarowa.
	"ankara": {"coffee": 16, "tobacco": 318, "tea": 206, "cocoa": 15, "contraband": 18},
	"bombay": {"coffee": 18, "tobacco": 362, "tea": 235, "cocoa": 17},
	"colombo": {"coffee": 17, "tobacco": 30, "tea": 215, "cocoa": 15},
	"mombasa": {"coffee": 207, "tobacco": 33, "tea": 242, "cocoa": 17},
	"duala": {"coffee": 208, "tobacco": 34, "tea": 22, "cocoa": 188},
	"abidjan": {"coffee": 240, "tobacco": 39, "tea": 26, "cocoa": 218},
	"rio": {"coffee": 220, "tobacco": 396, "tea": 24, "cocoa": 199},
	"bogota": {"coffee": 215, "tobacco": 35, "tea": 23, "cocoa": 195},
	"guatemala": {"coffee": 226, "tobacco": 37, "tea": 24, "cocoa": 19, "contraband": 20},
	"mexico": {"coffee": 206, "tobacco": 373, "tea": 22, "cocoa": 17},
	"richmond": {"coffee": 22, "tobacco": 428, "tea": 25, "cocoa": 20},
	"st_louis": {"coffee": 22, "tobacco": 433, "tea": 26, "cocoa": 20},
}

## Koszt transportu jednej jednostki towaru do magazynu (stały, bez inflacji).
const TRANSPORT_COST := {
	"london": {
		"st_louis": 23, "richmond": 21, "new_york": 18, "mexico": 30,
		"guatemala": 29, "bogota": 27, "rio": 26, "abidjan": 12, "duala": 14,
		"mombasa": 22, "colombo": 29, "bombay": 25, "ankara": 11,
	},
	"new_york": {
		"st_louis": 4, "richmond": 3, "mexico": 11, "guatemala": 10, "bogota": 9,
		"rio": 20, "abidjan": 22, "duala": 26, "mombasa": 34, "colombo": 40,
		"bombay": 37, "ankara": 23, "london": 18,
	},
}

## Sezonowa wydajność zbiorów wg miesiąca (1=styczeń ... 12=grudzień).
const SEASONAL_YIELD_FACTOR := {
	1: 0.4, 2: 0.7, 3: 1.0, 4: 1.0, 5: 0.8, 6: 0.6,
	7: 0.8, 8: 1.0, 9: 1.0, 10: 0.7, 11: 0.4, 12: 0.3,
}

## Pola przylegające do rzeki dają podwójny plon.
const RIVER_YIELD_MULTIPLIER := 2.0

## Ceny bazowe towarów na rynku (marek za jednostkę) — nasza własna wycena,
## świadomie wyrównana między uprawami (patrz GDD.md pkt. 11), nie kopiujemy
## przechyłu oryginału na rzecz tytoniu. Skalibrowana względem historycznej
## płacy robotnika (PlayerPlantations.WORKER_DAILY_WAGE = 1,0/dzień, ta
## liczba JEST z materiałów źródłowych — patrz docs/DODATKOWE_MECHANIKI.md),
## tak by w pełni obsadzona plantacja referencyjna (500 robotników, 50 pól)
## wychodziła na plus — patrz tools/balance_simulation.py.
## "contraband" 4x cenę zwykłej uprawy — mały plon (REFERENCE_YIELD wyżej),
## ale wysoka cena za jednostkę, tak jak realny przemyt: mało, ale drogo.
const BASE_CROP_PRICE := {"coffee": 50.0, "tobacco": 50.0, "tea": 50.0, "cocoa": 50.0, "contraband": 200.0}
const DAILY_DRIFT_RANGE := 0.02  ## losowe wahanie ceny ±2% dziennie

## Historia ceny do wykresu (StockMarket.gd, PriceChart.gd) — ten sam wzorzec
## co ShippingCompanies.gd (patrz komentarz tam): jeden punkt na każde
## wywołanie _on_day_advanced, MAX_HISTORY_POINTS ogranicza pamięć/szerokość
## wykresu przy bardzo długiej grze (najstarsze punkty wypadają, FIFO).
const MAX_HISTORY_POINTS := 60
## Zgłoszone przez użytkownika: cena na starcie nowej gry ma być losowa, a
## wykres ma już mieć jakąś historię zamiast płaskiego pojedynczego punktu —
## ten sam wzorzec symulowanej "przeszłości" co ShippingCompanies.gd.
const INITIAL_HISTORY_POINTS := 12

var market_price: Dictionary = {}
var price_history: Dictionary = {}  ## crop -> Array[float]


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)


func reset_new_game() -> void:
	market_price.clear()
	price_history.clear()
	for crop in CROPS:
		var history: Array = [BASE_CROP_PRICE[crop]]
		for i in INITIAL_HISTORY_POINTS - 1:
			history.append(max(1.0, history.back() * (1.0 + randf_range(-DAILY_DRIFT_RANGE, DAILY_DRIFT_RANGE))))
		price_history[crop] = history
		market_price[crop] = history.back()


func get_transport_cost(warehouse: String, from_city: String) -> int:
	return TRANSPORT_COST.get(warehouse, {}).get(from_city, -1)


func get_reference_yield(city_id: String, crop: String) -> int:
	return REFERENCE_YIELD.get(city_id, {}).get(crop, 0)


func get_price(crop: String) -> float:
	return market_price.get(crop, BASE_CROP_PRICE.get(crop, 9.0))


func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	var weeks: float = float(days_elapsed) / 7.0
	for crop in CROPS:
		var change_percent := randf_range(-DAILY_DRIFT_RANGE, DAILY_DRIFT_RANGE) * weeks
		market_price[crop] = max(1.0, get_price(crop) * (1.0 + change_percent))
		_record_history(crop)


func _record_history(crop: String) -> void:
	var history: Array = price_history.get(crop, [])
	history.append(market_price[crop])
	if history.size() > MAX_HISTORY_POINTS:
		history.pop_front()
	price_history[crop] = history
