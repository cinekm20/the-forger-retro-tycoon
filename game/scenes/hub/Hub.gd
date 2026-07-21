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
}
const FREE_DESTINATIONS := {
	"Giełda": "res://scenes/stock_market/StockMarket.tscn",
	"Wyścigi konne": "res://scenes/races/Races.tscn",
	"Szkoła sztuki": "res://scenes/art_school/ArtSchool.tscn",
	"Galeria": "res://scenes/gallery/Gallery.tscn",
}

## Tła wg regionu aktualnej lokalizacji (docs/GRAFIKA_LEONARDO.md §2.1).
## south_america i central_america dzielą jeden szablon "tropikalny port"
## (Rio/Bogota/Gwatemala/Meksyk w oryginalnym planie to jedna grupa
## stylistyczna, mimo że w Cities.gd mają dwa różne klucze region). Wszystkie
## 6 regionów z Cities.gd ma już własne tło — FALLBACK_BACKGROUND niżej to
## czysta rezerwa na wypadek nowego/nieznanego klucza region.
const REGION_BACKGROUNDS := {
	"europe": "res://art/backgrounds/region_europe.jpg",
	"south_america": "res://art/backgrounds/region_tropical_port.jpg",
	"central_america": "res://art/backgrounds/region_tropical_port.jpg",
	"africa": "res://art/backgrounds/region_africa.jpg",
	"asia": "res://art/backgrounds/region_asia.jpg",
	"north_america": "res://art/backgrounds/region_north_america.jpg",
}
const FALLBACK_BACKGROUND := "res://art/backgrounds/hub_map.jpg"

var status_label: Label
var turn_label: Label
var travel_status_label: Label
var travel_button: Button


func _ready() -> void:
	ScreenHelpers.make_background(self, _get_current_background())
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "VERMEER")

	turn_label = ScreenHelpers.make_label(root, "")
	status_label = ScreenHelpers.make_label(root, "")
	travel_status_label = ScreenHelpers.make_label(root, "")

	travel_button = ScreenHelpers.make_button(root, "Jedź »", func(): SceneRouter.goto_scene(SceneRouter.TRAVEL_MAP))

	for destination_name in LOCATION_GATED_DESTINATIONS.keys():
		var info: Dictionary = LOCATION_GATED_DESTINATIONS[destination_name]
		var path: String = info["path"]
		var btn := ScreenHelpers.make_button(root, destination_name, func(): SceneRouter.goto_scene(path))
		btn.set_meta("requires_type", info["requires_type"])

	for destination_name in FREE_DESTINATIONS.keys():
		var path: String = FREE_DESTINATIONS[destination_name]
		ScreenHelpers.make_button(root, destination_name, func(): SceneRouter.goto_scene(path))

	ScreenHelpers.make_button(root, "Koniec tury »", _on_end_turn_pressed)
	ScreenHelpers.make_button(root, "Zapisz i wyjdź do menu", _on_save_and_exit_pressed)

	_update_status()


func _get_current_background() -> String:
	var region: String = Cities.CITIES.get(Travel.current_city, {}).get("region", "")
	return REGION_BACKGROUNDS.get(region, FALLBACK_BACKGROUND)


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
