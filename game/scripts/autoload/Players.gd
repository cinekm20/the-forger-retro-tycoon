extends Node
## Hot-seat multiplayer (1-4 graczy, docs/GDD.md pkt. 11, oryginał wspierał
## do 4 na jednym C64). Zamiast dublować Economy/PlayerPlantations/Paintings/
## Travel/ShippingCompanies/ForwardContracts per gracza, PRZEŁĄCZAMY, kto jest
## "aktywny" — te autoloady zawsze reprezentują aktualnie grającego, a stan
## pozostałych graczy leży w snapshots[] między ich turami. Dzięki temu żaden
## ekran (Plantation/StockMarket/AuctionHouse/ArtSchool/Races) nie musi wiedzieć
## o multiplayerze — zawsze operuje na "aktywnym graczu".
##
## Uproszczenie świadomie zaakceptowane: efekty zależne od upływu czasu (płace
## robotników, dług, terminy kontraktów) naliczają się tylko w momencie, gdy to
## czyjaś tura kończy się (Calendar.advance_days wywoływane w end_turn) — a nie
## "jednocześnie" dla wszystkich graczy w tle. To odpowiednik sekwencyjnych tur
## w wielu grach hot-seat, nie symulacja idealnie równoległego czasu.
## Prawdziwie globalne zjawiska (reforma walutowa, Noworoczna Loteria) i tak
## celowo trafiają we wszystkich graczy — patrz apply_reform_to_all i
## grant_new_year_to_random_player.

signal turn_changed(player_index: int)

const MAX_PLAYERS := 4
const DAYS_PER_TURN := 7

## Awatary graczy — ta sama pula grafik co GENERIC_RIVAL_POOL rywali AI
## (docs/GRAFIKA_LEONARDO.md §6: 6 portretów, 2 płcie × 3 dodatki,
## art/characters/<płeć>_<wariant>.jpg), więc wybór "płeć + avatar" na
## ekranie nowej gry nie wymaga generowania nowej grafiki — 6 gotowych
## wariantów starcza z zapasem na maks. 4 graczy (dopuszczalne powtórzenia,
## jeśli kilku graczy wybierze tę samą kombinację). Gdyby kiedyś zabrakło
## wariantów (więcej niż 3 dodatki na płeć), dopisać nowe prompty w
## docs/GRAFIKA_LEONARDO.md §6 obok istniejących.
const GENDERS := ["male", "female"]
const GENDER_NAMES := {"male": "Mężczyzna", "female": "Kobieta"}
const AVATAR_VARIANTS := ["tophat", "monocle", "boa"]
const AVATAR_VARIANT_NAMES := {"tophat": "Cylinder", "monocle": "Monokl", "boa": "Boa z piór"}

var player_count: int = 1
var active_index: int = 0
var player_names: Array[String] = []
var player_genders: Array[String] = []
var player_avatar_variants: Array[String] = []
var snapshots: Array[Dictionary] = []  ## stan graczy, którzy NIE są właśnie aktywni

## Niezależny licznik dni KAŻDEGO gracza (Tor B — patrz advance_active_player_time
## niżej). Płaska tablica jak player_names, celowo NIE migawkowana w
## snapshots[] — w odróżnieniu od pieniędzy/plantacji, nikt nigdy nie
## potrzebuje "aktualnej wartości" dnia gracza, który akurat nie jest
## aktywny, tylko wartości spod dowolnego indeksu (get_player_day), więc
## płaska tablica wystarcza.
var player_days: Array[int] = [0]


func reset_new_game(count: int) -> void:
	player_count = clampi(count, 1, MAX_PLAYERS)
	active_index = 0
	player_names.clear()
	player_genders.clear()
	player_avatar_variants.clear()
	snapshots.clear()
	player_days.clear()
	for i in player_count:
		player_names.append("Gracz %d" % (i + 1))
		player_genders.append(GENDERS[0])
		player_avatar_variants.append(AVATAR_VARIANTS[0])
		snapshots.append(_empty_snapshot())
		player_days.append(0)


