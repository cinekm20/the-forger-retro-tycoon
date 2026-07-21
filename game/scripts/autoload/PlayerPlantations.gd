extends Node
## Plantacje gracza: siatka pól z rzeką, uprawa, robotnicy, zbiory.
## Uproszczony model — patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 3–4.
## Dokładny wzór plonu z oryginału nie jest odtwarzalny 1:1 (zależał od
## wielu nieudokumentowanych czynników), więc formuła niżej jest świadomie
## uproszczonym, tunowalnym placeholderem do dalszego balansowania.

const GRID_SIZE := 6
const RIVER_COLUMN := 2  ## rzeka biegnie pionowo przez tę kolumnę (pola niedostępne pod uprawę)
const TILE_COST := 500.0
const WORKER_DAILY_WAGE := 1.0
const MAX_WORKERS := 500
const REFERENCE_TILE_COUNT := 50.0  ## odniesienie do tabeli plonów (ok. 50 ha przy rzece)

var plantations: Array[Dictionary] = []


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)


func reset_new_game() -> void:
	plantations.clear()


## Płaca robotników nalicza się cyklicznie za każdy dzień pracy (nie
## jednorazowo przy zatrudnieniu) — brak pieniędzy nie blokuje pracy, tylko
## pogłębia dług gracza (spójne z mechaniką bankructwa w Economy.gd).
func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	for plantation in plantations:
		var wage_cost: float = int(plantation["workers"]) * WORKER_DAILY_WAGE * days_elapsed
		if wage_cost > 0.0:
			Economy.player_money -= wage_cost


func found_plantation(city_id: String) -> int:
	var grid: Array[bool] = []
	grid.resize(GRID_SIZE * GRID_SIZE)
	grid.fill(false)
	plantations.append({
		"city": city_id,
		"grid": grid,
		"crop": "",
		"workers": 0,
		"stored_goods": 0,
		"last_harvest_day": Calendar.current_day,
	})
	return plantations.size() - 1


func is_river_tile(tile_index: int) -> bool:
	return tile_index % GRID_SIZE == RIVER_COLUMN


func is_adjacent_to_river(tile_index: int) -> bool:
	var x := tile_index % GRID_SIZE
	@warning_ignore("integer_division")  ## celowe: y to indeks wiersza w siatce
	var y := tile_index / GRID_SIZE
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if nx == RIVER_COLUMN and ny >= 0 and ny < GRID_SIZE:
				return true
	return false


func buy_tile(plantation_index: int, tile_index: int) -> bool:
	var plantation: Dictionary = plantations[plantation_index]
	if is_river_tile(tile_index) or plantation["grid"][tile_index]:
		return false
	if not Economy.spend(TILE_COST):
		return false
	plantation["grid"][tile_index] = true
	return true


## Zmiana uprawy czyści niesprzedany zapas — inaczej stary towar zostałby po
## cichu "przemianowany" na nową uprawę przy kolejnym get_total_stored/sell.
func set_crop(plantation_index: int, crop: String) -> void:
	var plantation: Dictionary = plantations[plantation_index]
	if plantation["crop"] != crop:
		plantation["stored_goods"] = 0
	plantation["crop"] = crop


## Zmienia liczbę robotników. Sam akt zatrudnienia nic nie kosztuje — koszt to
## bieżąca płaca naliczana codziennie (patrz _on_day_advanced).
func hire_workers(plantation_index: int, count: int) -> void:
	plantations[plantation_index]["workers"] = clampi(count, 0, MAX_WORKERS)


func get_owned_tile_count(plantation_index: int) -> int:
	var count := 0
	for owned in plantations[plantation_index]["grid"]:
		if owned:
			count += 1
	return count


func get_river_adjacent_owned_count(plantation_index: int) -> int:
	var plantation: Dictionary = plantations[plantation_index]
	var count := 0
	for i in plantation["grid"].size():
		if plantation["grid"][i] and is_adjacent_to_river(i):
			count += 1
	return count


