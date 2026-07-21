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

var status_label: Label
var turn_label: Label
var travel_status_label: Label
var travel_button: Button
var root_panel: VBoxContainer
var hub_bg: TextureRect
var hub_overlay: ColorRect


func _ready() -> void:
	var bg_layers := ScreenHelpers.make_background_with_overlay(self, Cities.get_city_background(Travel.current_city))
	hub_bg = bg_layers["background"]
	hub_overlay = bg_layers["overlay"]

	## Panel boczny zamiast pełnoekranowego — w oryginale menu i pasek stanu
	## to małe skrzynki w rogach ekranu, nie zasłaniają całego widoku
	## (patrz zrzuty ekranu z oryginału). make_root_side() daje ten sam
	## efekt: wąska kolumna z prawej, reszta tła regionu zostaje odsłonięta.
	root_panel = ScreenHelpers.make_root_side(self)
	ScreenHelpers.make_title(root_panel, "VERMEER")

	turn_label = ScreenHelpers.make_label(root_panel, "")
	status_label = ScreenHelpers.make_label(root_panel, "")
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	travel_status_label = ScreenHelpers.make_label(root_panel, "")
	travel_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD

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
	tween.chain().tween_callback(func(): SceneRouter.goto_scene(SceneRouter.TRAVEL_MAP))


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
	if Players.is_multiplayer():
		turn_label.text = "Tura: %s (gracz %d/%d)" % [
			Players.active_name(), Players.active_index + 1, Players.player_count,
		]

	var text := "Gotówka: %.0f M | Data: %s | Obrazy: %d/%d" % [
		Economy.player_money,
		Calendar.get_date_string(),
		Paintings.owned_count(),
		Paintings.win_threshold,
	]
	if Economy.is_reform_imminent():
		text += "\n⚠ Kurs dolara wysoki — zbliża się reforma walutowa!"
	status_label.text = text

	if Travel.is_traveling():
		travel_status_label.text = "W podróży do %s — pozostało %.1f dnia (trasa: %s)" % [
			Cities.get_city_name(Travel.get_destination()),
			Travel.days_remaining,
			", ".join(Travel.route.map(func(c): return Cities.get_city_name(c))),
		]
	else:
		travel_status_label.text = "Jesteś w: %s" % Cities.get_city_name(Travel.current_city)

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
