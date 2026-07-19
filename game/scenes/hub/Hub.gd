extends Control
## Mapa świata / hub — tło art/backgrounds/hub_map.jpg (docs/GRAFIKA_LEONARDO.md
## pkt. 2), reszta ekranu wciąż na surowym UI Godota: pasek stanu, podróże
## między miastami i nawigacja do wszystkich ekranów.

## Ekrany, które wymagają bycia w mieście danego typu (patrz Cities.CITIES),
## na wzór "zablokowanych" opcji menu z oryginału (docs/ZRODLA_C64_WIKI.md,
## sekcja Bedienung). Ekrany spoza tej listy są dostępne z każdego miasta.
const LOCATION_GATED_DESTINATIONS := {
	"Plantacje": {"path": "res://scenes/plantation/Plantation.tscn", "requires_type": "plantation"},
	"Dom aukcyjny": {"path": "res://scenes/auction_house/AuctionHouse.tscn", "requires_type": "auction"},
}
const FREE_DESTINATIONS := {
	"Giełda": "res://scenes/stock_market/StockMarket.tscn",
	"Wyścigi konne": "res://scenes/races/Races.tscn",
	"Szkoła sztuki": "res://scenes/art_school/ArtSchool.tscn",
	"Galeria": "res://scenes/gallery/Gallery.tscn",
}

## Kolory pinezek wg typu miasta (Cities.CITIES[id]["type"]) — nasza paleta
## złoto/burgund/turkus. Aktualne miasto gracza dostaje osobny, biały kolor.
const TYPE_PIN_COLORS := {
	"plantation": Color(0.85, 0.65, 0.2),
	"auction": Color(0.55, 0.1, 0.15),
	"hub": Color(0.1, 0.55, 0.55),
}
const CURRENT_CITY_PIN_COLOR := Color(1.0, 1.0, 1.0)

const MapPinScript := preload("res://scripts/ui/MapPin.gd")

var status_label: Label
var turn_label: Label
var travel_status_label: Label
var destination_option: OptionButton
var travel_button: Button


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/hub_map.jpg")
	_build_pins()
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "VERMEER — Mapa świata")

	turn_label = ScreenHelpers.make_label(root, "")
	status_label = ScreenHelpers.make_label(root, "")
	travel_status_label = ScreenHelpers.make_label(root, "")

	var travel_row := HBoxContainer.new()
	travel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(travel_row)

	destination_option = OptionButton.new()
	for city_id in Cities.CITIES.keys():
		if city_id == Travel.current_city:
			continue
		destination_option.add_item(Cities.get_city_name(city_id))
		destination_option.set_item_metadata(destination_option.item_count - 1, city_id)
	travel_row.add_child(destination_option)

	travel_button = Button.new()
	travel_button.text = "Jedź »"
	travel_button.pressed.connect(_on_travel_pressed)
	travel_row.add_child(travel_button)

	for destination_name in LOCATION_GATED_DESTINATIONS.keys():
		var info: Dictionary = LOCATION_GATED_DESTINATIONS[destination_name]
		var path: String = info["path"]
		var btn := ScreenHelpers.make_button(root, destination_name, func(): SceneRouter.goto_scene(path))
		btn.set_meta("requires_type", info["requires_type"])

	for destination_name in FREE_DESTINATIONS.keys():
		var path: String = FREE_DESTINATIONS[destination_name]
		ScreenHelpers.make_button(root, destination_name, func(): SceneRouter.goto_scene(path))

	ScreenHelpers.make_button(root, "Koniec tury »", _on_end_turn_pressed)

	_update_status()


## Rozmieszcza klikalne pinezki nad mapą wg Cities.MAP_POSITION — dotknięcie
## pinezki innego miasta niż aktualne od razu rozpoczyna podróż (to samo, co
## wybór z listy rozwijanej + "Jedź »" niżej, tylko szybciej).
func _build_pins() -> void:
	var pins_layer := Control.new()
	pins_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pins_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(pins_layer)

	var viewport_size := get_viewport_rect().size
	for city_id in Cities.CITIES.keys():
		var pin: Button = MapPinScript.new()
		var city_type: String = Cities.CITIES[city_id]["type"]
		pin.pin_color = CURRENT_CITY_PIN_COLOR if city_id == Travel.current_city else TYPE_PIN_COLORS.get(city_type, Color.GRAY)
		var frac: Vector2 = Cities.get_map_position(city_id)
		pin.position = frac * viewport_size - MapPinScript.PIN_SIZE / 2.0
		pin.tooltip_text = Cities.get_city_name(city_id)
		pin.pressed.connect(_on_pin_pressed.bind(city_id))
		pins_layer.add_child(pin)


func _on_pin_pressed(city_id: String) -> void:
	if city_id == Travel.current_city:
		return
	Travel.start_travel(city_id)
	_update_status()


func _on_travel_pressed() -> void:
	if destination_option.selected < 0:
		return
	var destination: String = destination_option.get_item_metadata(destination_option.selected)
	Travel.start_travel(destination)
	_update_status()


func _on_end_turn_pressed() -> void:
	Players.end_turn()
	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)
	else:
		SceneRouter.goto_hub()  # przeładuj scenę — nowy aktywny gracz ma inną mapę/plantacje


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

	destination_option.visible = not Travel.is_traveling()
	travel_button.visible = not Travel.is_traveling()

	for child in get_children():
		_update_gated_button(child)


func _update_gated_button(node: Node) -> void:
	if node is Button and node.has_meta("requires_type"):
		var requires_type: String = node.get_meta("requires_type")
		var current_type: String = Cities.CITIES.get(Travel.current_city, {}).get("type", "")
		node.disabled = Travel.is_traveling() or current_type != requires_type
	for child in node.get_children():
		_update_gated_button(child)
