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

const RaceTrackScript := preload("res://scripts/ui/RaceTrackView.gd")


func _ready() -> void:
	print("=== The Forger: Retro Tycoon — testy autoloadów ===")

	_test_cities_direct_travel()
	_test_cities_route_via_transfer()
	_test_river_adjacency_detection()
	_test_harvest_requires_elapsed_time()
	_test_harvest_scales_with_time()
	_test_forgery_by_duplicate_number()
	_test_forgery_texture_falls_back_when_missing()
	_test_paintings_numbers_with_fake_variant()
	_test_ai_players_rival_names_randomized()
	_test_win_threshold_easy_mode()
	_test_forward_contract_penalty_on_failure()
	_test_players_hotseat_swap()
	_test_players_turn_follows_earliest_date()
	_test_art_school_course_ends_turn_after_applying_effects()
	_test_security_bodyguard_and_gangster()
	_test_travel_vehicle_choice()
	_test_travel_completes_in_one_animation()
	_test_auctions_schedule()
	_test_auctions_cap_turn_advance()
	_test_auctions_present_players()
	_test_ship_and_sell_all_across_plantations()
	_test_find_plantation_index()
	_test_plantation_grows_multiple_crops_at_once()
	_test_plant_tile_requires_ownership()
	_test_plantation_crisis_from_unpaid_wages()
	_test_plantation_lost_after_repeated_crisis_hits()
	_test_plantation_tiles_are_exclusive_between_players()
	_test_world_events_reform_queued()
	_test_market_shock_crash_and_boom()
	_test_yearly_report_populated_on_new_year()
	_test_players_gender_and_avatar_selection()
	_test_price_history_for_charts()
	_test_players_days_diverge()
	_test_races_cooldown_between_bets()
	_test_horses_odds_drift_and_bounds()
	_test_horses_odds_shared_by_day()
	_test_race_track_winner_finishes_first()
	_test_shared_price_by_day()
	_test_catching_up_player_does_not_double_world_drift()
	_test_catching_up_player_gets_full_personal_consequences()
	_test_catching_up_player_completes_travel()
	_test_all_scene_scripts_parse_without_error()

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
	# Rzeka jest teraz losowa (patrz _generate_river) i wspólna dla całego
	# miasta (PlayerPlantations.city_grids, nie per gracz) — dla
	# deterministycznego testu logiki sąsiedztwa nadpisujemy ją ręcznie:
	# prosta kolumna x=2, GRID_SIZE = 16 -> tile_index = y*16+x.
	var river: Array[bool] = []
	river.resize(PlayerPlantations.GRID_SIZE * PlayerPlantations.GRID_SIZE)
	river.fill(false)
	river[2] = true  # pole (2,0)
	PlayerPlantations.city_grids["richmond"]["river"] = river

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
	Players.reset_new_game(1)
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.city_grids["richmond"]["river"].fill(false)  # rzeka losowa - pole 0 musi być pewne do kupienia
	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.plant_tile(idx, 0, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)

	Players.advance_active_player_time(30)
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
	Players.reset_new_game(1)
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.city_grids["richmond"]["river"].fill(false)  # rzeka losowa - pole 0 musi być pewne do kupienia
	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.plant_tile(idx, 0, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)
	Players.advance_active_player_time(10)
	var harvest_10_days: int = PlayerPlantations.harvest(idx).get("tobacco", 0)

	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	Economy.reset_new_game()
	Players.reset_new_game(1)
	idx = PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.city_grids["richmond"]["river"].fill(false)  # rzeka losowa - pole 0 musi być pewne do kupienia
	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.plant_tile(idx, 0, "tobacco")
	PlayerPlantations.hire_workers(idx, 500)
	Players.advance_active_player_time(20)
	var harvest_20_days: int = PlayerPlantations.harvest(idx).get("tobacco", 0)

	_assert(harvest_20_days > harvest_10_days, "20 dni upraw daje więcej plonu niż 10 dni (ten sam miesiąc)")
	_assert(absi(harvest_20_days - harvest_10_days * 2) <= 2, "plon skaluje się z grubsza liniowo z czasem (20d ≈ 2×10d)")


func _test_plantation_grows_multiple_crops_at_once() -> void:
	print("-- PlayerPlantations: jedna plantacja uprawia kilka różnych roślin naraz --")
	PlayerPlantations.reset_new_game()
	Calendar.reset_new_game()
	Economy.reset_new_game()
	Players.reset_new_game(1)
	## "rio" (nie "richmond") — richmond ma bazowy plon kawy tylko 22 (patrz
	## Crops.REFERENCE_YIELD), więc przy JEDNYM polu kawy calculate_harvest
	## liczy ~0,3 jednostki, co int() ucina do 0 i test fałszywie failuje
	## (nie błąd gry — richmond to po prostu miasto tytoniowe, nie kawowe).
	## Rio ma wysoki bazowy plon OBU upraw (kawa 220, tytoń 396), więc nawet
	## po 1 polu każdej z nich wynik zaokrągla się w górę od zera.
	var idx := PlayerPlantations.found_plantation("rio")
	PlayerPlantations.city_grids["rio"]["river"].fill(false)
	PlayerPlantations.hire_workers(idx, 500)

	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.buy_tile(idx, 1)
	PlayerPlantations.plant_tile(idx, 0, "tobacco")
	PlayerPlantations.plant_tile(idx, 1, "coffee")

	_assert(PlayerPlantations.get_planted_tile_count(idx, "tobacco") == 1, "1 pole obsiane tytoniem")
	_assert(PlayerPlantations.get_planted_tile_count(idx, "coffee") == 1, "1 pole obsiane kawą")
	_assert(PlayerPlantations.get_planted_tile_count(idx, "tea") == 0, "0 pól obsianych herbatą")

	Players.advance_active_player_time(30)
	var amounts := PlayerPlantations.harvest(idx)
	_assert(amounts.get("tobacco", 0) > 0, "zbiory obejmują tytoń")
	_assert(amounts.get("coffee", 0) > 0, "zbiory obejmują kawę JEDNOCZEŚNIE z tytoniem")


