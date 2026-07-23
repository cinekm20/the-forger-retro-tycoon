extends Control
## Hub — pasek stanu i nawigacja do wszystkich ekranów. Tło zależy od
## aktualnej lokalizacji (regionu), nie jest już mapą świata — mapa z
## klikalnymi pinezkami żyje teraz na osobnym ekranie (scenes/travel_map),
## otwieranym przyciskiem "Jedź »" (patrz GDD.md pkt. 4.9).

## Ekrany, które wymagają bycia w mieście danego typu (patrz Cities.CITIES).
## W oryginale menu w ogóle nie pokazywało niedostępnych opcji (np. Londyn:
## TRAVEL/BANK/MARK./AUCTION/COLLECT./OVERVIEW, ale St. Louis zamiast
## AUCTION/COLLECT. miało PLANTAT./WORKERS) — więc te przyciski są tu
## całkiem UKRYWANE poza właściwym typem miasta, nie tylko wyszarzane
## (patrz _update_gated_button niżej). Ekrany spoza tej listy są dostępne
## z każdego miasta.
const LOCATION_GATED_DESTINATIONS := {
	"Plantacje": {"path": "res://scenes/plantation/Plantation.tscn", "requires_type": "plantation"},
	"Spichlerz": {"path": "res://scenes/warehouse/Warehouse.tscn", "requires_type": "plantation"},
	"Dom aukcyjny": {"path": "res://scenes/auction_house/AuctionHouse.tscn", "requires_type": "auction"},
	"Galeria": {"path": "res://scenes/gallery/Gallery.tscn", "requires_type": "auction"},
	## Zgłoszone przez użytkownika: Szkoła sztuki ma być dostępna tylko w
	## miastach aukcyjnych (Berlin/Paryż/Amsterdam/Lizbona/Londyn), nie
	## wszędzie — bez Nowego Jorku (który jest typu "hub", nie "auction")
	## mieści się już w istniejącym mechanizmie bramkowania wg typu, zamiast
	## osobnej listy konkretnych miast.
	"Szkoła sztuki": {"path": "res://scenes/art_school/ArtSchool.tscn", "requires_type": "auction"},
}
const FREE_DESTINATIONS := {
	"Giełda": "res://scenes/stock_market/StockMarket.tscn",
	"Wyścigi konne": "res://scenes/races/Races.tscn",
}

const MapPinScript := preload("res://scripts/ui/MapPin.gd")
const ZOOM_OUT_DURATION := 0.9

var location_label: Label
var money_label: Label
var date_label: Label
var paintings_label: Label
var auction_schedule_label: Label
var warning_label: Label
var travel_button: Button
var root_panel: VBoxContainer
var main_menu_section: VBoxContainer
var places_menu_section: VBoxContainer
var top_row: HBoxContainer
var hub_bg: TextureRect
var hub_overlay: ColorRect
var turn_summary_container: HBoxContainer
var turn_summary_label: Label
var turn_summary_button: Button


