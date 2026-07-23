extends Node
## Lekki zestaw testów uruchamiany bez edytora, prosto na tym samym kodzie
## co gra (nie na kopii formuł, jak tools/balance_simulation.py w Pythonie).
##
## `extends Node` + scena tests/run_tests.tscn, NIE `extends SceneTree` +
## `--script` — ten drugi wariant wyglądał prościej, ale Godot dokumentuje
## `--script` jako "uruchom skrypt bez potrzeby projektu": świadomie pomija
## pełny boot projektu (czyli też autoloady), więc każde użycie autoloadu
## (Cities, Calendar, ...) failowało z "Identifier not found" mimo że
## dokładnie ten sam kod działa normalnie w grze. Scena + pełny boot
## projektu = autoloady dostępne tak samo jak wszędzie indziej.
##
## Uruchomienie lokalnie (gdy będzie już Godot pod ręką):
##   godot --headless --path . res://tests/run_tests.tscn
##
## W CI odpalane automatycznie przez .github/workflows/godot-check.yml.
## Kod wyjścia 1, jeśli którykolwiek test nie przejdzie.

var failures: int = 0
var total: int = 0


func _ready() -> void:
	print("=== Vermeer — testy autoloadów ===")

	_test_cities_direct_travel()
	_test_cities_route_via_transfer()
	_test_river_adjacency_detection()
	_test_harvest_requires_elapsed_time()
	_test_harvest_scales_with_time()
	_test_forgery_by_duplicate_number()
	_test_forgery_texture_falls_back_when_missing()
	_test_ai_players_rival_names_randomized()
	_test_win_threshold_easy_mode()
	_test_forward_contract_penalty_on_failure()
	_test_players_hotseat_swap()
	_test_security_bodyguard_and_gangster()
	_test_travel_vehicle_choice()
	_test_travel_completes_in_one_animation()
	_test_auctions_schedule()
	_test_auctions_cap_turn_advance()
	_test_ship_and_sell_all_across_plantations()
	_test_find_plantation_index()
	_test_plantation_grows_multiple_crops_at_once()
	_test_plant_tile_requires_ownership()
	_test_yearly_report_populated_on_new_year()

	print("\n=== Wynik: %d/%d testów przeszło ===" % [total - failures, total])
	get_tree().quit(1 if failures > 0 else 0)


func _assert(condition: bool, description: String) -> void:
	total += 1
	if condition:
		print("  OK   %s" % description)
	else:
		failures += 1
		print("  FAIL %s" % description)


func _test_cities_direct_travel() -> void:
	print("-- Cities: bezpośrednie trasy (docs/MECHANIKI_EKONOMICZNE.md pkt. 2.1) --")
	_assert(is_equal_approx(Cities.get_travel_days("richmond", "st_louis"), 1.9), "Richmond -> St. Louis = 1,9 dnia")
	_assert(is_equal_approx(Cities.get_travel_days("st_louis", "richmond"), 1.9), "macierz symetryczna: St. Louis -> Richmond też 1,9 dnia")
	_assert(Cities.get_travel_days("richmond", "richmond") == 0.0, "to samo miasto = 0 dni")


func _test_cities_route_via_transfer() -> void:
	print("-- Cities: trasa z przesiadką (Dijkstra) --")
	# Berlin nie ma bezpośredniej trasy do St. Louis w danych źródłowych —
	# musi znaleźć trasę przez co najmniej jedno miasto pośrednie.
	_assert(Cities.get_travel_days("berlin", "st_louis") < 0.0, "brak bezpośredniej trasy Berlin -> St. Louis w danych źródłowych")
	var result := Cities.find_route("berlin", "st_louis")
	_assert(not result["path"].is_empty(), "mimo to find_route znajduje jakąś trasę")
	_assert(result["path"][0] == "berlin", "trasa zaczyna się w Berlinie")
	_assert(result["path"][-1] == "st_louis", "trasa kończy się w St. Louis")
	_assert(result["path"].size() > 2, "trasa wymaga przynajmniej jednej przesiadki")
	_assert(result["total_days"] > 0.0, "całkowity czas podróży dodatni")