func _test_plant_tile_requires_ownership() -> void:
	print("-- PlayerPlantations: plant_tile wymaga wcześniejszego kupienia pola --")
	PlayerPlantations.reset_new_game()
	Players.reset_new_game(1)
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.city_grids["richmond"]["river"].fill(false)
	_assert(not PlayerPlantations.plant_tile(idx, 0, "tobacco"), "nie da się zasadzić na polu, którego gracz jeszcze nie kupił")


## "richmond" (region north_america) celowo — Cities.REGION_UNREST_CHANCE_PER_WEEK
## nie ma dla niego wpisu, więc zamieszki nigdy nie ingerują w ten test:
## sprawdzamy WYŁĄCZNIE strajk z zaległych wypłat, deterministycznie, bez
## żadnego randf() w grze (ten sam powód, dla którego _test_security_bodyguard_and_gangster
## nigdy nie wywołuje apply_player_days_elapsed — realne, losowe zdarzenia
## tygodniowe nie powinny wpływać na wynik testu).
func _test_plantation_crisis_from_unpaid_wages() -> void:
	print("-- PlayerPlantations: strajk (brak wypłat) zabiera zapasy i połowę robotników --")
	PlayerPlantations.reset_new_game()
	Economy.reset_new_game()
	WorldEvents.reset_new_game()
	Players.reset_new_game(1)
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.hire_workers(idx, 10)
	PlayerPlantations.plantations[idx]["stored_goods"]["tobacco"] = 50
	Economy.player_money = -1.0  # już na minusie — jedna dowolna płaca utrzyma dług

	PlayerPlantations.apply_player_days_elapsed(1)

	_assert(int(PlayerPlantations.plantations[idx]["stored_goods"].get("tobacco", 0)) == 0, "zapasy skonfiskowane po strajku")
	_assert(int(PlayerPlantations.plantations[idx]["workers"]) == 5, "połowa robotników uciekła (10 -> 5)")
	_assert(int(PlayerPlantations.plantations[idx]["crisis_hits"]) == 1, "licznik uderzeń kryzysu wzrósł do 1")
	_assert(WorldEvents.has_pending(), "zdarzenie trafiło do kolejki WorldEvents")
	var reported_event := WorldEvents.consume_next()
	_assert(reported_event.get("kind", "") == "crisis" and reported_event.get("cause", "") == "wages", "zdarzenie oznaczone jako kryzys z przyczyny 'wages'")
	_assert(not reported_event.get("plantation_lost", true), "pojedynczy strajk NIE zabiera jeszcze całej plantacji")


func _test_plantation_lost_after_repeated_crisis_hits() -> void:
	print("-- PlayerPlantations: powtarzające się strajki zabierają całą plantację i zwalniają jej pola --")
	PlayerPlantations.reset_new_game()
	Economy.reset_new_game()
	WorldEvents.reset_new_game()
	Players.reset_new_game(1)
	var idx := PlayerPlantations.found_plantation("richmond")
	PlayerPlantations.city_grids["richmond"]["river"].fill(false)
	PlayerPlantations.buy_tile(idx, 0)
	PlayerPlantations.hire_workers(idx, 10)

	for i in PlayerPlantations.CRISIS_HITS_TO_LOSE_PLANTATION:
		Economy.player_money = -1.0  # utrzymaj dług przed każdym kolejnym uderzeniem
		PlayerPlantations.apply_player_days_elapsed(1)

	_assert(PlayerPlantations.find_plantation_index("richmond") == -1, "po %d uderzeniach kryzysu plantacja znika z tablicy" % PlayerPlantations.CRISIS_HITS_TO_LOSE_PLANTATION)
	_assert(int(PlayerPlantations.city_grids["richmond"]["tile_owner"][0]) == -1, "utracone pole wraca do wspólnej puli (wolne dla kogokolwiek)")


## Zgłoszone przez użytkownika: "plantacje w danym mieście powinny być
## wygenerowane na początku gry i powinny być wspólne dla wszystkich
## graczy, czyli ten który zasieje w lepszym miejscu będzie miał lepsze
## plony" — sedno tego wymagania: pole zajęte przez JEDNEGO gracza musi
## być niedostępne dla RESZTY, dopóki go nie straci.
func _test_plantation_tiles_are_exclusive_between_players() -> void:
	print("-- PlayerPlantations: pola siatki miasta są na wyłączność między graczami --")
	PlayerPlantations.reset_new_game()
	Economy.reset_new_game()
	Players.reset_new_game(2)
	PlayerPlantations.city_grids["richmond"]["river"].fill(false)

	# Gracz 1 (aktywny domyślnie, active_index=0) zajmuje pole 0.
	var idx_p1 := PlayerPlantations.found_plantation("richmond")
	_assert(PlayerPlantations.buy_tile(idx_p1, 0), "gracz 1 kupuje pole 0")

	# Przesuń dzień gracza 1 do przodu, żeby pass_turn_to_earliest_player
	# faktycznie oddał ruch graczowi 2 (remis 0=0 zostawiłby aktywnym
	# gracza o niższym indeksie, czyli tego samego gracza 1).
	Players.player_days[0] = 10
	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 1, "gracz 2 jest teraz aktywny")

	var idx_p2 := PlayerPlantations.found_plantation("richmond")
	_assert(not PlayerPlantations.buy_tile(idx_p2, 0), "gracz 2 NIE MOŻE kupić pola 0 — już należy do gracza 1")
	_assert(PlayerPlantations.buy_tile(idx_p2, 1), "gracz 2 kupuje inne, wolne pole 1")
	_assert(PlayerPlantations.get_owned_tile_count(idx_p2) == 1, "gracz 2 widzi TYLKO swoje własne pole (1), nie pole gracza 1")

	# Wróć do gracza 1 (jego snapshot z buy_tile(idx_p1, 0) musi przetrwać
	# przełączenie tury nietknięty) i sprawdź, że wciąż widzi TYLKO swoje pole.
	Players.player_days[1] = 20
	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 0, "gracz 1 jest znów aktywny")
	_assert(PlayerPlantations.get_owned_tile_count(idx_p1) == 1, "gracz 1 nadal widzi TYLKO swoje pole (0), nie pole gracza 2")