func _ready() -> void:
	## Podsumowanie roku (patrz YearlyReport.gd) — jeśli od ostatniego wejścia
	## do Huba minął Sylwester w grze, pokaż je NAJPIERW, zamiast budować
	## resztę Huba pod spodem (i tak zostanie natychmiast odsłonięty
	## normalny Hub po kliknięciu "Kontynuuj" na ekranie podsumowania).
	if YearlyReport.has_pending():
		SceneRouter.goto_scene(SceneRouter.YEAR_SUMMARY)
		return

	var bg_layers := ScreenHelpers.make_background_with_overlay(self, Cities.get_city_background(Travel.current_city))
	hub_bg = bg_layers["background"]
	hub_overlay = bg_layers["overlay"]

	## W oryginale skrzynki statusu leżą rozrzucone w rogach ekranu (imię
	## gracza + lokalizacja i data w lewym górnym rogu, gotówka w prawym),
	## a menu to osobna skrzynka w prawym dolnym rogu — NIE wszystko razem
	## w jednym bocznym pasku. top_row (pełnoekranowy, niewidoczny poziomy
	## kontener) trzyma lewą kolumnę (location/date/obrazy) i skrzynkę
	## gotówki po przeciwnych stronach — patrz komentarz przy _build_top_row.
	top_row = _build_top_row()
	_build_turn_summary()

	## Panel boczny na menu nawigacyjne — zostaje w prawym dolnym rogu,
	## zgodnie z oryginałem, ale bez informacji statusu (te są teraz w
	## top_row powyżej). use_menu_frame=true: ozdobna ramka Art Deco
	## zamiast zwykłego półprzezroczystego tła (docs/GRAFIKA_LEONARDO.md §10).
	root_panel = ScreenHelpers.make_root_side(self, true, true)

	## Na telefonie przewijanie tego paska dotykiem nie zawsze działa
	## niezawodnie (zgłoszone przez użytkownika), więc zamiast liczyć na
	## scrollowanie długiej listy, główny panel trzyma tylko kilka pozycji na
	## stałe, a ekrany lokacji (bramkowane + darmowe) chowają się w osobnym
	## podmenu "Miejsca »" — otwieranym/zamykanym przełączeniem visible
	## między main_menu_section i places_menu_section (ten sam patent co
	## MainMenu.gd _show_name_entry). ScrollContainer z make_root_side zostaje
	## jako zabezpieczenie, ale w normalnych warunkach nie powinien być już
	## potrzebny.
	main_menu_section = VBoxContainer.new()
	root_panel.add_child(main_menu_section)

	places_menu_section = VBoxContainer.new()
	places_menu_section.visible = false
	root_panel.add_child(places_menu_section)

	travel_button = ScreenHelpers.make_button(main_menu_section, "Jedź »", _on_travel_pressed)
	ScreenHelpers.make_button(main_menu_section, "Miejsca »", _show_places_menu)
	ScreenHelpers.make_button(main_menu_section, "Koniec tury »", _on_end_turn_pressed)
	ScreenHelpers.make_button(main_menu_section, "Zapisz i wyjdź do menu", _on_save_and_exit_pressed)

	for destination_name in LOCATION_GATED_DESTINATIONS.keys():
		var info: Dictionary = LOCATION_GATED_DESTINATIONS[destination_name]
		var path: String = info["path"]
		var btn := ScreenHelpers.make_button(places_menu_section, destination_name, func(): SceneRouter.goto_scene(path))
		btn.set_meta("requires_type", info["requires_type"])

	for destination_name in FREE_DESTINATIONS.keys():
		var path: String = FREE_DESTINATIONS[destination_name]
		ScreenHelpers.make_button(places_menu_section, destination_name, func(): SceneRouter.goto_scene(path))

	ScreenHelpers.make_button(places_menu_section, "« Powrót", _hide_places_menu)

	_update_status()


func _show_places_menu() -> void:
	main_menu_section.visible = false
	places_menu_section.visible = true


func _hide_places_menu() -> void:
	places_menu_section.visible = false
	main_menu_section.visible = true