func is_multiplayer() -> bool:
	return player_count > 1


func set_player_name(index: int, player_name: String) -> void:
	if index < 0 or index >= player_names.size():
		return
	var trimmed := player_name.strip_edges()
	if trimmed != "":
		player_names[index] = trimmed


func set_player_gender(index: int, gender: String) -> void:
	if index < 0 or index >= player_genders.size() or not GENDERS.has(gender):
		return
	player_genders[index] = gender


func set_player_avatar(index: int, variant: String) -> void:
	if index < 0 or index >= player_avatar_variants.size() or not AVATAR_VARIANTS.has(variant):
		return
	player_avatar_variants[index] = variant


## Ścieżka do awatara gracza (patrz komentarz przy GENDERS wyżej) —
## AIPlayers.get_portrait_path ma ten sam wzorzec ścieżki dla rywali.
func get_avatar_path(index: int) -> String:
	if index < 0 or index >= player_genders.size():
		return ""
	return "res://art/characters/%s_%s.jpg" % [player_genders[index], player_avatar_variants[index]]


func active_name() -> String:
	return player_names[active_index] if active_index < player_names.size() else "Gracz"


func active_avatar_path() -> String:
	return get_avatar_path(active_index)


## Własny, niezależny dzień aktywnego gracza (Tor B) — NIE to samo co
## Calendar.current_day (Tor A, wspólny dla wszystkich, patrz komentarz
## przy player_days wyżej i przy advance_active_player_time niżej).
func active_day() -> int:
	return player_days[active_index]


func get_player_day(index: int) -> int:
	return player_days[index]


func _empty_snapshot() -> Dictionary:
	return {
		"money": Economy.STARTING_MONEY,
		"days_in_debt": 0,
		"catalogued_numbers": [],
		"expertise": 0.0,
		"plantations": [],
		"shipping_shares": {},
		"forward_contracts": [],
		"current_city": Travel.START_CITY,
		"travel_route": [],
		"travel_days_remaining": 0.0,
		"has_bodyguard": false,
	}


func _capture_active() -> Dictionary:
	return {
		"money": Economy.player_money,
		"days_in_debt": Economy.days_in_debt,
		"catalogued_numbers": Paintings.catalogued_numbers.duplicate(),
		"expertise": Paintings.expertise,
		"plantations": PlayerPlantations.plantations.duplicate(true),
		"shipping_shares": ShippingCompanies.shares_owned.duplicate(),
		"forward_contracts": ForwardContracts.active_contracts.duplicate(true),
		"current_city": Travel.current_city,
		"travel_route": Travel.route.duplicate(),
		"travel_days_remaining": Travel.days_remaining,
		"has_bodyguard": Security.has_bodyguard,
	}


func _apply_snapshot(state: Dictionary) -> void:
	Economy.player_money = state["money"]
	Economy.days_in_debt = state["days_in_debt"]
	var numbers: Array[int] = []
	numbers.assign(state["catalogued_numbers"])
	Paintings.catalogued_numbers = numbers
	Paintings.expertise = state["expertise"]
	var plantations: Array[Dictionary] = []
	plantations.assign(state["plantations"])
	PlayerPlantations.plantations = plantations
	ShippingCompanies.shares_owned = state["shipping_shares"].duplicate()
	var contracts: Array[Dictionary] = []
	contracts.assign(state["forward_contracts"])
	ForwardContracts.active_contracts = contracts
	Travel.current_city = state["current_city"]
	var route: Array[String] = []
	route.assign(state["travel_route"])
	Travel.route = route
	Travel.days_remaining = state["travel_days_remaining"]
	Security.has_bodyguard = state.get("has_bodyguard", false)


