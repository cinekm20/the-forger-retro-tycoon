extends Node
## Zapis/odczyt stanu gry do pojedynczego pliku JSON w katalogu użytkownika.

const SAVE_PATH := "user://the_forger_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"difficulty_level": Difficulty.level,
		"current_day": Calendar.current_day,
		"player_money": Economy.player_money,
		"dollar_rate": Economy.dollar_rate,
		"inflation": Economy.inflation,
		"catalogued_numbers": Paintings.catalogued_numbers,
		"bonus_awarded": Paintings.bonus_awarded,
		"expertise": Paintings.expertise,
		"win_threshold": Paintings.win_threshold,
		"days_in_debt": Economy.days_in_debt,
		"shipping_prices": ShippingCompanies.stock_price,
		"shipping_shares": ShippingCompanies.shares_owned,
		"shipping_price_history": ShippingCompanies.price_history,
		"horse_odds": Horses.current_odds,
		"gangster_chance": Gangsters.current_chance,
		"plantations": PlayerPlantations.plantations,
		"city_grids": PlayerPlantations.city_grids,
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
		"last_race_day": Players.last_race_day,
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
	## Zapisy sprzed dodania poziomów trudności nie mają "difficulty_level" —
	## spadają do NORMAL, tak samo jak domyślna wartość Difficulty.level
	## (zgłoszone przez użytkownika: "defaultowy to ma być poziom pośredni,
	## czyli normalny" — spójnie w całej grze, nie tylko przy zakładaniu
	## nowej gry w MainMenu.gd).
	Difficulty.level = data.get("difficulty_level", Difficulty.Level.NORMAL)
	Calendar.current_day = data.get("current_day", 0)
	Economy.player_money = data.get("player_money", Economy.STARTING_MONEY)
	Economy.dollar_rate = data.get("dollar_rate", Economy.STARTING_DOLLAR_RATE)
	Economy.inflation = data.get("inflation", Economy.STARTING_INFLATION)
	Economy.days_in_debt = data.get("days_in_debt", 0)
	var loaded_numbers: Array = data.get("catalogued_numbers", [])
	Paintings.catalogued_numbers.assign(loaded_numbers)
	var loaded_bonus_awarded: Array = data.get("bonus_awarded", [])  # zapisy sprzed bonusowych obrazów wuja: brak = żaden jeszcze nie rozdany
	Paintings.bonus_awarded.assign(loaded_bonus_awarded)
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
	## Zapisy sprzed dodania dryfującego kursu koni nie mają "horse_odds" —
	## brakujące/nierozpoznane konie (np. stary zapis z inną listą) spadają
	## do Horses.STARTING_ODDS per koń.
	var loaded_horse_odds: Dictionary = data.get("horse_odds", {})
	for horse_id in Horses.HORSES.keys():
		if not loaded_horse_odds.has(horse_id):
			loaded_horse_odds[horse_id] = Horses.STARTING_ODDS.get(horse_id, 1.0)
	Horses.current_odds = loaded_horse_odds
	## Zapisy sprzed dodania dryfującej szansy gangsterów — ten sam wzorzec co
	## horse_odds wyżej, brakujący/nierozpoznany gangster spada do
	## Gangsters.STARTING_CHANCE.
	var loaded_gangster_chance: Dictionary = data.get("gangster_chance", {})
	for gangster_id in Gangsters.GANGSTERS.keys():
		if not loaded_gangster_chance.has(gangster_id):
			loaded_gangster_chance[gangster_id] = Gangsters.STARTING_CHANCE.get(gangster_id, 0.3)
	Gangsters.current_chance = loaded_gangster_chance
	var loaded_plantations: Array = data.get("plantations", [])
	PlayerPlantations.plantations.assign(loaded_plantations)
	## Zapisy sprzed wspólnej siatki miast (city_grids) nie mają tego klucza —
	## zamiast zgadywać stary, per-gracz teren, generujemy świeży, w pełni
	## wolny teren dla wszystkich miast (ten sam efekt co nowa gra), skoro i
	## tak nie da się wiarygodnie odtworzyć, kto co wcześniej posiadał w
	## starym modelu. Jednorazowa, akceptowalna utrata przy migracji — ten
	## sam kompromis co gdzie indziej w tym pliku (np. next_auction_city).
	var loaded_city_grids: Dictionary = data.get("city_grids", {})
	if loaded_city_grids.is_empty():
		PlayerPlantations.generate_all_city_grids()
	else:
		PlayerPlantations.city_grids = loaded_city_grids
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
	## Zapisy sprzed dodania limitu wyścigów (albo po zmianie liczby graczy)
	## nie mają "last_race_day" — sentinel -DAYS_PER_TURN pozwala od razu
	## postawić zakład, tak samo jak na starcie nowej gry (patrz
	## Players.reset_new_game).
	var loaded_race_days: Array = data.get("last_race_day", [])
	if loaded_race_days.size() != Players.player_count:
		loaded_race_days.clear()
		for i in Players.player_count:
			loaded_race_days.append(-Players.DAYS_PER_TURN)
	var last_race_day: Array[int] = []
	last_race_day.assign(loaded_race_days)
	Players.last_race_day = last_race_day
	Security.has_bodyguard = data.get("has_bodyguard", false)
	Auctions.next_auction_city = data.get("next_auction_city", "")
	Auctions.next_auction_day = data.get("next_auction_day", 0)
	Auctions.current_painting_number = data.get("current_painting_number", Auctions.NO_PAINTING_SELECTED)
	if Auctions.next_auction_city == "":
		Auctions.reset_new_game()  # zapis sprzed dodania harmonogramu aukcji
