extends Node
## Zapis/odczyt stanu gry do pojedynczego pliku JSON w katalogu użytkownika.

const SAVE_PATH := "user://the_forger_save.json"


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
		"shipping_price_history": ShippingCompanies.price_history,
		"plantations": PlayerPlantations.plantations,
		"crop_prices": Crops.market_price,
		"crop_price_history": Crops.price_history,
		"forward_contracts": ForwardContracts.active_contracts,
		"rivals": AIPlayers.rivals,
		"current_city": Travel.current_city,
		"travel_route": Travel.route,
		"travel_days_remaining": Travel.days_remaining,
		"player_count": Players.player_count,
		"active_index": Players.active_index,
		"player_names": Players.player_names,
		"player_genders": Players.player_genders,
		"player_avatar_variants": Players.player_avatar_variants,
		"player_snapshots": Players.snapshots,
		"player_days": Players.player_days,
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
	## Domyślnie: jeden punkt na bieżącej cenie — dla zapisów sprzed dodania
	## wykresu (patrz ShippingCompanies.reset_new_game, ten sam wzorzec
	## seedowania historii).
	var default_shipping_history := {}
	for company_id in ShippingCompanies.COMPANIES.keys():
		default_shipping_history[company_id] = [ShippingCompanies.get_price(company_id)]
	ShippingCompanies.price_history = data.get("shipping_price_history", default_shipping_history)
	var loaded_plantations: Array = data.get("plantations", [])
	PlayerPlantations.plantations.assign(loaded_plantations)
	Crops.market_price = data.get("crop_prices", {})
	var default_crop_history := {}
	for crop in Crops.CROPS:
		default_crop_history[crop] = [Crops.get_price(crop)]
	Crops.price_history = data.get("crop_price_history", default_crop_history)
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
	## Domyślne płeć/awatar dla zapisów sprzed dodania tego wyboru —
	## jeden wpis na gracza, tak jak Players.reset_new_game().
	var default_genders: Array = []
	var default_avatar_variants: Array = []
	for i in Players.player_count:
		default_genders.append(Players.GENDERS[0])
		default_avatar_variants.append(Players.AVATAR_VARIANTS[0])
	var loaded_genders: Array = data.get("player_genders", default_genders)
	Players.player_genders.assign(loaded_genders)
	var loaded_avatar_variants: Array = data.get("player_avatar_variants", default_avatar_variants)
	Players.player_avatar_variants.assign(loaded_avatar_variants)
	var loaded_snapshots: Array = data.get("player_snapshots", [])
	Players.snapshots.assign(loaded_snapshots)
	## Zapisy sprzed dodania niezależnych linii czasu per gracz nie mają
	## "player_days" (albo mają tablicę złego rozmiaru, np. po zmianie
	## liczby graczy) — najlepsze dostępne przybliżenie to ówczesny
	## wspólny Calendar.current_day dla każdego gracza.
	var loaded_days: Array = data.get("player_days", [])
	if loaded_days.size() != Players.player_count:
		loaded_days.clear()
		for i in Players.player_count:
			loaded_days.append(Calendar.current_day)
	var player_days: Array[int] = []
	player_days.assign(loaded_days)
	Players.player_days = player_days
	Security.has_bodyguard = data.get("has_bodyguard", false)
	Auctions.next_auction_city = data.get("next_auction_city", "")
	Auctions.next_auction_day = data.get("next_auction_day", 0)
	Auctions.current_painting_number = data.get("current_painting_number", -1)
	if Auctions.next_auction_city == "":
		Auctions.reset_new_game()  # zapis sprzed dodania harmonogramu aukcji
