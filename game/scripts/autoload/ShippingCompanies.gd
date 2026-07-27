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

## Krach/hossa — rzadki, losowy wstrząs uderzający jednakowo we WSZYSTKIE
## spółki naraz (nie per-region jak boost_from_region_activity), zgłoszony
## przez użytkownika jako uzupełnienie kart wydarzeń (docs/GDD.md pkt. 4.3,
## karty "Krach"/"Hossa" czekały gotowe od strony grafiki, bez mechaniki).
## Szansa CELOWO niska (rzadkie, ale zapamiętywalne wydarzenie w ciągu
## wieloletniej gry) i mutually exclusive w jednym tygodniu (krach sprawdzany
## pierwszy — realny krach i hossa nie zdarzają się jednocześnie).
const MARKET_CRASH_CHANCE_PER_WEEK := 0.02
const MARKET_BOOM_CHANCE_PER_WEEK := 0.02
const MARKET_SHOCK_RANGE := Vector2(0.25, 0.45)  ## krach/hossa zmienia WSZYSTKIE kursy o 25-45% naraz

## Historia kursu do wykresu (StockMarket.gd, PriceChart.gd) — jeden punkt na
## każde wywołanie _on_day_advanced (czyli raz na "skok" kalendarza, nie co
## dzień co do jednego — Koniec tury/podróż/Szkoła sztuki skaczą po kilka-
## kilkanaście dni na raz), więc gęstość próbkowania naturalnie dopasowuje
## się do tempa rozgrywki. MAX_HISTORY_POINTS ogranicza pamięć/szerokość
## wykresu przy bardzo długiej grze — najstarsze punkty wypadają (FIFO).
const MAX_HISTORY_POINTS := 60
## Zgłoszone przez użytkownika: cena na starcie nowej gry ma być losowa, a
## wykres ma już mieć jakąś historię zamiast płaskiego pojedynczego punktu.
## Symulujemy więc kilka "przeszłych" kroków tym samym wzorem co
## _on_day_advanced (losowy dryf o DAILY_DRIFT_RANGE) — ostatni wygenerowany
## punkt staje się aktualną (losową) ceną startową.
const INITIAL_HISTORY_POINTS := 12

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
		shares_owned[company_id] = 0
		var history: Array = [STARTING_PRICE]
		for i in INITIAL_HISTORY_POINTS - 1:
			history.append(max(1.0, history.back() * (1.0 + randf_range(-DAILY_DRIFT_RANGE, DAILY_DRIFT_RANGE))))
		price_history[company_id] = history
		stock_price[company_id] = history.back()


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
	_maybe_trigger_market_shock(weeks)
	for company_id in COMPANIES.keys():
		var change_percent := randf_range(-DAILY_DRIFT_RANGE, DAILY_DRIFT_RANGE) * weeks
		stock_price[company_id] = max(1.0, get_price(company_id) * (1.0 + change_percent))
		_record_history(company_id)


func _maybe_trigger_market_shock(weeks: float) -> void:
	if randf() < MARKET_CRASH_CHANCE_PER_WEEK * weeks:
		apply_market_shock("crash", -randf_range(MARKET_SHOCK_RANGE.x, MARKET_SHOCK_RANGE.y))
	elif randf() < MARKET_BOOM_CHANCE_PER_WEEK * weeks:
		apply_market_shock("boom", randf_range(MARKET_SHOCK_RANGE.x, MARKET_SHOCK_RANGE.y))


## Publiczna (jak Economy.apply_currency_reform) — wywoływana z losowego
## tygodniowego rzutu w _on_day_advanced, ale też wprost z testów, żeby nie
## polegać na RNG. Celowo NIE dopisuje własnego punktu do price_history —
## zaraz potem (albo, przy wywołaniu z testu, przy następnym prawdziwym
## skoku dni) i tak leci zwykły zapis w _on_day_advanced, więc wynik szoku
## po prostu wchodzi w NAJBLIŻSZY punkt historii, bez podwajania wpisów.
## change_ratio ujemny = krach (np. -0.3 = spadek cen o 30%), dodatni = hossa.
func apply_market_shock(kind: String, change_ratio: float) -> void:
	for company_id in COMPANIES.keys():
		stock_price[company_id] = max(1.0, get_price(company_id) * (1.0 + change_ratio))
	WorldEvents.report_market_shock(kind, change_ratio)


func _record_history(company_id: String) -> void:
	var history: Array = price_history.get(company_id, [])
	history.append(stock_price[company_id])
	if history.size() > MAX_HISTORY_POINTS:
		history.pop_front()
	price_history[company_id] = history