## Pełnoekranowy, przezroczysty HBoxContainer (PRESET_FULL_RECT — bezpieczny,
## zawsze dynamicznie dopasowuje się do rozmiaru ekranu, w przeciwieństwie do
## presetów typu TOP_WIDE, które liczą wysokość raz, w momencie wywołania —
## pułapka opisana przy make_root_side w screen_helpers.gd).
## Lewa kolumna (location/data/obrazy) i skrzynka gotówki mają
## size_flags_vertical = SIZE_SHRINK_BEGIN, więc "przyklejają się" do góry
## zamiast rozciągać na całą wysokość ekranu; spacer między nimi ma
## SIZE_EXPAND_FILL i pcha skrzynkę gotówki do prawej krawędzi.
func _build_top_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	## Margines od krawędzi ekranu — bez niego skrzynka gotówki (prawy górny
	## róg) leżała dosłownie na samej krawędzi viewportu, więc na telefonie
	## z zaokrąglonymi rogami/notchem część liczby wypadała poza widoczny
	## obszar (zgłoszone przez testera: "nie widać całej liczby").
	row.offset_left = 16
	row.offset_right = -16
	row.offset_top = 12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	add_child(row)

	var left_column := VBoxContainer.new()
	left_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_column.add_theme_constant_override("separation", 8)
	row.add_child(left_column)

	## Awatar POŁĄCZONY z tą samą skrzynką co imię/lokalizacja gracza (nie
	## osobno obok, jak wcześniej) i większy (80×80, było 64×64) —
	## zgłoszone przez użytkownika. make_boxed_row (nie make_info_box), bo
	## potrzeba więcej niż jednej etykiety w tej samej ramce. Skrzynka jest
	## szersza (360) niż pozostałe 3 (280), żeby zmieścić avatar + tekst —
	## nadal stała szerokość, więc nie "skacze" przy zmianie treści (patrz
	## komentarz przy pozostałych skrzynkach niżej).
	var location_row := ScreenHelpers.make_boxed_row(left_column)
	location_row.get_parent().custom_minimum_size = Vector2(360, 0)

	var avatar_rect := TextureRect.new()
	avatar_rect.custom_minimum_size = Vector2(80, 80)
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	## Awatar aktywnego gracza (wybrany przy starcie nowej gry, patrz
	## MainMenu.gd _show_name_entry / Players.get_avatar_path) — w hot-seat
	## zmienia się przy każdym end_turn, bo _ready() przelicza go na nowo z
	## Players.active_index po przeładowaniu Huba (SceneRouter.goto_hub()).
	var avatar_path := Players.active_avatar_path()
	avatar_rect.texture = load(avatar_path) if ResourceLoader.exists(avatar_path) else null
	location_row.add_child(avatar_rect)

	location_label = Label.new()
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
	location_label.add_theme_font_size_override("font_size", 22)
	location_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	location_label.custom_minimum_size = Vector2(230, 0)
	location_row.add_child(location_label)

	## Wszystkie pozostałe skrzynki dostają TĘ SAMĄ szerokość (280) —
	## użytkownik zgłosił, że muszą być zawsze jednakowej szerokości,
	## niezależnie od treści (np. skrzynka terminu aukcji miała różną
	## szerokość zależnie od długości nazwy miasta: Amsterdam vs Berlin).
	## make_info_box z min_width > 0 wymusza teraz stałą szerokość +
	## zawijanie zamiast rozpychania skrzynki (patrz komentarz w
	## screen_helpers.gd).
	date_label = ScreenHelpers.make_info_box(left_column, "", 280.0)
	paintings_label = ScreenHelpers.make_info_box(left_column, "", 280.0)
	## Skrzynka "NEXT AUCTION IS: ..." z oryginału — widoczna niezależnie od
	## typu aktualnego miasta, bo termin aukcji dotyczy jednego z 5 miast
	## aukcyjnych, nie koniecznie tego, w którym gracz akurat jest.
	auction_schedule_label = ScreenHelpers.make_info_box(left_column, "", 280.0)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var right_column := VBoxContainer.new()
	right_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(right_column)

	money_label = ScreenHelpers.make_info_box(right_column, "")
	warning_label = ScreenHelpers.make_label(right_column, "")
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	warning_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
	warning_label.custom_minimum_size = Vector2(220, 0)

	return row