func _test_river_adjacency_detection() -> void:
	print("-- PlayerPlantations: wykrywanie sąsiedztwa z rzeką --")
	PlayerPlantations.reset_new_game()
	var idx := PlayerPlantations.found_plantation("richmond")
	# Rzeka jest teraz losowa (patrz _generate_river) — dla deterministycznego
	# testu logiki sąsiedztwa nadpisujemy ją ręcznie: prosta kolumna x=2,
	# GRID_SIZE = 16 -> tile_index = y*16+x.
	var river: Array[bool] = []
	river.resize(PlayerPlantations.GRID_SIZE * PlayerPlantations.GRID_SIZE)
	river.fill(false)
	river[2] = true  # pole (2,0)
	PlayerPlantations.plantations[idx]["river"] = river

	_assert(PlayerPlantations.is_river_tile(idx, 2), "pole (2,0) to sama rzeka")
	_assert(not PlayerPlantations.is_adjacent_to_river(idx, 2), "rzeka nie jest 'sąsiadem samej siebie' (nieistotne w grze — rzeka i tak nie do kupienia)")
	_assert(PlayerPlantations.is_adjacent_to_river(idx, 1), "pole (1,0), tuż obok rzeki -> sąsiaduje")
	_assert(PlayerPlantations.is_adjacent_to_river(idx, 3), "pole (3,0), po drugiej stronie rzeki -> też sąsiaduje")
	_assert(not PlayerPlantations.is_adjacent_to_river(idx, 5), "pole (5,0), daleko od rzeki -> nie sąsiaduje")


func _test_harvest_requires_elapsed_time() -> void:
	print("-- PlayerPlantations: zbiory wymagają upływu czasu (regresja na naprawiony exploit) --")
	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	Economy.reset_new_game()
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.plantations[idx]["river"].fill(false)  # rzeka losowa - pole 0 musi być pewne do kupienia
	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.plant_tile(idx, 0, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)

	Calendar.advance_days(30)
	var first_harvest: int = PlayerPlantations.harvest(idx).get("tobacco", 0)
	var second_harvest: int = PlayerPlantations.harvest(idx).get("tobacco", 0)  # bez upływu czasu od pierwszych zbiorów

	_assert(first_harvest > 0, "pierwsze zbiory po 30 dniach dają plon > 0")
	_assert(second_harvest == 0, "powtórne zbiory BEZ upływu czasu dają 0 (exploit z sesji naprawiony)")


func _test_harvest_scales_with_time() -> void:
	print("-- PlayerPlantations: plon skaluje się proporcjonalnie do czasu --")
	# Oba pomiary w tym samym miesiącu (dni 1-29 = styczeń, stały czynnik
	# sezonowy), żeby sezonowość nie zaburzała porównania.
	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	Economy.reset_new_game()
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.plantations[idx]["river"].fill(false)  # rzeka losowa - pole 0 musi być pewne do kupienia
	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.plant_tile(idx, 0, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)
	Calendar.advance_days(10)
	var harvest_10_days: int = PlayerPlantations.harvest(idx).get("tobacco", 0)

	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	Economy.reset_new_game()
	idx = PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.plantations[idx]["river"].fill(false)  # rzeka losowa - pole 0 musi być pewne do kupienia
	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.plant_tile(idx, 0, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)
	Calendar.advance_days(20)
	var harvest_20_days: int = PlayerPlantations.harvest(idx).get("tobacco", 0)

	_assert(harvest_20_days > harvest_10_days, "20 dni upraw daje więcej plonu niż 10 dni (ten sam miesiąc)")
	_assert(absi(harvest_20_days - harvest_10_days * 2) <= 2, "plon skaluje się z grubsza liniowo z czasem (20d ≈ 2×10d)")


