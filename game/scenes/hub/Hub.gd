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
	"Dom aukcyjny": {"path": "res://scenes/auction_house/AuctionHouse.tscn", "requires_type": "auction"},
	"Galeria": {"path": "res://scenes/gallery/Gallery.tscn", "requires_type": "auction"},
}
const FREE_DESTINATIONS := {
	"Giełda": "res://scenes/stock_market/StockMarket.tscn",
	"Wyścigi konne": "res://scenes/races/Races.tscn",
	"Szkoła sztuki": "res://scenes/art_school/ArtSchool.tscn",
}

const MapPinScript := preload("res://scripts/ui/MapPin.gd")
const ZOOM_OUT_DURATION := 0.9

var location_label: Label
var money_label: Label
var date_label: Label
var paintings_label: Label
var warning_label: Label
var travel_button: Button
var root_panel: VBoxContainer
var top_row: HBoxContainer
var hub_bg: TextureRect
var hub_overlay: ColorRect


func _ready() -> void:
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

	## Panel boczny na menu nawigacyjne — zostaje w prawym dolnym rogu,
	## zgodnie z oryginałem, ale bez informacji statusu (te są teraz w
	## top_row powyżej). use_menu_frame=true: ozdobna ramka Art Deco
	## zamiast zwykłego półprzezroczystego tła (docs/GRAFIKA_LEONARDO.md §10).
	root_panel = ScreenHelpers.make_root_side(self, true, true)

	travel_button = ScreenHelpers.make_button(root_panel, "Jedź »", _on_travel_pressed)

	for destination_name in LOCATION_GATED_DESTINATIONS.keys():
		var info: Dictionary = LOCATION_GATED_DESTINATIONS[destination_name]
		var path: String = info["path"]
		var btn := ScreenHelpers.make_button(root_panel, destination_name, func(): SceneRouter.goto_scene(path))
		btn.set_meta("requires_type", info["requires_type"])

	for destination_name in FREE_DESTINATIONS.keys():
		var path: String = FREE_DESTINATIONS[destination_name]
		ScreenHelpers.make_button(root_panel, destination_name, func(): SceneRouter.goto_scene(path))

	ScreenHelpers.make_button(root_panel, "Koniec tury »", _on_end_turn_pressed)
	ScreenHelpers.make_button(root_panel, "Zapisz i wyjdź do menu", _on_save_and_exit_pressed)

	_update_status()


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
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	add_child(row)

	var left_column := VBoxContainer.new()
	left_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_column.add_theme_constant_override("separation", 8)
	row.add_child(left_column)

	location_label = ScreenHelpers.make_info_box(left_column, "", 280.0, 22)
	date_label = ScreenHelpers.make_info_box(left_column, "")
	paintings_label = ScreenHelpers.make_info_box(left_column, "")

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

	## Płynne wygaszenie do czerni w ostatniej jednej trzeciej animacji,
	## zsynchronizowane tak, żeby dojść do pełnej czerni DOKŁADNIE w
	## momencie zakończenia reszty animacji — maskuje klatkę przerwy, którą
	## silnik potrafi wyrenderować przy change_scene_to_file() (patrz
	## SceneRouter.goto_scene_after_fade). Nagłe, natychmiastowe przykrycie
	## tuż przed przełączeniem (bez tego płynnego tweena) samo wygląda jak
	## mrugnięcie — dlatego to musi być część TEJ SAMEJ animacji zoom, a nie
	## osobny krok po niej.
	var fade_cover := SceneRouter.get_fade_cover()
	fade_cover.color.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(map_bg, "modulate:a", 1.0, ZOOM_OUT_DURATION)
	tween.tween_property(hub_overlay, "modulate:a", 0.0, ZOOM_OUT_DURATION)
	tween.tween_property(hub_bg, "scale", pin_scale, ZOOM_OUT_DURATION)
	tween.tween_property(root_panel, "modulate:a", 0.0, ZOOM_OUT_DURATION * 0.5)
	tween.tween_property(top_row, "modulate:a", 0.0, ZOOM_OUT_DURATION * 0.5)
	tween.tween_property(fade_cover, "color:a", 1.0, ZOOM_OUT_DURATION * 0.35).set_delay(ZOOM_OUT_DURATION * 0.65)
	tween.chain().tween_callback(func(): SceneRouter.goto_scene_after_fade(SceneRouter.TRAVEL_MAP))


func _set_buttons_disabled(disabled: bool) -> void:
	for child in root_panel.get_children():
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
		location_label.text = "%s\nw podróży do %s (%.1f dnia)" % [
			Players.active_name(), Cities.get_city_name(Travel.get_destination()), Travel.days_remaining,
		]
	else:
		location_label.text = "%s\nw: %s" % [Players.active_name(), Cities.get_city_name(Travel.current_city)]
	if Players.is_multiplayer():
		location_label.text += "\n(gracz %d/%d)" % [Players.active_index + 1, Players.player_count]

	money_label.text = "%.0f M" % Economy.player_money
	date_label.text = Calendar.get_date_string()
	paintings_label.text = "Obrazy: %d/%d" % [Paintings.owned_count(), Paintings.win_threshold]

	warning_label.visible = Economy.is_reform_imminent()
	warning_label.text = "⚠ Kurs dolara wysoki — zbliża się reforma walutowa!" if warning_label.visible else ""

	travel_button.visible = not Travel.is_traveling()

	for child in get_children():
		_update_gated_button(child)


func _update_gated_button(node: Node) -> void:
	if node is Button and node.has_meta("requires_type"):
		var requires_type: String = node.get_meta("requires_type")
		var current_type: String = Cities.CITIES.get(Travel.current_city, {}).get("type", "")
		node.visible = not Travel.is_traveling() and current_type == requires_type
	for child in node.get_children():
		_update_gated_button(child)