## Krótkie podsumowanie aktualnego miasta, w lewym dolnym rogu ekranu
## (zgłoszone przez użytkownika) — jeśli w mieście jest dziś aukcja, pokaż to
## z możliwością od razu tam przejść; jeśli miasto ma plantację gracza,
## pokaż, ile jest aktualnie gotowe do zbioru. Cała skrzynka (make_boxed_row)
## chowa się całkiem, gdy żaden z warunków nie zachodzi.
func _build_turn_summary() -> void:
	## PRESET_FULL_RECT (nie żaden z presetów typu BOTTOM_LEFT!) — ten sam
	## patent co "row" w _build_top_row wyżej. Presety inne niż FULL_RECT
	## liczyłyby rozmiar/offsety raz, w momencie wywołania (czyli na
	## podstawie 0×0, zanim dojdą dzieci) i zablokowałyby kontener trwale na
	## błędnym rozmiarze (patrz komentarz przy make_root_side w
	## screen_helpers.gd) — FULL_RECT jest bezpieczny, bo zawsze rozciąga
	## się na cały ekran; ALIGNMENT_BEGIN (poziomo) + SIZE_SHRINK_END
	## (pionowo, na samej oprawionej skrzynce — size_flags działają na
	## DZIECKU Containera, nie na samym Containerze) przyklejają ją do
	## lewego DOLNEGO rogu tego (niewidocznie pełnoekranowego) obszaru.
	turn_summary_container = HBoxContainer.new()
	turn_summary_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	turn_summary_container.offset_left = 16
	turn_summary_container.offset_bottom = -16
	turn_summary_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	turn_summary_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(turn_summary_container)

	var row := ScreenHelpers.make_boxed_row(turn_summary_container)
	row.get_parent().size_flags_vertical = Control.SIZE_SHRINK_END

	turn_summary_label = Label.new()
	turn_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_summary_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
	turn_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	turn_summary_label.custom_minimum_size = Vector2(300, 0)
	row.add_child(turn_summary_label)

	turn_summary_button = ScreenHelpers.make_button(row, tr("Przejdź do aukcji »"), func(): SceneRouter.goto_scene(SceneRouter.AUCTION_HOUSE))
	turn_summary_button.visible = false


func _update_turn_summary() -> void:
	var lines: Array[String] = []

	if not Travel.is_traveling() and Auctions.is_open(Travel.current_city):
		lines.append(tr("W tym mieście trwa dziś aukcja!"))
		turn_summary_button.visible = true
	else:
		turn_summary_button.visible = false

	var plantation_index := PlayerPlantations.find_plantation_index(Travel.current_city)
	if not Travel.is_traveling() and plantation_index != -1:
		var ready_amounts := PlayerPlantations.calculate_harvest(plantation_index)
		var ready_total := 0
		for amount in ready_amounts.values():
			ready_total += amount
		if ready_total > 0:
			lines.append(tr("Gotowe do zbioru: %d jednostek.") % ready_total)

	turn_summary_container.visible = not lines.is_empty()
	turn_summary_label.text = "\n".join(lines)


