extends Node
## Plantacje gracza: siatka pól z rzeką, uprawa, robotnicy, zbiory.
## Uproszczony model — patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 3–4.
## Dokładny wzór plonu z oryginału nie jest odtwarzalny 1:1 (zależał od
## wielu nieudokumentowanych czynników), więc formuła niżej jest świadomie
## uproszczonym, tunowalnym placeholderem do dalszego balansowania.

const GRID_SIZE := 16
const TILE_COST := 500.0
const WORKER_DAILY_WAGE := 1.0
const MAX_WORKERS := 500
const REFERENCE_TILE_COUNT := 50.0  ## odniesienie do tabeli plonów (ok. 50 ha przy rzece)

var plantations: Array[Dictionary] = []


func reset_new_game() -> void:
	plantations.clear()


## Tor B — osobiste dla aktywnego gracza: płaca robotników nalicza się
## cyklicznie za każdy dzień pracy (nie jednorazowo przy zatrudnieniu) — brak
## pieniędzy nie blokuje pracy, tylko pogłębia dług gracza (spójne z
## mechaniką bankructwa w Economy.gd). Wywoływane wprost przez
## Players.advance_active_player_time (NIE podłączone do Calendar.day_advanced
## — to osobisty koszt TEGO gracza, nie zjawisko globalne).
func apply_player_days_elapsed(days_elapsed: int) -> void:
	for plantation in plantations:
		var wage_cost: float = int(plantation["workers"]) * WORKER_DAILY_WAGE * days_elapsed
		if wage_cost > 0.0:
			Economy.player_money -= wage_cost


## Indeks plantacji gracza w danym mieście, albo -1, jeśli gracz nie ma tam
## (jeszcze) plantacji — patrz Hub.gd (podsumowanie po "Koniec tury") i
## Plantation.gd, obie potrzebują tego samego wyszukiwania po city_id.
func find_plantation_index(city_id: String) -> int:
	for i in plantations.size():
		if plantations[i]["city"] == city_id:
			return i
	return -1


func found_plantation(city_id: String) -> int:
	var grid: Array[bool] = []
	grid.resize(GRID_SIZE * GRID_SIZE)
	grid.fill(false)
	## tile_crops: uprawa PER POLE, nie jedna uprawa całej plantacji (zgłoszone
	## przez użytkownika: jedna plantacja ma jednocześnie uprawiać wszystkie
	## możliwe rośliny) — "" = pole kupione, ale jeszcze niezasiane.
	var tile_crops: Array[String] = []
	tile_crops.resize(GRID_SIZE * GRID_SIZE)
	tile_crops.fill("")
	plantations.append({
		"city": city_id,
		"grid": grid,
		"river": _generate_river(),
		"tile_crops": tile_crops,
		"workers": 0,
		"stored_goods": {},  ## uprawa -> ilość w magazynie (osobno per uprawa)
		"last_harvest_day": Players.active_day(),
	})
	return plantations.size() - 1


## Rzeka jako losowy, wijący się pas (a nie prosta kolumna, patrz zrzut
## ekranu oryginału) — "błądzenie losowe" po kolumnach: startuje w losowej
## kolumnie i w każdym kolejnym wierszu przesuwa się o -1/0/+1, przycięte do
## granic siatki, więc zawsze tworzy ciągłą, pionowo płynącą, ale krętą rzekę.
func _generate_river() -> Array[bool]:
	var river: Array[bool] = []
	river.resize(GRID_SIZE * GRID_SIZE)
	river.fill(false)
	var col := randi() % GRID_SIZE
	for row in GRID_SIZE:
		river[row * GRID_SIZE + col] = true
		col = clampi(col + (randi() % 3 - 1), 0, GRID_SIZE - 1)
	return river


func is_river_tile(plantation_index: int, tile_index: int) -> bool:
	return plantations[plantation_index]["river"][tile_index]


