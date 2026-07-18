extends Control
## Mapa świata / hub — docelowo zastąpiona właściwą mapą (docs/GRAFIKA_LEONARDO.md
## pkt. 2). Na razie: pasek stanu, podróże między miastami i nawigacja do
## wszystkich ekranów.

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

const DAYS_PER_WEEK_ADVANCE := 7

var status_label: Label
var travel_status_label: Label
var destination_option: OptionButton
var travel_button: Button


func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "VERMEER — Mapa świata")

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

	ScreenHelpers.make_button(root, "Tydzień naprzód »", _on_advance_week_pressed)

	_update_status()


func _on_travel_pressed() -> void:
	if destination_option.selected < 0:
		return
	var destination: String = destination_option.get_item_metadata(destination_option.selected)
	Travel.start_travel(destination)
	_update_status()


func _on_advance_week_pressed() -> void:
	Calendar.advance_days(DAYS_PER_WEEK_ADVANCE)
	_update_status()
	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)


func _update_status() -> void:
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