## Zamiast od razu przełączać scenę, tło Huba "kurczy się" do pozycji
## pinezki aktualnego miasta na mapie świata, a mapa pojawia się pod spodem
## — dopiero potem ładuje się TravelMap.tscn (który ma dokładnie tę samą
## pinezkę w tym samym miejscu, patrz Cities.get_map_position — ciągłość
## wizualna między ekranami). Odwrotność tego dzieje się w
## TravelAnimation.gd po dotarciu do celu (zoom-in z pinezki w nowy Hub).
func _on_travel_pressed() -> void:
	_set_buttons_disabled(true)

	var viewport_size := get_viewport_rect().size
	var target_pos := Cities.get_map_position(Travel.current_city) * viewport_size

	var map_bg := TextureRect.new()
	map_bg.texture = load(Cities.MAP_BACKGROUND_PATH)
	map_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_bg.stretch_mode = TextureRect.STRETCH_SCALE
	map_bg.modulate.a = 0.0
	add_child(map_bg)
	move_child(map_bg, 0)  # pod hub_bg, który się kurczy i odsłania mapę

	## Ta sama przyciemniająca nakładka co docelowy TravelMap.tscn (alpha
	## 0.45, patrz ScreenHelpers.make_background_with_overlay) — bez niej
	## pojawiająca się mapa była jaśniejsza niż finalny ekran mapy, widoczny
	## skok jasności przy przełączeniu scen (ten sam problem co przy
	## zoom-inie w TravelAnimation.gd). Dziecko map_bg — jego modulate:a
	## (fade-in mapy) cascaduje na dzieci, więc nakładka ciemnieje w tym
	## samym tempie co pojawia się mapa, bez osobnego tweena.
	var map_overlay := ColorRect.new()
	map_overlay.color = Color(0, 0, 0, 0.45)
	map_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_bg.add_child(map_overlay)

	hub_bg.pivot_offset = target_pos
	var pin_scale := MapPinScript.PIN_SIZE / viewport_size

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(map_bg, "modulate:a", 1.0, ZOOM_OUT_DURATION)
	tween.tween_property(hub_overlay, "modulate:a", 0.0, ZOOM_OUT_DURATION)
	tween.tween_property(hub_bg, "scale", pin_scale, ZOOM_OUT_DURATION)
	tween.tween_property(root_panel, "modulate:a", 0.0, ZOOM_OUT_DURATION * 0.5)
	tween.tween_property(top_row, "modulate:a", 0.0, ZOOM_OUT_DURATION * 0.5)
	## goto_scene_crossfade zamiast goto_scene: robi zrzut ostatniej klatki
	## zoomu i płynnie z niego wygasza do nowej sceny pod spodem, zamiast
	## nagłego cięcia (patrz SceneRouter.gd) — bez tego widać mrugnięcie
	## dokładnie w momencie przełączenia scen.
	tween.chain().tween_callback(func(): SceneRouter.goto_scene_crossfade(SceneRouter.TRAVEL_MAP))


func _set_buttons_disabled(disabled: bool) -> void:
	for child in main_menu_section.get_children() + places_menu_section.get_children():
		if child is Button:
			child.disabled = disabled


func _on_save_and_exit_pressed() -> void:
	SaveGame.save_game()
	SceneRouter.goto_scene(SceneRouter.MAIN_MENU)


func _on_end_turn_pressed() -> void:
	Players.end_turn()
	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)
	else:
		SceneRouter.goto_hub()  # przeładuj scenę — nowy aktywny gracz ma inny stan/lokalizację


func _update_status() -> void:
	## Jedna skrzynka "imię gracza w mieście" (tak jak oryginalne "JASONJ IN
	## LISBON") — w multiplayer dodatkowo numer gracza, bo wtedy ważne jest,
	## kto trzyma telefon.
	if Travel.is_traveling():
		location_label.text = tr("%s\nw podróży do %s (%.1f dnia)") % [
			Players.active_name(), Cities.get_city_name(Travel.get_destination()), Travel.days_remaining,
		]
	else:
		location_label.text = tr("%s\nw: %s") % [Players.active_name(), Cities.get_city_name(Travel.current_city)]
	if Players.is_multiplayer():
		location_label.text += tr("\n(gracz %d/%d)") % [Players.active_index + 1, Players.player_count]

	money_label.text = tr("%.0f M") % Economy.player_money
	date_label.text = Calendar.get_date_string()
	paintings_label.text = tr("Obrazy: %d/%d") % [Paintings.owned_count(), Paintings.win_threshold]
	auction_schedule_label.text = Auctions.get_schedule_string()

	warning_label.visible = Economy.is_reform_imminent()
	warning_label.text = tr("⚠ Kurs dolara wysoki — zbliża się reforma walutowa!") if warning_label.visible else ""

	travel_button.visible = not Travel.is_traveling()
	_update_turn_summary()

	for child in get_children():
		_update_gated_button(child)


func _update_gated_button(node: Node) -> void:
	if node is Button and node.has_meta("requires_type"):
		var requires_type: String = node.get_meta("requires_type")
		var current_type: String = Cities.CITIES.get(Travel.current_city, {}).get("type", "")
		node.visible = not Travel.is_traveling() and current_type == requires_type
	for child in node.get_children():
		_update_gated_button(child)
