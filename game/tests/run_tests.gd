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
	_test_win_threshold_easy_mode()
	_test_forward_contract_penalty_on_failure()
	_test_players_hotseat_swap()
	_test_security_bodyguard_and_gangster()
	_test_travel_vehicle_choice()
	_test_travel_completes_in_one_animation()
	_test_auctions_schedule()

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
	# RIVER_COLUMN = 2, GRID_SIZE = 6 -> tile_index = y*6+x
	_assert(PlayerPlantations.is_river_tile(2), "pole (2,0) to sama rzeka")
	_assert(not PlayerPlantations.is_adjacent_to_river(2), "rzeka nie jest 'sąsiadem samej siebie' (nieistotne w grze — rzeka i tak nie do kupienia)")
	_assert(PlayerPlantations.is_adjacent_to_river(1), "pole (1,0), tuż obok rzeki -> sąsiaduje")
	_assert(PlayerPlantations.is_adjacent_to_river(3), "pole (3,0), po drugiej stronie rzeki -> też sąsiaduje")
	_assert(not PlayerPlantations.is_adjacent_to_river(5), "pole (5,0), daleko od rzeki -> nie sąsiaduje")


func _test_harvest_requires_elapsed_time() -> void:
	print("-- PlayerPlantations: zbiory wymagają upływu czasu (regresja na naprawiony exploit) --")
	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.set_crop(idx, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)
	Economy.reset_new_game()
	PlayerPlantations.buy_tile(idx, 0)

	Calendar.advance_days(30)
	var first_harvest := PlayerPlantations.harvest(idx)
	var second_harvest := PlayerPlantations.harvest(idx)  # bez upływu czasu od pierwszych zbiorów

	_assert(first_harvest > 0, "pierwsze zbiory po 30 dniach dają plon > 0")
	_assert(second_harvest == 0, "powtórne zbiory BEZ upływu czasu dają 0 (exploit z sesji naprawiony)")


func _test_harvest_scales_with_time() -> void:
	print("-- PlayerPlantations: plon skaluje się proporcjonalnie do czasu --")
	# Oba pomiary w tym samym miesiącu (dni 1-29 = styczeń, stały czynnik
	# sezonowy), żeby sezonowość nie zaburzała porównania.
	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.set_crop(idx, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)
	Economy.reset_new_game()
	PlayerPlantations.buy_tile(idx, 0)
	Calendar.advance_days(10)
	var harvest_10_days := PlayerPlantations.harvest(idx)

	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	idx = PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.set_crop(idx, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)
	Economy.reset_new_game()
	PlayerPlantations.buy_tile(idx, 0)
	Calendar.advance_days(20)
	var harvest_20_days := PlayerPlantations.harvest(idx)

	_assert(harvest_20_days > harvest_10_days, "20 dni upraw daje więcej plonu niż 10 dni (ten sam miesiąc)")
	_assert(absi(harvest_20_days - harvest_10_days * 2) <= 2, "plon skaluje się z grubsza liniowo z czasem (20d ≈ 2×10d)")


func _test_forgery_by_duplicate_number() -> void:
	print("-- Paintings: wykrywanie fałszywek po numerze katalogowym --")
	Paintings.reset_new_game()
	_assert(not Paintings.is_forgery_by_duplicate(6), "obraz nr 6 jeszcze nie posiadany -> nie jest 'duplikatem'")
	Paintings.catalogue(6)
	_assert(Paintings.owned_count() == 1, "po katalogowaniu: 1 obraz w kolekcji")
	_assert(Paintings.is_forgery_by_duplicate(6), "próba zdobycia drugiego obrazu nr 6 = wykryta fałszywka")
	_assert(Paintings.get_category(6) == "vermeer", "obraz nr 6 należy do kategorii 'vermeer' (docs/ZRODLA_C64_WIKI.md)")


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

	var other_city := Cities.get_auction_cities().filter(func(c): return c != Auctions.next_auction_city)[0]
	Calendar.advance_days(Auctions.next_auction_day - Calendar.current_day)
	_assert(not Auctions.is_open(other_city), "inne miasto aukcyjne pozostaje zamknięte, nawet gdy termin nadszedł")
	_assert(Auctions.is_open(Auctions.next_auction_city), "właściwe miasto otwiera aukcję dokładnie w zaplanowanym dniu")

	var scheduled_day := Auctions.next_auction_day
	Auctions.resolve_and_reschedule()
	_assert(Auctions.next_auction_day > scheduled_day, "po rozstrzygnięciu losowany jest nowy termin w przyszłości")
