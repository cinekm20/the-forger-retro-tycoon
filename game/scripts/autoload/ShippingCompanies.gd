extends Node
## 4 fikcyjne linie żeglugowe, notowane na giełdzie — ich kurs rośnie wraz
## z aktywnością gracza na plantacjach danego regionu.
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 7.

const COMPANIES := {
	"lloyd": {"name": "Lloyd", "region": "asia"},
	"star": {"name": "Star", "region": "africa"},
	"hanse": {"name": "Hanse", "region": "south_america"},
	"royal": {"name": "Royal", "region": "north_america"},
}

const STARTING_PRICE := 100.0  ## zgodnie z realiami startu gry (1918, Londyn)
const DAILY_DRIFT_RANGE := 0.03  ## losowe wahanie kursu ±3% dziennie

## Historia kursu do wykresu (StockMarket.gd, PriceChart.gd) — jeden punkt na
## każde wywołanie _on_day_advanced (czyli raz na "skok" kalendarza, nie co
## dzień co do jednego — Koniec tury/podróż/Szkoła sztuki skaczą po kilka-
## kilkanaście dni na raz), więc gęstość próbkowania naturalnie dopasowuje
## się do tempa rozgrywki. MAX_HISTORY_POINTS ogranicza pamięć/szerokość
## wykresu przy bardzo długiej grze — najstarsze punkty wypadają (FIFO).
const MAX_HISTORY_POINTS := 60

var stock_price: Dictionary = {}
var shares_owned: Dictionary = {}
var price_history: Dictionary = {}  ## company_id -> Array[float]


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)


func reset_new_game() -> void:
	stock_price.clear()
	shares_owned.clear()
	price_history.clear()
	for company_id in COMPANIES.keys():
		stock_price[company_id] = STARTING_PRICE
		shares_owned[company_id] = 0
		price_history[company_id] = [STARTING_PRICE]


func boost_from_region_activity(region: String, amount: float) -> void:
	for company_id in COMPANIES.keys():
		if COMPANIES[company_id]["region"] == region:
			stock_price[company_id] = get_price(company_id) + amount


func get_price(company_id: String) -> float:
	return stock_price.get(company_id, STARTING_PRICE)


func get_shares_owned(company_id: String) -> int:
	return shares_owned.get(company_id, 0)


func buy_shares(company_id: String, count: int) -> bool:
	if count <= 0:
		return false
	if not Economy.spend(get_price(company_id) * count):
		return false
	shares_owned[company_id] = get_shares_owned(company_id) + count
	return true


func sell_shares(company_id: String, count: int) -> bool:
	if count <= 0 or count > get_shares_owned(company_id):
		return false
	shares_owned[company_id] -= count
	Economy.earn(get_price(company_id) * count)
	return true


func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	var weeks: float = float(days_elapsed) / 7.0
	for company_id in COMPANIES.keys():
		var change_percent := randf_range(-DAILY_DRIFT_RANGE, DAILY_DRIFT_RANGE) * weeks
		stock_price[company_id] = max(1.0, get_price(company_id) * (1.0 + change_percent))
		_record_history(company_id)


func _record_history(company_id: String) -> void:
	var history: Array = price_history.get(company_id, [])
	history.append(stock_price[company_id])
	if history.size() > MAX_HISTORY_POINTS:
		history.pop_front()
	price_history[company_id] = history