func _test_plantation_grows_multiple_crops_at_once() -> void:
	print("-- PlayerPlantations: jedna plantacja uprawia kilka różnych roślin naraz --")
	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	Economy.reset_new_game()
	## "rio" (nie "richmond") — richmond ma bazowy plon kawy tylko 22 (patrz
	## Crops.REFERENCE_YIELD), więc przy JEDNYM polu kawy calculate_harvest
	## liczy ~0,3 jednostki, co int() ucina do 0 i test fałszywie failuje
	## (nie błąd gry — richmond to po prostu miasto tytoniowe, nie kawowe).
	## Rio ma wysoki bazowy plon OBU upraw (kawa 220, tytoń 396), więc nawet
	## po 1 polu każdej z nich wynik zaokrągla się w górę od zera.
	var idx := PlayerPlantations.found_plantation("rio")
	PlayerPlantations.plantations[idx]["river"].fill(false)
	PlayerPlantations.hire_workers(idx, 500)

	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.buy_tile(idx, 1)
	PlayerPlantations.plant_tile(idx, 0, "tobacco")
	PlayerPlantations.plant_tile(idx, 1, "coffee")

	_assert(PlayerPlantations.get_planted_tile_count(idx, "tobacco") == 1, "1 pole obsiane tytoniem")
	_assert(PlayerPlantations.get_planted_tile_count(idx, "coffee") == 1, "1 pole obsiane kawą")
	_assert(PlayerPlantations.get_planted_tile_count(idx, "tea") == 0, "0 pól obsianych herbatą")

	Calendar.advance_days(30)
	var amounts := PlayerPlantations.harvest(idx)
	_assert(amounts.get("tobacco", 0) > 0, "zbiory obejmują tytoń")
	_assert(amounts.get("coffee", 0) > 0, "zbiory obejmują kawę JEDNOCZEŚNIE z tytoniem")


func _test_plant_tile_requires_ownership() -> void:
	print("-- PlayerPlantations: plant_tile wymaga wcześniejszego kupienia pola --")
	PlayerPlantations.reset_new_game()
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.plantations[idx]["river"].fill(false)
	_assert(not PlayerPlantations.plant_tile(idx, 0, "tobacco"), "nie da się zasadzić na polu, którego gracz jeszcze nie kupił")


func _test_ship_and_sell_all_across_plantations() -> void:
	print("-- PlayerPlantations: ship_and_sell_all sprzedaje ten sam towar z WSZYSTKICH plantacji --")
	PlayerPlantations.reset_new_game()
	Economy.reset_new_game()

	var idx_a := PlayerPlantations.found_plantation("richmond")
	var idx_b := PlayerPlantations.found_plantation("mombasa")
	PlayerPlantations.plantations[idx_a]["stored_goods"] = {"tobacco": 10}
	PlayerPlantations.plantations[idx_b]["stored_goods"] = {"tobacco": 15}

	var sold := PlayerPlantations.ship_and_sell_all("tobacco", "new_york")

	_assert(sold == 25, "sprzedano łącznie 10+15=25 jednostek z obu plantacji")
	_assert(int(PlayerPlantations.plantations[idx_a]["stored_goods"].get("tobacco", 0)) == 0, "magazyn plantacji A wyzerowany po sprzedaży")
	_assert(int(PlayerPlantations.plantations[idx_b]["stored_goods"].get("tobacco", 0)) == 0, "magazyn plantacji B wyzerowany po sprzedaży")


func _test_find_plantation_index() -> void:
	print("-- PlayerPlantations: find_plantation_index --")
	PlayerPlantations.reset_new_game()
	_assert(PlayerPlantations.find_plantation_index("richmond") == -1, "brak plantacji w mieście, gdzie gracz jej jeszcze nie założył")
	var idx := PlayerPlantations.found_plantation("richmond")
	_assert(PlayerPlantations.find_plantation_index("richmond") == idx, "po założeniu: find_plantation_index zwraca właściwy indeks")
	_assert(PlayerPlantations.find_plantation_index("mombasa") == -1, "inne miasto nadal bez plantacji")