func _test_world_events_reform_queued() -> void:
	print("-- WorldEvents: reforma walutowa trafia do kolejki karty gazety --")
	WorldEvents.reset_new_game()
	Economy.reset_new_game()

	Economy.apply_currency_reform(5.0)

	_assert(WorldEvents.has_pending(), "reforma trafia do kolejki")
	var reported_event := WorldEvents.consume_next()
	_assert(reported_event.get("kind", "") == "reform" and is_equal_approx(reported_event.get("ratio", 0.0), 5.0), "zdarzenie to reforma z ratio=5.0")
	_assert(not WorldEvents.has_pending(), "kolejka pusta po skonsumowaniu jedynego zdarzenia")


## Krach/hossa — patrz ShippingCompanies.apply_market_shock. Wołane wprost
## (jak Economy.apply_currency_reform w teście wyżej), NIE przez losowy rzut
## w _on_day_advanced — inaczej test byłby losowo zawodny (~2%/tydzień
## szansy nie da się wiarygodnie wymusić przez zwykłe advance_days).
func _test_market_shock_crash_and_boom() -> void:
	print("-- ShippingCompanies/WorldEvents: krach i hossa zmieniają WSZYSTKIE kursy naraz i trafiają do kolejki karty gazety --")
	WorldEvents.reset_new_game()
	ShippingCompanies.reset_new_game()

	var lloyd_before := ShippingCompanies.get_price("lloyd")
	var royal_before := ShippingCompanies.get_price("royal")
	ShippingCompanies.apply_market_shock("crash", -0.3)
	_assert(is_equal_approx(ShippingCompanies.get_price("lloyd"), lloyd_before * 0.7), "krach obniża kurs Lloyd o 30%")
	_assert(is_equal_approx(ShippingCompanies.get_price("royal"), royal_before * 0.7), "krach obniża RÓWNIEŻ kurs Royal o 30% — uderza we WSZYSTKIE spółki naraz")
	_assert(WorldEvents.has_pending(), "krach trafia do kolejki karty gazety")
	var crash_event := WorldEvents.consume_next()
	_assert(crash_event.get("kind", "") == "crash" and is_equal_approx(crash_event.get("change_ratio", 0.0), -0.3), "zdarzenie to krach z change_ratio=-0.3")

	var lloyd_before_boom := ShippingCompanies.get_price("lloyd")
	ShippingCompanies.apply_market_shock("boom", 0.4)
	_assert(is_equal_approx(ShippingCompanies.get_price("lloyd"), lloyd_before_boom * 1.4), "hossa podnosi kurs Lloyd o 40%")
	var boom_event := WorldEvents.consume_next()
	_assert(boom_event.get("kind", "") == "boom" and is_equal_approx(boom_event.get("change_ratio", 0.0), 0.4), "zdarzenie to hossa z change_ratio=0.4")


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


func _test_paintings_numbers_with_fake_variant() -> void:
	print("-- Paintings: get_numbers_with_fake_variant (mini-gra Szkoły sztuki) --")
	var numbers := Paintings.get_numbers_with_fake_variant()
	_assert(numbers.has(7), "obraz nr 7 (ma dedykowaną grafikę podróbki) jest na liście")
	_assert(not numbers.has(1), "obraz nr 1 (bez dedykowanej grafiki podróbki) NIE jest na liście")
	_assert(not numbers.is_empty(), "lista nie jest pusta — mini-gra ma z czego losować")


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
	Players.reset_new_game(1)

	ForwardContracts.propose_contract("tobacco")
	_assert(ForwardContracts.active_contracts.size() == 1, "kontrakt utworzony")
	var money_before := Economy.player_money

	# Żadna plantacja nie dostarcza tytoniu -> po terminie kontrakt musi zawieść.
	Players.advance_active_player_time(ForwardContracts.DUE_IN_DAYS + 1)

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