## Kończy turę aktywnego gracza: dolicza tydzień (płace, kontrakty, dług —
## patrz nagłówek pliku), a w multiplayerze przekazuje ruch temu, kto ma
## teraz najwcześniejszą datę (patrz pass_turn_to_earliest_player niżej).
## Auctions.cap_turn_advance skraca ten skok, jeśli pełny tydzień przeleciałby
## od razu przez dzień aukcji w mieście, w którym gracz akurat stoi (patrz
## komentarz przy tej funkcji) — bez tego nigdy nie dało się trafić dokładnie
## na termin, żeby zdążyć wejść do Domu aukcyjnego.
func end_turn() -> void:
	var days := Auctions.cap_turn_advance(DAYS_PER_TURN, Travel.current_city)
	advance_active_player_time(days)
	pass_turn_to_earliest_player()


## Nalicza upływ dni TYLKO aktywnemu graczowi — czysta matematyka dni, BEZ
## przekazania ruchu (patrz pass_turn_to_earliest_player niżej, wywoływane
## osobno). Tor A (Calendar.current_day, wspólny dla wszystkich) rusza
## TYLKO o nowy teren ponad to, co już zasymulowane — dzięki temu ten sam
## dzień zawsze ma tę samą cenę na Giełdzie/Rynku, niezależnie kto do niego
## dotarł pierwszy. Tor B (Travel/Economy/PlayerPlantations/ForwardContracts/
## Security) dostaje ZAWSZE pełną liczbę dni — z perspektywy TEGO gracza te
## dni i tak minęły, nawet jeśli świat był już dalej (bez tego catching-up
## gracz nie płaciłby swoim robotnikom / nie kończyłby podróży).
func advance_active_player_time(days: int) -> void:
	if days <= 0:
		return
	var new_day := player_days[active_index] + days
	player_days[active_index] = new_day
	if new_day > Calendar.current_day:
		Calendar.advance_days(new_day - Calendar.current_day)
	Travel.apply_player_days_elapsed(days)
	Economy.apply_player_days_elapsed(days)
	PlayerPlantations.apply_player_days_elapsed(days)
	ForwardContracts.apply_player_days_elapsed(days)
	Security.apply_player_days_elapsed(days)


## Decyduje, KTO gra dalej — nie sztywny round-robin, tylko gracz z
## najwcześniejszą (najmniejszą) datą (patrz nagłówek pliku i GDD). Może to
## być ten sam gracz drugi raz z rzędu, jeśli nadal jest "najbardziej z
## tyłu" w czasie. Remis rozstrzyga najniższy indeks (deterministyczne,
## odtwarza zwykły round-robin, gdy wszystkie akcje trwają tyle samo).
## Publiczna i wywoływana OSOBNO od advance_active_player_time — Szkoła
## sztuki (ArtSchool.gd) musi rozegrać quiz PO naliczeniu dni, ale PRZED
## przekazaniem ruchu, żeby zdobyta eksperckość trafiła do właściwego,
## wciąż aktywnego gracza (Economy.player_money/Paintings.expertise są
## migawkowane per gracz).
func pass_turn_to_earliest_player() -> void:
	if not is_multiplayer():
		turn_changed.emit(active_index)
		return
	var earliest_index := 0
	for i in range(1, player_count):
		if player_days[i] < player_days[earliest_index]:
			earliest_index = i
	if earliest_index != active_index:
		snapshots[active_index] = _capture_active()
		active_index = earliest_index
		_apply_snapshot(snapshots[active_index])
	turn_changed.emit(active_index)


## Miasto DANEGO gracza (nie tylko aktywnego) — potrzebne do sprawdzenia, kto
## fizycznie jest w mieście aukcyjnym w danym momencie (AuctionHouse.gd,
## Auctions.get_present_players), skoro kilku graczy może dotrzeć do tej
## samej aukcji niezależnie (patrz GDD.md pkt. 11).
func get_player_city(index: int) -> String:
	if index == active_index:
		return Travel.current_city
	return snapshots[index].get("current_city", Travel.START_CITY)


func get_player_money(index: int) -> float:
	if index == active_index:
		return Economy.player_money
	return snapshots[index].get("money", Economy.STARTING_MONEY)


func player_can_afford(index: int, amount: float) -> bool:
	return get_player_money(index) >= amount