func _test_forgery_by_duplicate_number() -> void:
	print("-- Paintings: wykrywanie fałszywek po numerze katalogowym --")
	Paintings.reset_new_game()
	_assert(not Paintings.is_forgery_by_duplicate(6), "obraz nr 6 jeszcze nie posiadany -> nie jest 'duplikatem'")
	Paintings.catalogue(6)
	_assert(Paintings.owned_count() == 1, "po katalogowaniu: 1 obraz w kolekcji")
	_assert(Paintings.is_forgery_by_duplicate(6), "próba zdobycia drugiego obrazu nr 6 = wykryta fałszywka")
	_assert(Paintings.get_category(6) == "vermeer", "obraz nr 6 należy do kategorii 'vermeer' (docs/ZRODLA_C64_WIKI.md)")


func _test_forgery_texture_falls_back_when_missing() -> void:
	print("-- Paintings: get_texture_path z is_fake=true --")
	## Obraz nr 7 ma dedykowany wariant podróbki (painting_07_fake.jpg),
	## obraz nr 1 (na razie) nie — is_fake=true musi po cichu spaść z
	## powrotem na zwykłą grafikę zamiast zwracać nieistniejącą ścieżkę.
	_assert(
		Paintings.get_texture_path(7, true) == "res://art/paintings/painting_07_fake.jpg",
		"obraz nr 7 z is_fake=true zwraca dedykowaną grafikę podróbki",
	)
	_assert(
		Paintings.get_texture_path(1, true) == Paintings.get_texture_path(1, false),
		"obraz nr 1 bez wariantu podróbki: is_fake=true spada z powrotem na zwykłą grafikę",
	)


func _test_ai_players_rival_names_randomized() -> void:
	print("-- AIPlayers: imiona/portrety generycznych rywali losowane, nie statyczne --")
	AIPlayers.reset_new_game()
	var rival_2 := AIPlayers.get_rival("rival_2")
	var rival_3 := AIPlayers.get_rival("rival_3")

	_assert(rival_2["name"] != "Rywal II", "rival_2 dostaje wylosowane imię, nie statyczny placeholder")
	_assert(rival_3["name"] != "Rywal III", "rival_3 dostaje wylosowane imię, nie statyczny placeholder")
	_assert(
		AIPlayers.GENERIC_RIVAL_POOL.has(rival_2["portrait"]) and AIPlayers.GENERIC_RIVAL_POOL.has(rival_3["portrait"]),
		"oba portrety pochodzą z puli generycznych rywali",
	)
	_assert(rival_2["portrait"] != rival_3["portrait"], "rival_2 i rival_3 dostają RÓŻNE portrety (bez powtórzeń)")

	var vico := AIPlayers.get_rival("vico")
	_assert(
		vico["portrait"].begins_with("vico_"),
		"Vico dostaje jeden z losowych wariantów portretu (vico_1/2/3)",
	)
	_assert(
		AIPlayers.get_portrait_path("vico") == "res://art/characters/%s.jpg" % vico["portrait"],
		"get_portrait_path liczy ścieżkę Vico z jego wylosowanego pola 'portrait'",
	)
	_assert(
		AIPlayers.get_portrait_path("rival_2") == "res://art/characters/%s.jpg" % rival_2["portrait"],
		"get_portrait_path liczy ścieżkę z pola 'portrait' danego rywala",
	)


func _test_win_threshold_easy_mode() -> void:
	print("-- Paintings: próg zwycięstwa (tryb łatwy vs normalny) --")
	Paintings.reset_new_game(true)
	_assert(Paintings.win_threshold == Paintings.EASY_WIN_THRESHOLD, "tryb łatwy: win_threshold == 15")
	Paintings.reset_new_game(false)
	_assert(Paintings.win_threshold == Paintings.CATALOG.size(), "tryb normalny: win_threshold == 40")