## Zgłoszone przez użytkownika: kolejność tur NIE jest sztywnym round-robin —
## po KAŻDEJ czynności (tu: podróż) silnik oddaje ruch temu, kto ma teraz
## najwcześniejszą datę (Players.pass_turn_to_earliest_player). W grze
## 2-osobowej: gracz aktywny zawsze zaczyna swoją akcję będąc na RÓWNI z
## resztą (bo dostał ruch właśnie dlatego, że miał najwcześniejszą datę), więc
## KAŻDA podróż z niezerową liczbą dni wysuwa go przed pozostałych i oddaje im
## ruch — nie ma już progu "dłużej niż tydzień". Ten sam gracz dostaje ruch
## z powrotem drugi raz z rzędu tylko wtedy, gdy nadal jest najbardziej "z
## tyłu" w czasie (patrz trzeci etap testu niżej). Symuluje dokładnie to, co
## robi TravelAnimation.gd::_on_finished (advance_active_player_time, potem
## bezwarunkowo pass_turn_to_earliest_player) — scen nie instancjonujemy w
## tym pakiecie testów, patrz konwencja innych testów w tym pliku.
func _test_players_turn_follows_earliest_date() -> void:
	print("-- Travel/Players: silnik oddaje ruch graczowi z najwcześniejszą datą --")
	Economy.reset_new_game()
	Security.reset_new_game()
	Security.has_bodyguard = true  # eliminuje losową kradzież w tle, tak jak w _test_players_hotseat_swap
	Players.reset_new_game(2)
	Travel.reset_new_game()
	Calendar.reset_new_game()

	Travel.current_city = "berlin"
	Travel.route.clear()
	Travel.start_travel("london")  # 3.0 dnia
	var short_days := int(ceil(Travel.last_travel_total_days))
	Players.advance_active_player_time(short_days)  # gracz 1: dzień 0 -> %d dni
	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 1, "gracz 1 po podróży (%d dni) wysuwa się przed gracza 2 (wciąż dzień 0) — ruch przechodzi na gracza 2" % short_days)

	Travel.current_city = "london"
	Travel.route.clear()
	Travel.start_travel("new_york")  # 13.9 dnia — znacznie dłuższa
	var long_days := int(ceil(Travel.last_travel_total_days))
	Players.advance_active_player_time(long_days)  # gracz 2: dzień 0 -> %d dni, znacznie więcej niż gracz 1
	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 0, "gracz 2 wyprzedza gracza 1 długą podróżą (%d dni) — ruch wraca do gracza 1 (znów najwcześniejsza data)" % long_days)

	# Gracz 1 (aktywny) wraca z podróży do Londynu (patrz przywrócona migawka
	# po pass_turn_to_earliest_player wyżej) — kolejna, krótsza podróż stąd.
	Travel.route.clear()
	Travel.start_travel("ankara")  # 7.8 dnia z Londynu
	var third_days := int(ceil(Travel.last_travel_total_days))
	Players.advance_active_player_time(third_days)
	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 0, "gracz 1 nadal jest najbardziej 'z tyłu' (dzień %d wciąż < gracz 2, dzień %d) — dostaje ruch DRUGI RAZ z rzędu, silnik NIE wraca do sztywnego round-robin" % [Players.get_player_day(0), Players.get_player_day(1)])


## Ten sam problem co podróż wyżej, ale subtelniejszy: Economy.player_money
## i Paintings.expertise są migawkowane PER GRACZ (Players._capture_active),
## więc przekazanie tury (Players.pass_turn_to_earliest_player) MUSI nastąpić
## DOPIERO PO zastosowaniu efektów kursu (opłata + zdobyta eksperckość z
## quizu) — inaczej trafiłyby do migawki złego gracza. Symuluje kolejność z
## ArtSchool.gd (_on_train_pressed -> quiz -> _end_course_turn), nie sam
## quiz UI (scen nie instancjonujemy w tym pakiecie testów).
func _test_art_school_course_ends_turn_after_applying_effects() -> void:
	print("-- ArtSchool: długi kurs oddaje ruch graczowi z najwcześniejszą datą, PO zastosowaniu efektów --")
	Calendar.reset_new_game()
	Economy.reset_new_game()
	Paintings.reset_new_game()
	Security.reset_new_game()
	Security.has_bodyguard = true
	Players.reset_new_game(2)

	var training_cost := 2000.0
	var training_days := 14
	var expertise_gain := 0.15  # symuluje trafną odpowiedź w quizie

	Economy.spend(training_cost)
	Players.advance_active_player_time(training_days)  # patrz ArtSchool.gd::_on_train_pressed
	Paintings.increase_expertise(expertise_gain)
	Players.pass_turn_to_earliest_player()  # patrz ArtSchool.gd::_end_course_turn, wywołane PO quizie

	_assert(Players.active_index == 1, "kurs dłuższy niż tydzień (%d dni) wysuwa gracza 1 do przodu, ruch przechodzi na gracza 2 (najwcześniejsza data)" % training_days)
	_assert(Economy.player_money == Economy.STARTING_MONEY, "gracz 2 widzi swój świeży stan, nie kasę pomniejszoną przez kurs gracza 1")
	_assert(is_equal_approx(Paintings.expertise, 0.0), "gracz 2 nie odziedziczył eksperckości zdobytej przez gracza 1")

	# Gracz 2 wyprzedza gracza 1 w czasie (dzień training_days+1 > training_days)
	# — dopiero to oddaje ruch z powrotem, sprawdzamy migawkę gracza 1. NIE
	# używamy Players.end_turn() tutaj: ono dolicza własny tydzień (i cap
	# Auctions.cap_turn_advance) PRZED sprawdzeniem najwcześniejszej daty, co
	# przy training_days=14 > DAYS_PER_TURN=7 nie wystarczyłoby, by wyprzedzić
	# gracza 1 — testowalibyśmy więc coś innego niż samą logikę
	# pass_turn_to_earliest_player.
	Players.advance_active_player_time(training_days + 1)
	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 0, "gracz 2 wyprzedził gracza 1 w czasie — ruch wraca do gracza 1 (znów najwcześniejsza data)")
	_assert(
		is_equal_approx(Economy.player_money, Economy.STARTING_MONEY - training_cost),
		"po powrocie: gotówka gracza 1 poprawnie pomniejszona o koszt kursu",
	)
	_assert(is_equal_approx(Paintings.expertise, expertise_gain), "po powrocie: eksperckość gracza 1 poprawnie zapisana z kursu")


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
	print("-- Travel: cała podróż kończy się po jednym advance_active_player_time --")
	Travel.reset_new_game()
	Calendar.reset_new_game()
	Players.reset_new_game(1)
	Travel.current_city = "richmond"
	Travel.route.clear()
	Travel.start_travel("st_louis")
	Players.advance_active_player_time(int(ceil(Travel.last_travel_total_days)))
	_assert(not Travel.is_traveling(), "Richmond -> St. Louis: podróż zakończona po jednym advance_active_player_time")
	_assert(Travel.current_city == "st_louis", "Travel.current_city zaktualizowany na miasto docelowe")

	# Trasa z przesiadką (Berlin -> St. Louis, patrz _test_cities_route_via_transfer).
	Travel.reset_new_game()
	Calendar.reset_new_game()
	Players.reset_new_game(1)
	Travel.current_city = "berlin"
	Travel.route.clear()
	Travel.start_travel("st_louis")
	Players.advance_active_player_time(int(ceil(Travel.last_travel_total_days)))
	_assert(not Travel.is_traveling(), "Berlin -> St. Louis (z przesiadką): podróż zakończona po jednym advance_active_player_time")
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
	Players.reset_new_game(1)

	_assert(Cities.get_auction_cities().has(Auctions.next_auction_city), "wylosowane miasto aukcji jest jednym z miast typu 'auction'")
	_assert(Auctions.next_auction_day > Players.active_day(), "termin aukcji jest w przyszłości względem startu gry")
	_assert(not Auctions.is_open(Auctions.next_auction_city), "aukcja jeszcze nieotwarta przed nadejściem terminu")

	var other_city: String = Cities.get_auction_cities().filter(func(c): return c != Auctions.next_auction_city)[0]
	Players.advance_active_player_time(Auctions.next_auction_day - Players.active_day())
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
	Players.reset_new_game(1)

	var other_city: String = Cities.get_auction_cities().filter(func(c): return c != Auctions.next_auction_city)[0]
	_assert(
		Auctions.cap_turn_advance(7, other_city) == 7,
		"w innym mieście (nie tym z aukcją) skok dni zostaje bez zmian",
	)

	var days_to_auction := Auctions.next_auction_day - Players.active_day()
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

	Players.advance_active_player_time(days_to_auction)
	_assert(
		Auctions.cap_turn_advance(7, Auctions.next_auction_city) == 7,
		"gdy termin już nadszedł (gracz jest na miejscu), skok dni nie jest już capowany",
	)