## Odejmuje kwotę z konta DANEGO gracza, jeśli go na to stać — zwraca false
## bez żadnego efektu, jeśli nie. Używane przez AuctionHouse.gd, gdzie
## licytować i wygrywać może każdy gracz fizycznie obecny na aukcji, nie
## tylko aktualnie aktywny.
func spend_player_money(index: int, amount: float) -> bool:
	if index == active_index:
		return Economy.spend(amount)
	if snapshots[index].get("money", 0.0) < amount:
		return false
	snapshots[index]["money"] -= amount
	return true


func get_player_expertise(index: int) -> float:
	if index == active_index:
		return Paintings.expertise
	return snapshots[index].get("expertise", 0.0)


## Czy DANY gracz (nie tylko aktywny) ma już ten numer skatalogowany —
## podstawa wykrywania fałszywki (Paintings.is_forgery_by_duplicate liczy to
## tylko dla aktywnego gracza, tu potrzebna wersja per gracz dla aukcji z
## wieloma jednoczesnymi licytującymi).
func player_has_number(index: int, number: int) -> bool:
	if index == active_index:
		return Paintings.catalogued_numbers.has(number)
	return snapshots[index].get("catalogued_numbers", []).has(number)


## Katalogowanie obrazu na konto DANEGO gracza — patrz spend_player_money,
## ten sam powód (aukcja z wieloma obecnymi graczami).
func catalogue_for_player(index: int, number: int) -> void:
	if index == active_index:
		Paintings.catalogue(number)
		return
	var numbers: Array = snapshots[index].get("catalogued_numbers", [])
	if not numbers.has(number):
		numbers.append(number)
		snapshots[index]["catalogued_numbers"] = numbers


func get_painting_count(index: int) -> int:
	if index == active_index:
		return Paintings.owned_count()
	return snapshots[index].get("catalogued_numbers", []).size()


func get_days_in_debt(index: int) -> int:
	if index == active_index:
		return Economy.days_in_debt
	return snapshots[index].get("days_in_debt", 0)


## Indeks pierwszego gracza, który skompletował Paintings.win_threshold
## obrazów, albo -1.
func get_winning_player() -> int:
	for i in player_count:
		if get_painting_count(i) >= Paintings.win_threshold:
			return i
	return -1


## Indeks pierwszego zbankrutowanego gracza, albo -1.
func get_bankrupt_player() -> int:
	for i in player_count:
		if get_days_in_debt(i) >= Economy.BANKRUPTCY_THRESHOLD_DAYS:
			return i
	return -1


## Reforma walutowa to zdarzenie globalne — dotyka gotówki wszystkich graczy,
## nie tylko aktywnego. Nie zmienia dollar_rate (to robi Economy.gd).
func apply_reform_to_all(ratio: float) -> void:
	Economy.player_money /= ratio
	for i in snapshots.size():
		if i != active_index:
			snapshots[i]["money"] = snapshots[i].get("money", 0.0) / ratio


## Noworoczna Loteria trafia w losowego gracza (nie zawsze akurat aktywnego).
func grant_new_year_to_random_player(money_amount: float, painting_chance: float) -> void:
	var index := randi() % player_count
	var already_catalogued: Array = (
		Paintings.catalogued_numbers if index == active_index
		else snapshots[index].get("catalogued_numbers", [])
	)
	var available_numbers: Array[int] = []
	for number in Paintings.CATALOG.keys():
		if not already_catalogued.has(number):
			available_numbers.append(number)
	var painting_number := -1
	if not available_numbers.is_empty() and randf() < painting_chance:
		painting_number = available_numbers[randi() % available_numbers.size()]

	if index == active_index:
		Economy.earn(money_amount)
		if painting_number >= 0:
			Paintings.catalogue(painting_number)
	else:
		snapshots[index]["money"] = snapshots[index].get("money", 0.0) + money_amount
		if painting_number >= 0:
			var nums: Array = snapshots[index].get("catalogued_numbers", [])
			nums.append(painting_number)
			snapshots[index]["catalogued_numbers"] = nums