func _test_forward_contract_penalty_on_failure() -> void:
	print("-- ForwardContracts: kara za niedostarczony kontrakt --")
	Calendar.reset_new_game()
	Economy.reset_new_game()
	Crops.reset_new_game()
	PlayerPlantations.reset_new_game()
	ForwardContracts.reset_new_game()

	ForwardContracts.propose_contract("tobacco")
	_assert(ForwardContracts.active_contracts.size() == 1, "kontrakt utworzony")
	var money_before := Economy.player_money

	# Żadna plantacja nie dostarcza tytoniu -> po terminie kontrakt musi zawieść.
	Calendar.advance_days(ForwardContracts.DUE_IN_DAYS + 1)

	_assert(ForwardContracts.active_contracts.is_empty(), "kontrakt rozliczony i usunięty z listy aktywnych")
	_assert(Economy.player_money < money_before, "gotówka spadła o karę umowną za niedostarczenie")


func _test_players_hotseat_swap() -> void:
	print("-- Players: przełączanie graczy hot-seat --")
	Calendar.reset_new_game()
	Economy.reset_new_game()
	Crops.reset_new_game()
	Paintings.reset_new_game()
	PlayerPlantations.reset_new_game()
	ShippingCompanies.reset_new_game()
	ForwardContracts.reset_new_game()
	Travel.reset_new_game()
	Security.reset_new_game()
	Players.reset_new_game(2)

	Economy.player_money = 12345.0
	Paintings.catalogue(1)
	## Bez tego Security._on_day_advanced (podłączony pod Calendar.day_advanced,
	## czyli odpala się przy KAŻDYM end_turn() poniżej) miał ~5% szansy/tydzień
	## ukraść jedyny obraz gracza 1 — losowa, niezwiązana z tym testem
	## interakcja z mechaniką kradzieży (patrz Security.gd), która sprawiała,
	## że test sporadycznie failował. Ten test sprawdza migawki stanu, nie
	## kradzieże — ochroniarz eliminuje tę przypadkową zależność.
	Security.has_bodyguard = true

	Players.end_turn()  # gracz 1 -> gracz 2

	_assert(Players.active_index == 1, "po end_turn: aktywny indeks = 1 (gracz 2)")
	_assert(Economy.player_money == Economy.STARTING_MONEY, "gracz 2 widzi swój świeży stan, nie kasę gracza 1")
	_assert(Paintings.owned_count() == 0, "gracz 2 nie widzi obrazów gracza 1")

	Players.end_turn()  # gracz 2 -> gracz 1 (pełny obrót)

	_assert(Players.active_index == 0, "po drugim end_turn wracamy do gracza 1")
	_assert(Economy.player_money == 12345.0, "stan gracza 1 poprawnie przywrócony z migawki")
	_assert(Paintings.owned_count() == 1, "gracz 1 nadal ma swój obraz")


func _test_security_bodyguard_and_gangster() -> void:
	print("-- Security: ochroniarz i gangster (docs/DODATKOWE_MECHANIKI.md) --")
	Economy.reset_new_game()
	Security.reset_new_game()

	_assert(not Security.has_bodyguard, "na starcie brak ochroniarza")
	var cost_before := Economy.player_money
	_assert(Security.hire_bodyguard(), "zatrudnienie ochroniarza się udaje przy wystarczających środkach")
	_assert(Security.has_bodyguard, "po zatrudnieniu: has_bodyguard == true")
	_assert(Economy.player_money == cost_before - Security.BODYGUARD_COST, "gotówka spadła dokładnie o koszt ochroniarza")
	_assert(not Security.hire_bodyguard(), "nie da się zatrudnić drugiego ochroniarza")

	AIPlayers.reset_new_game()
	Paintings.reset_new_game()
	var rival_id: String = AIPlayers.rivals[0]["id"]
	AIPlayers.rivals[0]["paintings"] = [7]
	Economy.player_money = 100000.0

	var money_before_gangster := Economy.player_money
	Security.send_gangster(rival_id)
	_assert(Economy.player_money == money_before_gangster - Security.GANGSTER_COST, "opłata za gangstera pobrana niezależnie od wyniku")

	# Rywal bez obrazów -> próba musi się nie udać (nie ma czego ukraść).
	AIPlayers.rivals[0]["paintings"] = []
	Economy.player_money = 100000.0
	var stolen := Security.send_gangster(rival_id)
	_assert(not stolen, "gangster nie może ukraść obrazu, którego rywal nie posiada")