## Zgłoszone przez użytkownika: aukcja ma pokazywać osobną ramkę dla KAŻDEGO
## gracza fizycznie obecnego w mieście na termin, nie dla wszystkich
## skonfigurowanych graczy. get_present_players() musi wymagać OBU warunków
## naraz (właściwe miasto ORAZ własny dzień >= termin) dla KAŻDEGO gracza
## osobno — snapshots[i]["current_city"] ustawiane ręcznie tu, tak jak inne
## testy poking snapshot state bezpośrednio (patrz np. _test_river_adjacency_detection).
func _test_auctions_present_players() -> void:
	print("-- Auctions: get_present_players zwraca tylko graczy fizycznie obecnych na aukcji --")
	Calendar.reset_new_game()
	Players.reset_new_game(3)
	Auctions.reset_new_game()
	Travel.reset_new_game()

	# Gracz 1 (aktywny): właściwe miasto i termin już nadszedł.
	Travel.current_city = Auctions.next_auction_city
	Players.player_days[0] = Auctions.next_auction_day

	# Gracz 2: to samo miasto, ale jeszcze nie dotarł do właściwego dnia.
	Players.snapshots[1]["current_city"] = Auctions.next_auction_city
	Players.player_days[1] = Auctions.next_auction_day - 1

	# Gracz 3: właściwy dzień, ale stoi w INNYM mieście.
	var other_city: String = Cities.get_auction_cities().filter(func(c): return c != Auctions.next_auction_city)[0]
	Players.snapshots[2]["current_city"] = other_city
	Players.player_days[2] = Auctions.next_auction_day

	var present := Auctions.get_present_players()
	_assert(present.has(0), "gracz 1 (właściwe miasto i dzień) jest obecny")
	_assert(not present.has(1), "gracz 2 (właściwe miasto, ZA WCZEŚNIE) NIE jest obecny")
	_assert(not present.has(2), "gracz 3 (właściwy dzień, INNE miasto) NIE jest obecny")
	_assert(present.size() == 1, "tylko jeden gracz spełnia oba warunki naraz")


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


func _test_players_gender_and_avatar_selection() -> void:
	print("-- Players: wybór płci i awatara --")
	Players.reset_new_game(2)

	_assert(Players.player_genders[0] == Players.GENDERS[0], "domyślna płeć gracza 1 to pierwsza z GENDERS")
	_assert(Players.player_avatar_variants[0] == Players.AVATAR_VARIANTS[0], "domyślny wariant awatara gracza 1 to pierwszy z AVATAR_VARIANTS")

	Players.set_player_gender(1, "female")
	Players.set_player_avatar(1, "boa")
	_assert(Players.player_genders[1] == "female", "płeć gracza 2 ustawiona na 'female'")
	_assert(Players.player_avatar_variants[1] == "boa", "wariant awatara gracza 2 ustawiony na 'boa'")
	_assert(Players.get_avatar_path(1) == "res://art/characters/female_boa.jpg", "ścieżka awatara łączy płeć i wariant")

	Players.set_player_gender(1, "nieznana_plec")
	Players.set_player_avatar(1, "nieznany_wariant")
	_assert(Players.player_genders[1] == "female", "nieprawidłowa płeć nie nadpisuje poprzedniego wyboru")
	_assert(Players.player_avatar_variants[1] == "boa", "nieprawidłowy wariant nie nadpisuje poprzedniego wyboru")


