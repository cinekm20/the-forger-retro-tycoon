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

var player_count: int = 1
var active_index: int = 0
var player_names: Array[String] = []
var snapshots: Array[Dictionary] = []  ## stan graczy, którzy NIE są właśnie aktywni


func reset_new_game(count: int) -> void:
	player_count = clampi(count, 1, MAX_PLAYERS)
	active_index = 0
	player_names.clear()
	snapshots.clear()
	for i in player_count:
		player_names.append("Gracz %d" % (i + 1))
		snapshots.append(_empty_snapshot())


func is_multiplayer() -> bool:
	return player_count > 1


func active_name() -> String:
	return player_names[active_index] if active_index < player_names.size() else "Gracz"


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
## patrz nagłówek pliku), a w multiplayerze przełącza na kolejnego gracza.
func end_turn() -> void:
	Calendar.advance_days(DAYS_PER_TURN)
	if is_multiplayer():
		snapshots[active_index] = _capture_active()
		active_index = (active_index + 1) % player_count
		_apply_snapshot(snapshots[active_index])
	turn_changed.emit(active_index)


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