func _test_travel_vehicle_choice() -> void:
	print("-- Travel: wybór pociąg vs samolot wg regionu --")
	Travel.reset_new_game()

	# Richmond i St. Louis są w tym samym regionie (north_america) -> pociąg.
	Travel.current_city = "richmond"
	Travel.route.clear()
	Travel.start_travel("st_louis")
	_assert(Travel.last_travel_vehicle == Travel.Vehicle.TRAIN, "Richmond -> St. Louis (ten sam region) = pociąg")

	# Londyn (europe) i Nowy Jork (north_america) są w różnych regionach -> samolot.
	Travel.reset_new_game()
	Travel.current_city = "london"
	Travel.start_travel("new_york")
	_assert(Travel.last_travel_vehicle == Travel.Vehicle.PLANE, "Londyn -> Nowy Jork (inny region) = samolot")


## Regresja: TravelAnimation.gd dogrywa Calendar.advance_days() na całą
## trasę od razu po animacji (patrz komentarz w TravelAnimation.gd) —
## sprawdza, że to faktycznie kończy podróż, także przy trasie z
## przesiadką (gdzie Travel._on_day_advanced musi poprawnie rozliczyć
## "nadmiarowe" dni między etapami).
func _test_travel_completes_in_one_animation() -> void:
	print("-- Travel: cała podróż kończy się po jednym Calendar.advance_days --")
	Travel.reset_new_game()
	Calendar.reset_new_game()
	Travel.current_city = "richmond"
	Travel.route.clear()
	Travel.start_travel("st_louis")
	Calendar.advance_days(int(ceil(Travel.last_travel_total_days)))
	_assert(not Travel.is_traveling(), "Richmond -> St. Louis: podróż zakończona po jednym advance_days")
	_assert(Travel.current_city == "st_louis", "Travel.current_city zaktualizowany na miasto docelowe")

	# Trasa z przesiadką (Berlin -> St. Louis, patrz _test_cities_route_via_transfer).
	Travel.reset_new_game()
	Calendar.reset_new_game()
	Travel.current_city = "berlin"
	Travel.route.clear()
	Travel.start_travel("st_louis")
	Calendar.advance_days(int(ceil(Travel.last_travel_total_days)))
	_assert(not Travel.is_traveling(), "Berlin -> St. Louis (z przesiadką): podróż zakończona po jednym advance_days")
	_assert(Travel.current_city == "st_louis", "Travel.current_city zaktualizowany na miasto docelowe mimo przesiadki")


## Regresja: przed dodaniem Auctions.gd dom aukcyjny pozwalał kupować
## dowolną liczbę obrazów na żądanie (przycisk "Nowa aukcja" bez ograniczeń)
## — użytkownik zgłosił, że w oryginale aukcje odbywają się tylko w
## konkretnym mieście i dniu (patrz "NEXT AUCTION IS: ..." w oryginalnej
## grze). Sprawdza, że harmonogram faktycznie ogranicza dostępność.
func _test_auctions_schedule() -> void:
	print("-- Auctions: aukcja dostępna tylko we właściwym mieście i terminie --")
	Calendar.reset_new_game()
	Auctions.reset_new_game()

	_assert(Cities.get_auction_cities().has(Auctions.next_auction_city), "wylosowane miasto aukcji jest jednym z miast typu 'auction'")
	_assert(Auctions.next_auction_day > Calendar.current_day, "termin aukcji jest w przyszłości względem startu gry")
	_assert(not Auctions.is_open(Auctions.next_auction_city), "aukcja jeszcze nieotwarta przed nadejściem terminu")

	var other_city: String = Cities.get_auction_cities().filter(func(c): return c != Auctions.next_auction_city)[0]
	Calendar.advance_days(Auctions.next_auction_day - Calendar.current_day)
	_assert(not Auctions.is_open(other_city), "inne miasto aukcyjne pozostaje zamknięte, nawet gdy termin nadszedł")
	_assert(Auctions.is_open(Auctions.next_auction_city), "właściwe miasto otwiera aukcję dokładnie w zaplanowanym dniu")

	var scheduled_day := Auctions.next_auction_day
	Auctions.resolve_and_reschedule()
	_assert(Auctions.next_auction_day > scheduled_day, "po rozstrzygnięciu losowany jest nowy termin w przyszłości")