func _test_price_history_for_charts() -> void:
	print("-- ShippingCompanies/Crops: historia cen do wykresu na Giełdzie --")
	Calendar.reset_new_game()
	ShippingCompanies.reset_new_game()
	Crops.reset_new_game()

	## Zgłoszone przez użytkownika: na starcie nowej gry wykres ma już mieć
	## losową "przeszłość" (nie płaski pojedynczy punkt) — reset_new_game
	## dogenerowuje INITIAL_HISTORY_POINTS punktów, pierwszy zawsze = cena
	## bazowa, ostatni = aktualna (losowa) cena startowa.
	_assert(
		ShippingCompanies.price_history["lloyd"].size() == ShippingCompanies.INITIAL_HISTORY_POINTS,
		"historia kursu Lloyd zaczyna się z INITIAL_HISTORY_POINTS punktami",
	)
	_assert(ShippingCompanies.price_history["lloyd"][0] == ShippingCompanies.STARTING_PRICE, "pierwszy punkt to STARTING_PRICE")
	_assert(ShippingCompanies.price_history["lloyd"][-1] == ShippingCompanies.get_price("lloyd"), "ostatni punkt historii = aktualna (losowa) cena startowa")
	_assert(
		Crops.price_history["coffee"].size() == Crops.INITIAL_HISTORY_POINTS,
		"historia ceny kawy zaczyna się z INITIAL_HISTORY_POINTS punktami",
	)

	## Calendar.advance_days (nie wywoływanie _on_day_advanced bezpośrednio) —
	## tak samo jak reszta gry, przez sygnał Calendar.day_advanced, pod który
	## podpięte są ShippingCompanies i Crops.
	var lloyd_size_before: int = ShippingCompanies.price_history["lloyd"].size()
	var coffee_size_before: int = Crops.price_history["coffee"].size()
	Calendar.advance_days(7)
	_assert(ShippingCompanies.price_history["lloyd"].size() == lloyd_size_before + 1, "kolejny skok dni dopisuje kolejny punkt historii (Lloyd)")
	_assert(Crops.price_history["coffee"].size() == coffee_size_before + 1, "kolejny skok dni dopisuje kolejny punkt historii (kawa)")
	_assert(ShippingCompanies.price_history["lloyd"][-1] == ShippingCompanies.get_price("lloyd"), "ostatni punkt historii = aktualna cena")

	## MAX_HISTORY_POINTS ogranicza długość historii (najstarsze punkty
	## wypadają, FIFO) — bez tego pamięć/szerokość wykresu rosłaby bez końca
	## w bardzo długiej grze.
	for i in ShippingCompanies.MAX_HISTORY_POINTS + 10:
		Calendar.advance_days(7)
	_assert(
		ShippingCompanies.price_history["lloyd"].size() == ShippingCompanies.MAX_HISTORY_POINTS,
		"historia kursu nie rośnie w nieskończoność, zatrzymuje się na MAX_HISTORY_POINTS",
	)


## Niezależne linie czasu per gracz (hot-seat) — patrz nagłówek Players.gd.
## Testy niżej pokrywają nowy podział Tor A ("świat", Calendar.current_day,
## wspólny) / Tor B (Players.player_days, osobisty dla każdego gracza).
func _test_players_days_diverge() -> void:
	print("-- Players: gracze mają niezależne linie czasu --")
	Calendar.reset_new_game()
	Players.reset_new_game(2)
	Players.advance_active_player_time(10)
	_assert(Players.get_player_day(0) == 10, "gracz 1 (aktywny) ma dzień 10 po własnej akcji")
	_assert(Players.get_player_day(1) == 0, "gracz 2 pozostaje na dniu 0 (nie wykonał żadnej akcji)")
	_assert(Players.get_player_day(0) != Players.get_player_day(1), "linie czasu graczy się rozjeżdżają")


## Zgłoszone przez użytkownika: wyścigi konne (Races.gd) nie mogą być dostępne
## bez ograniczeń w obrębie jednej tury — limit Players.DAYS_PER_TURN między
## zakładami, liczony WŁASNYM czasem aktywnego gracza (Tor B).
func _test_races_cooldown_between_bets() -> void:
	print("-- Players: limit między zakładami na wyścigach (DAYS_PER_TURN) --")
	Calendar.reset_new_game()
	Players.reset_new_game(1)

	_assert(Players.days_since_last_race() >= Players.DAYS_PER_TURN, "na starcie nowej gry pierwszy zakład jest od razu możliwy")
	Players.record_race()
	_assert(Players.days_since_last_race() == 0, "zaraz po zakładzie licznik wraca do zera")

	Players.advance_active_player_time(3)
	_assert(Players.days_since_last_race() == 3 and Players.days_since_last_race() < Players.DAYS_PER_TURN, "po 3 dniach limit jeszcze nie minął")

	Players.advance_active_player_time(Players.DAYS_PER_TURN - 3)
	_assert(Players.days_since_last_race() >= Players.DAYS_PER_TURN, "po pełnym DAYS_PER_TURN limit minął, kolejny zakład znów możliwy")


## Zgłoszone przez użytkownika: kursy koni mają dryfować jak ceny na Giełdzie/
## Rynku, nie być raz na zawsze ustawioną stałą (Horses.gd, ten sam wzorzec
## dryfu co ShippingCompanies.gd). Sprawdzamy dwie rzeczy naraz: że kurs
## faktycznie się zmienia po wielu skokach dni (nie stoi w miejscu), i że
## MIN_ODDS/MAX_ODDS trzymają go w rozsądnych granicach mimo wielu powtórzeń
## losowego dryfu (bez tego kurs mógłby "uciec" do zera i rozwalić wagę
## 1.0/odds w Races._pick_winner_index, albo wystrzelić do absurdu).
func _test_horses_odds_drift_and_bounds() -> void:
	print("-- Horses: kurs dryfuje dziennie i trzyma się w granicach MIN/MAX_ODDS --")
	Calendar.reset_new_game()
	Horses.reset_new_game()

	var starting_odds := Horses.get_odds("komet")
	var changed_at_least_once := false
	for i in 200:
		Calendar.advance_days(7)
		var odds := Horses.get_odds("komet")
		_assert(odds >= Horses.MIN_ODDS and odds <= Horses.MAX_ODDS, "kurs Komet w granicach [MIN_ODDS, MAX_ODDS] (iteracja %d)" % i)
		if not is_equal_approx(odds, starting_odds):
			changed_at_least_once = true
	_assert(changed_at_least_once, "kurs Komet faktycznie dryfuje po wielu skokach dni, nie stoi w miejscu")