## Pole rzeki samo nie jest "sąsiadem rzeki" — bez tego wczesnego wyjścia
## dowolne pole rzeki wypadało jako sąsiadujące z inną, sąsiednią komórką
## tej samej rzeki, co nie ma sensu semantycznie. W realnej rozgrywce i tak
## nieistotne (rzeki nie da się kupić, więc funkcja nigdy nie dostaje
## indeksu pola rzeki jako owned tile), ale wynik dla dowolnego inputu
## powinien być poprawny.
func is_adjacent_to_river(plantation_index: int, tile_index: int) -> bool:
	if is_river_tile(plantation_index, tile_index):
		return false
	var river: Array = plantations[plantation_index]["river"]
	var x := tile_index % GRID_SIZE
	@warning_ignore("integer_division")  ## celowe: y to indeks wiersza w siatce
	var y := tile_index / GRID_SIZE
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE and river[ny * GRID_SIZE + nx]:
				return true
	return false


func buy_tile(plantation_index: int, tile_index: int) -> bool:
	var plantation: Dictionary = plantations[plantation_index]
	if is_river_tile(plantation_index, tile_index) or plantation["grid"][tile_index]:
		return false
	if not Economy.spend(TILE_COST):
		return false
	plantation["grid"][tile_index] = true
	return true


## Sadzi (albo zmienia) uprawę na WŁASNYM, niebędącym rzeką polu — każde pole
## plantacji może mieć inną uprawę, więc jedna plantacja może jednocześnie
## uprawiać wszystkie 4 rodzaje towaru naraz (zgłoszone przez użytkownika).
## Zwraca false, jeśli pole nie jest (jeszcze) własnością gracza.
func plant_tile(plantation_index: int, tile_index: int, crop: String) -> bool:
	var plantation: Dictionary = plantations[plantation_index]
	if not plantation["grid"][tile_index]:
		return false
	plantation["tile_crops"][tile_index] = crop
	return true


## Ile pól tej plantacji jest obsianych daną uprawą — patrz legenda w
## Plantation.gd (zgłoszone przez użytkownika).
func get_planted_tile_count(plantation_index: int, crop: String) -> int:
	var count := 0
	for tile_crop in plantations[plantation_index]["tile_crops"]:
		if tile_crop == crop:
			count += 1
	return count


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


const REFERENCE_PERIOD_DAYS := 30.0  ## REFERENCE_YIELD w Crops.gd to plon za 30 dni

## Plon skalowany rzeczywistym czasem od ostatnich zbiorów (patrz harvest())
## — reference w Crops.gd to plon za REFERENCE_PERIOD_DAYS, więc krótszy/dłuższy
## odstęp od ostatnich zbiorów daje proporcjonalnie mniej/więcej. Plantacja
## może uprawiać kilka różnych roślin naraz (patrz plant_tile), więc plon
## liczy się OSOBNO dla każdej uprawy obecnej na polach, sumując tylko jej
## własne pola (robotnicy/czas/sezon są wspólne dla całej plantacji, ale
## liczba i rodzaj pól — już nie). Zwraca słownik uprawa -> ilość (tylko
## uprawy z plonem > 0).
func calculate_harvest(plantation_index: int) -> Dictionary:
	var plantation: Dictionary = plantations[plantation_index]
	var days_since_harvest: int = Players.active_day() - int(plantation["last_harvest_day"])
	var result: Dictionary = {}
	if days_since_harvest <= 0:
		return result
	var worker_factor: float = float(plantation["workers"]) / 500.0
	var seasonal_factor: float = Crops.SEASONAL_YIELD_FACTOR[Calendar.get_month_for_day(Players.active_day())]
	var time_factor: float = days_since_harvest / REFERENCE_PERIOD_DAYS
	var tile_crops: Array = plantation["tile_crops"]
	for crop in Crops.CROPS:
		var normal_tiles := 0
		var river_tiles := 0
		for i in tile_crops.size():
			if tile_crops[i] != crop:
				continue
			if is_adjacent_to_river(plantation_index, i):
				river_tiles += 1
			else:
				normal_tiles += 1
		if normal_tiles == 0 and river_tiles == 0:
			continue
		var reference: int = Crops.get_reference_yield(plantation["city"], crop)
		if reference == 0:
			continue
		var effective_tiles: float = normal_tiles + river_tiles * Crops.RIVER_YIELD_MULTIPLIER
		var tile_factor: float = effective_tiles / REFERENCE_TILE_COUNT
		var amount := int(reference * worker_factor * tile_factor * seasonal_factor * time_factor)
		if amount > 0:
			result[crop] = amount
	return result