## Regresja: "Koniec tury" (Players.DAYS_PER_TURN = 7 dni) potrafił przelecieć
## od razu przez cały dzień aukcji, mimo że gracz stał akurat w mieście, gdzie
## miała się odbyć — nigdy nie dało się trafić dokładnie na termin, żeby
## zdążyć wejść do Domu aukcyjnego (zgłoszone przez użytkownika). Sprawdza,
## że cap_turn_advance skraca skok do dokładnie dnia aukcji w takiej sytuacji,
## a w pozostałych przypadkach zwraca żądaną liczbę dni bez zmian.
func _test_auctions_cap_turn_advance() -> void:
	print("-- Auctions: cap_turn_advance zatrzymuje koniec tury dokładnie na dniu aukcji --")
	Calendar.reset_new_game()
	Auctions.reset_new_game()

	var other_city: String = Cities.get_auction_cities().filter(func(c): return c != Auctions.next_auction_city)[0]
	_assert(
		Auctions.cap_turn_advance(7, other_city) == 7,
		"w innym mieście (nie tym z aukcją) skok dni zostaje bez zmian",
	)

	var days_to_auction := Auctions.next_auction_day - Calendar.current_day
	if days_to_auction < 7:
		_assert(
			Auctions.cap_turn_advance(7, Auctions.next_auction_city) == days_to_auction,
			"w mieście aukcji, gdy termin jest bliżej niż 7 dni, skok skraca się dokładnie do dnia aukcji",
		)
	else:
		_assert(
			Auctions.cap_turn_advance(7, Auctions.next_auction_city) == 7,
			"w mieście aukcji, gdy termin jest dalej niż 7 dni, skok zostaje bez zmian",
		)

	Calendar.advance_days(days_to_auction)
	_assert(
		Auctions.cap_turn_advance(7, Auctions.next_auction_city) == 7,
		"gdy termin już nadszedł (gracz jest na miejscu), skok dni nie jest już capowany",
	)


func _test_yearly_report_populated_on_new_year() -> void:
	print("-- YearlyReport: migawka gospodarki tworzona przy przejściu do nowego roku --")
	Calendar.reset_new_game()
	Economy.reset_new_game()
	ShippingCompanies.reset_new_game()
	Crops.reset_new_game()
	YearlyReport.reset_new_game()

	_assert(not YearlyReport.has_pending(), "brak podsumowania na starcie gry")

	var days_to_new_year := Calendar.DAYS_PER_MONTH * 12 - Calendar.current_day
	Calendar.advance_days(days_to_new_year)
	_assert(YearlyReport.has_pending(), "po przekroczeniu Sylwestra podsumowanie czeka na pokazanie")

	var report := YearlyReport.consume_pending()
	_assert(report["year"] == Calendar.START_YEAR, "podsumowanie dotyczy roku, który się właśnie skończył, nie nowego")
	_assert(report["shipping"].size() == ShippingCompanies.COMPANIES.size(), "migawka zawiera kursy wszystkich linii żeglugowych")
	_assert(report["crops"].size() == Crops.CROPS.size(), "migawka zawiera ceny wszystkich towarów")
	_assert(not YearlyReport.has_pending(), "consume_pending() czyści podsumowanie, żeby nie pokazało się drugi raz")
