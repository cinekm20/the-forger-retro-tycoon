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
		"shipping_prices": ShippingCompanies.stock_price,
		"shipping_shares": ShippingCompanies.shares_owned,
		"plantations": PlayerPlantations.plantations,
		"crop_prices": Crops.market_price,
		"forward_contracts": ForwardContracts.active_contracts,
		"rivals": AIPlayers.rivals,
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
	var loaded_numbers: Array = data.get("catalogued_numbers", [])
	Paintings.catalogued_numbers.assign(loaded_numbers)
	Paintings.expertise = data.get("expertise", 0.0)
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
