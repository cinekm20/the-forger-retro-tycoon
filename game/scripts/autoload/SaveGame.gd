extends Node
## Zapis/odczyt stanu gry do pojedynczego pliku JSON w katalogu użytkownika.

const SAVE_PATH := "user://vermeer_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"current_day": Calendar.current_day,
		"player_money": Economy.player_money,
		"dollar_rate": Economy.dollar_rate,
		"inflation": Economy.inflation,
		"catalogued_numbers": Paintings.catalogued_numbers,
		"expertise": Paintings.expertise,
		"win_threshold": Paintings.win_threshold,
		"days_in_debt": Economy.days_in_debt,
		"shipping_prices": ShippingCompanies.stock_price,
		"shipping_shares": ShippingCompanies.shares_owned,
		"plantations": PlayerPlantations.plantations,
		"crop_prices": Crops.market_price,
		"forward_contracts": ForwardContracts.active_contracts,
		"rivals": AIPlayers.rivals,
		"current_city": Travel.current_city,
		"travel_route": Travel.route,
		"travel_days_remaining": Travel.days_remaining,
		"player_count": Players.player_count,
		"active_index": Players.active_index,
		"player_names": Players.player_names,
		"player_snapshots": Players.snapshots,
		"has_bodyguard": Security.has_bodyguard,
		"next_auction_city": Auctions.next_auction_city,
		"next_auction_day": Auctions.next_auction_day,
		"current_painting_number": Auctions.current_painting_number,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func load_game() -> void:
	if not has_save():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null:
		return
	Calendar.current_day = data.get("current_day", 0)
	Economy.player_money = data.get("player_money", Economy.STARTING_MONEY)
	Economy.dollar_rate = data.get("dollar_rate", Economy.STARTING_DOLLAR_RATE)
	Economy.inflation = data.get("inflation", Economy.STARTING_INFLATION)
	Economy.days_in_debt = data.get("days_in_debt", 0)
	var loaded_numbers: Array = data.get("catalogued_numbers", [])
	Paintings.catalogued_numbers.assign(loaded_numbers)
	Paintings.expertise = data.get("expertise", 0.0)
	Paintings.win_threshold = data.get("win_threshold", Paintings.CATALOG.size())
	ShippingCompanies.stock_price = data.get("shipping_prices", {})
	ShippingCompanies.shares_owned = data.get("shipping_shares", {})
	var loaded_plantations: Array = data.get("plantations", [])
	PlayerPlantations.plantations.assign(loaded_plantations)
	Crops.market_price = data.get("crop_prices", {})
	var loaded_contracts: Array = data.get("forward_contracts", [])
	ForwardContracts.active_contracts.assign(loaded_contracts)
	var loaded_rivals: Array = data.get("rivals", [])
	if not loaded_rivals.is_empty():
		AIPlayers.rivals.assign(loaded_rivals)
	Travel.current_city = data.get("current_city", Travel.START_CITY)
	var loaded_route: Array = data.get("travel_route", [])
	Travel.route.assign(loaded_route)
	Travel.days_remaining = data.get("travel_days_remaining", 0.0)
	Players.player_count = data.get("player_count", 1)
	Players.active_index = data.get("active_index", 0)
	var loaded_names: Array = data.get("player_names", ["Gracz 1"])
	Players.player_names.assign(loaded_names)
	var loaded_snapshots: Array = data.get("player_snapshots", [])
	Players.snapshots.assign(loaded_snapshots)
	Security.has_bodyguard = data.get("has_bodyguard", false)
	Auctions.next_auction_city = data.get("next_auction_city", "")
	Auctions.next_auction_day = data.get("next_auction_day", 0)
	Auctions.current_painting_number = data.get("current_painting_number", -1)
	if Auctions.next_auction_city == "":
		Auctions.reset_new_game()  # zapis sprzed dodania harmonogramu aukcji