const REFERENCE_PERIOD_DAYS := 30.0  ## REFERENCE_YIELD w Crops.gd to plon za 30 dni

## Plon skalowany rzeczywistym czasem od ostatnich zbiorów (patrz harvest())
## — reference w Crops.gd to plon za REFERENCE_PERIOD_DAYS, więc krótszy/dłuższy
## odstęp od ostatnich zbiorów daje proporcjonalnie mniej/więcej.
func calculate_harvest(plantation_index: int) -> int:
	var plantation: Dictionary = plantations[plantation_index]
	var crop: String = plantation["crop"]
	if crop == "":
		return 0
	var days_since_harvest: int = Calendar.current_day - int(plantation["last_harvest_day"])
	if days_since_harvest <= 0:
		return 0
	var reference: int = Crops.get_reference_yield(plantation["city"], crop)
	if reference == 0:
		return 0
	var worker_factor: float = float(plantation["workers"]) / 500.0
	var river_tiles := get_river_adjacent_owned_count(plantation_index)
	var normal_tiles := get_owned_tile_count(plantation_index) - river_tiles
	var effective_tiles := normal_tiles + river_tiles * Crops.RIVER_YIELD_MULTIPLIER
	var tile_factor: float = effective_tiles / REFERENCE_TILE_COUNT
	var seasonal_factor: float = Crops.SEASONAL_YIELD_FACTOR[Calendar.get_month()]
	var time_factor: float = days_since_harvest / REFERENCE_PERIOD_DAYS
	return int(reference * worker_factor * tile_factor * seasonal_factor * time_factor)


## Zbiera plon narosły od ostatnich zbiorów i resetuje licznik dni — kolejne
## wywołanie bez upływu czasu (Calendar.advance_days) zwróci 0.
func harvest(plantation_index: int) -> int:
	var amount := calculate_harvest(plantation_index)
	var plantation: Dictionary = plantations[plantation_index]
	plantation["stored_goods"] += amount
	plantation["last_harvest_day"] = Calendar.current_day
	return amount


## Wysyła zebrany towar do magazynu i sprzedaje go po aktualnej cenie rynkowej
## (Crops.get_price) — podbija też odpowiednią linię żeglugową
## (docs/MECHANIKI_EKONOMICZNE.md pkt. 7).
func ship_and_sell(plantation_index: int, warehouse: String) -> int:
	var plantation: Dictionary = plantations[plantation_index]
	var amount: int = plantation["stored_goods"]
	if amount <= 0:
		return 0
	var transport_cost := Crops.get_transport_cost(warehouse, plantation["city"])
	if transport_cost < 0:
		return 0
	Economy.player_money -= transport_cost * amount
	Economy.earn(amount * Crops.get_price(plantation["crop"]))
	plantation["stored_goods"] = 0

	var region: String = Cities.CITIES[plantation["city"]]["region"]
	ShippingCompanies.boost_from_region_activity(region, amount * 0.01)
	return amount


## Suma zebranego towaru danej uprawy w magazynach wszystkich plantacji gracza
## (uproszczenie: "magazyn" = suma stored_goods plantacji uprawiających dany
## towar — bez modelowania osobnych magazynów w Nowym Jorku/Londynie).
func get_total_stored(crop: String) -> int:
	var total := 0
	for plantation in plantations:
		if plantation["crop"] == crop:
			total += plantation["stored_goods"]
	return total


## Zużywa zebrany towar (np. na poczet kontraktu terminowego) z plantacji
## uprawiających dany towar, w kolejności iteracji.
func consume_stored(crop: String, amount: int) -> void:
	var remaining := amount
	for plantation in plantations:
		if remaining <= 0:
			break
		if plantation["crop"] != crop:
			continue
		var take: int = min(remaining, int(plantation["stored_goods"]))
		plantation["stored_goods"] -= take
		remaining -= take