## Zgłoszone przez użytkownika: kursy koni mają być WSPÓLNE — ten sam dzień =
## ten sam kurs, niezależnie który gracz akurat stawia zakład (Horses.gd to
## Tor A, podłączony do Calendar.day_advanced, nie do per-gracz
## Players.advance_active_player_time — ten sam wzorzec co
## _test_shared_price_by_day niżej dla Crops/ShippingCompanies).
func _test_horses_odds_shared_by_day() -> void:
	print("-- Horses: ten sam dzień = ten sam kurs, niezależnie kto dotarł pierwszy --")
	Calendar.reset_new_game()
	Players.reset_new_game(2)
	Horses.reset_new_game()

	Players.advance_active_player_time(15)  # gracz 1 pcha świat do dnia 15
	var odds_after_player_1 := Horses.get_odds("wicher")

	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 1, "gracz 2 (dzień 0, najwcześniejsza data) dostaje ruch")
	Players.advance_active_player_time(15)  # gracz 2 dogania do dnia 15 — już zasymulowanego

	_assert(is_equal_approx(Horses.get_odds("wicher"), odds_after_player_1), "gracz 2, docierając do TEGO SAMEGO dnia, widzi ten sam kurs Wicher")


## Zgłoszenie użytkownika: wynik wyścigu nie może być oczywisty od razu, więc
## RaceTrackView daje każdemu koniowi losowe "błądzenie" po drodze — ale
## kluczowa gwarancja uczciwości MUSI się trzymać niezależnie od tego
## losowania: przy t=1 (meta) zwycięzca (ustalony PRZED animacją, patrz
## komentarz w RaceTrackView.gd) ma ściśle najwyższą wartość krzywej pozycji
## ze wszystkich koni, więc wizualnie zawsze przybiega pierwszy. Powtarzamy
## z wieloma losowymi zwycięzcami, żeby złapać ewentualny błąd we wzorze
## niezależnie od tego, który koń akurat wygrywa.
func _test_race_track_winner_finishes_first() -> void:
	print("-- RaceTrackView: zwycięzca ma ściśle najwyższą pozycję na mecie (t=1), niezależnie od losowego błądzenia --")
	var image_paths: Array[String] = [
		"res://art/horses/komet.jpg", "res://art/horses/grom.jpg", "res://art/horses/cyklon.jpg",
		"res://art/horses/blyskawica.jpg", "res://art/horses/wicher.jpg",
	]
	for trial in 20:
		var winner_idx := randi() % image_paths.size()
		var view: Control = RaceTrackScript.new()
		add_child(view)
		view.setup(image_paths, winner_idx, Vector2(1280.0, 720.0))

		var winner_offset: float = view._curve_offset(winner_idx, 1.0)
		var winner_is_highest := true
		for i in image_paths.size():
			if i != winner_idx and view._curve_offset(i, 1.0) >= winner_offset:
				winner_is_highest = false
		_assert(winner_is_highest, "próba %d: zwycięzca (koń %d) ma najwyższą pozycję na mecie" % [trial, winner_idx])
		view.queue_free()


## Zgłoszone przez użytkownika: ceny na Giełdzie/Rynku mają być WSPÓLNE — ten
## sam dzień = ta sama cena, niezależnie kto do niego dotarł pierwszy. Skoro
## Crops/ShippingCompanies to Tor A (nie migawkowane per gracz), gracz
## doganiający resztę do JUŻ zasymulowanego dnia po prostu odczytuje tę samą,
## niezmienioną cenę — nie losuje jej na nowo.
func _test_shared_price_by_day() -> void:
	print("-- Crops/ShippingCompanies: ten sam dzień = ta sama cena, niezależnie kto dotarł pierwszy --")
	Calendar.reset_new_game()
	Players.reset_new_game(2)
	Crops.reset_new_game()
	ShippingCompanies.reset_new_game()

	Players.advance_active_player_time(15)  # gracz 1 pcha świat do dnia 15
	var price_after_player_1 := Crops.get_price("coffee")
	var shipping_after_player_1 := ShippingCompanies.get_price("lloyd")

	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 1, "gracz 2 (dzień 0, najwcześniejsza data) dostaje ruch")
	Players.advance_active_player_time(15)  # gracz 2 dogania do dnia 15 — już zasymulowanego

	_assert(is_equal_approx(Crops.get_price("coffee"), price_after_player_1), "gracz 2, docierając do TEGO SAMEGO dnia, widzi tę samą cenę kawy")
	_assert(is_equal_approx(ShippingCompanies.get_price("lloyd"), shipping_after_player_1), "to samo dla kursu linii żeglugowej Lloyd")
	_assert(Players.get_player_day(1) == 15, "własny dzień gracza 2 mimo to poprawnie dochodzi do 15")