## Zbiera plon narosły od ostatnich zbiorów (osobno per uprawa, patrz
## calculate_harvest) i resetuje licznik dni — kolejne wywołanie bez upływu
## czasu (Calendar.advance_days) zwróci pusty słownik.
func harvest(plantation_index: int) -> Dictionary:
	var amounts := calculate_harvest(plantation_index)
	var plantation: Dictionary = plantations[plantation_index]
	var stored: Dictionary = plantation["stored_goods"]
	for crop in amounts:
		stored[crop] = int(stored.get(crop, 0)) + amounts[crop]
	plantation["last_harvest_day"] = Players.active_day()
	return amounts


## Sprzedaje zapas JEDNEJ uprawy z JEDNEJ plantacji po aktualnej cenie
## rynkowej (Crops.get_price) — podbija też odpowiednią linię żeglugową
## (docs/MECHANIKI_EKONOMICZNE.md pkt. 7). Współdzielone przez ship_and_sell
## (cała plantacja, wszystkie uprawy naraz) i ship_and_sell_all (jedna
## uprawa, wszystkie plantacje naraz — patrz Warehouse.gd).
func _ship_and_sell_crop(plantation_index: int, crop: String, warehouse: String) -> int:
	var plantation: Dictionary = plantations[plantation_index]
	var stored: Dictionary = plantation["stored_goods"]
	var amount: int = int(stored.get(crop, 0))
	if amount <= 0:
		return 0
	var transport_cost := Crops.get_transport_cost(warehouse, plantation["city"])
	if transport_cost < 0:
		return 0
	Economy.player_money -= transport_cost * amount
	Economy.earn(amount * Crops.get_price(crop))
	stored[crop] = 0

	var region: String = Cities.CITIES[plantation["city"]]["region"]
	ShippingCompanies.boost_from_region_activity(region, amount * 0.01)
	return amount


## Sprzedaje WSZYSTKIE zapasy JEDNEJ plantacji naraz (wszystkie uprawy,
## które akurat ma w magazynie) — przycisk "Wyślij i sprzedaj" w
## Plantation.gd.
func ship_and_sell(plantation_index: int, warehouse: String) -> int:
	var stored: Dictionary = plantations[plantation_index]["stored_goods"]
	var total := 0
	for crop in stored.keys().duplicate():
		total += _ship_and_sell_crop(plantation_index, crop, warehouse)
	return total


## Jak ship_and_sell, ale dla JEDNEJ uprawy ze WSZYSTKICH plantacji naraz
## (patrz Spichlerz/Warehouse.gd — pokazuje zsumowany zapas danej uprawy ze
## wszystkich plantacji, więc sprzedaż też musi obsłużyć wszystkie na raz,
## każdą z jej WŁASNYM kosztem transportu, bo ten zależy od miasta danej
## plantacji).
func ship_and_sell_all(crop: String, warehouse: String) -> int:
	var total := 0
	for i in plantations.size():
		total += _ship_and_sell_crop(i, crop, warehouse)
	return total


## Suma zebranego towaru danej uprawy w magazynach wszystkich plantacji gracza
## (uproszczenie: "magazyn" = suma stored_goods plantacji, które akurat mają
## zapas tej uprawy — bez modelowania osobnych magazynów w Nowym Jorku/Londynie).
func get_total_stored(crop: String) -> int:
	var total := 0
	for plantation in plantations:
		total += int(plantation["stored_goods"].get(crop, 0))
	return total


## Zużywa zebrany towar (np. na poczet kontraktu terminowego) z plantacji,
## które mają zapas danej uprawy, w kolejności iteracji.
func consume_stored(crop: String, amount: int) -> void:
	var remaining := amount
	for plantation in plantations:
		if remaining <= 0:
			break
		var stored: Dictionary = plantation["stored_goods"]
		var available: int = int(stored.get(crop, 0))
		if available <= 0:
			continue
		var take: int = min(remaining, available)
		stored[crop] = available - take
		remaining -= take