## Regresja na błąd znaleziony przez agenta walidującego plan: bez rozdziału
## Toru A/B, gracz doganiający resztę mógłby wywołać DRUGI raz ten sam skok
## światowego dryfu cen dla zakresu dni, który już raz się wydarzył.
func _test_catching_up_player_does_not_double_world_drift() -> void:
	print("-- Players: gracz doganiający resztę nie podwaja światowego dryfu (Tor A rusza raz na dzień) --")
	Calendar.reset_new_game()
	Players.reset_new_game(2)
	Crops.reset_new_game()

	Players.advance_active_player_time(15)
	var history_size_after_player_1: int = Crops.price_history["coffee"].size()
	var world_day_after_player_1: int = Calendar.current_day

	Players.pass_turn_to_earliest_player()
	Players.advance_active_player_time(15)  # gracz 2 dogania do JUŻ zasymulowanego dnia 15

	_assert(Calendar.current_day == world_day_after_player_1, "świat (Tor A) nie rusza się dalej, gdy doganiający gracz nie wychodzi poza już zasymulowany zakres")
	_assert(Crops.price_history["coffee"].size() == history_size_after_player_1, "historia cen nie dostaje dodatkowego punktu za doganianie tego samego zakresu dni")


## Regresja na błąd znaleziony przez agenta walidującego plan: Economy.gd
## trzymało days_in_debt w tym samym _on_day_advanced co dollar_rate/inflation
## (Tor A) — bez wydzielenia go do apply_player_days_elapsed (Tor B), zadłużenie
## gracza doganiającego resztę liczyłoby się na podstawie delty ŚWIATA, a nie
## jego WŁASNYCH dni, i wynosiłoby 0, mimo że dla NIEGO te dni realnie minęły.
func _test_catching_up_player_gets_full_personal_consequences() -> void:
	print("-- Players: gracz doganiający dostaje PEŁNE osobiste konsekwencje, nawet gdy świat się nie rusza --")
	Calendar.reset_new_game()
	Players.reset_new_game(2)
	Economy.reset_new_game()

	Players.advance_active_player_time(20)  # gracz 1 pcha świat do dnia 20

	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 1, "gracz 2 (dzień 0) jest teraz najwcześniejszy")
	Economy.player_money = -100.0  # symulacja długu gracza 2

	Players.advance_active_player_time(20)  # gracz 2 dogania do dnia 20 — Tor A JUŻ tam był

	_assert(Calendar.current_day == 20, "świat pozostaje na dniu 20 (bez zmian od tej akcji)")
	_assert(Economy.days_in_debt == 20, "mimo braku ruchu świata, gracz 2 dostaje PEŁNE 20 dni w długu (Tor B liczy się z jego WŁASNEJ perspektywy)")


## Regresja na drugi (najkrytyczniejszy) błąd znaleziony przez agenta
## walidującego plan: Travel.gd było pierwotnie pominięte na liście systemów
## Toru B — bez przełączenia go na apply_player_days_elapsed, podróż gracza
## doganiającego resztę zawieszałaby się w połowie trasy, gdy Tor A nie ma już
## dla niego nowych dni do rozegrania.
func _test_catching_up_player_completes_travel() -> void:
	print("-- Travel: gracz doganiający kończy podróż, nawet gdy Tor A się nie rusza --")
	Calendar.reset_new_game()
	Players.reset_new_game(2)
	Travel.reset_new_game()

	Players.advance_active_player_time(30)  # gracz 1 pcha świat daleko do przodu

	Players.pass_turn_to_earliest_player()
	_assert(Players.active_index == 1, "gracz 2 (dzień 0) jest teraz najwcześniejszy")

	Travel.current_city = "berlin"
	Travel.route.clear()
	Travel.start_travel("london")  # 3.0 dnia — krócej niż to, co świat już zasymulował
	var days := int(ceil(Travel.last_travel_total_days))
	Players.advance_active_player_time(days)  # gracz 2 dogania w obrębie już zasymulowanego zakresu

	_assert(not Travel.is_traveling(), "podróż gracza 2 kończy się mimo że Tor A (Calendar.current_day) się nie rusza")
	_assert(Travel.current_city == "london", "Travel.current_city gracza 2 poprawnie zaktualizowany na miasto docelowe")


## Zgłoszone przez użytkownika: literówka typu (Container zamiast Control w
## parametrze funkcji) w Gallery.gd przeszła całe CI bez wykrycia — boot
## headless (patrz nagłówek pliku) parsuje tylko autoloady + GŁÓWNĄ scenę,
## więc skrypty POZOSTAŁYCH ekranów (Gallery.gd, AuctionHouse.gd, ...) nigdy
## nie są odwiedzane, chyba że akurat są sceną startową. Błąd wyszedł dopiero
## przy ręcznym uruchomieniu w edytorze. Ten test ładuje KAŻDY skrypt sceny
## wprost przez load() — błąd parsera (Godot loguje "Parse Error" i load()
## zwraca null) wykryje się więc już tutaj, w CI.
func _test_all_scene_scripts_parse_without_error() -> void:
	print("-- Sanity: wszystkie skrypty scen (scenes/**/*.gd) ładują się bez błędu parsera --")
	var script_paths := _find_gd_scripts("res://scenes")
	_assert(script_paths.size() > 0, "znaleziono przynajmniej jeden skrypt sceny do sprawdzenia")
	for path in script_paths:
		var script: Script = load(path)
		_assert(script != null, "ładuje się bez błędu parsera: %s" % path)


## Rekurencyjne przejście katalogu w poszukiwaniu plików .gd — DirAccess
## zamiast statycznej listy, żeby nowe ekrany automatycznie wchodziły pod
## powyższy test bez pamiętania o dopisaniu ich ręcznie.
func _find_gd_scripts(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path := dir_path + "/" + entry
			if dir.current_is_dir():
				result.append_array(_find_gd_scripts(full_path))
			elif entry.ends_with(".gd"):
				result.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return result
