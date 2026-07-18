extends Control
## Mapa świata / hub — docelowo zastąpiona właściwą mapą (docs/GRAFIKA_LEONARDO.md
## pkt. 2). Na razie: pasek stanu + nawigacja do wszystkich ekranów.

const DESTINATIONS := {
	"Plantacje": "res://scenes/plantation/Plantation.tscn",
	"Giełda": "res://scenes/stock_market/StockMarket.tscn",
	"Wyścigi konne": "res://scenes/races/Races.tscn",
	"Dom aukcyjny": "res://scenes/auction_house/AuctionHouse.tscn",
	"Szkoła sztuki": "res://scenes/art_school/ArtSchool.tscn",
	"Galeria": "res://scenes/gallery/Gallery.tscn",
}


const DAYS_PER_WEEK_ADVANCE := 7

var status_label: Label


func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "VERMEER — Mapa świata")

	status_label = ScreenHelpers.make_label(root, "")
	_update_status()

	for destination_name in DESTINATIONS.keys():
		var path: String = DESTINATIONS[destination_name]
		ScreenHelpers.make_button(root, destination_name, func(): SceneRouter.goto_scene(path))

	ScreenHelpers.make_button(root, "Tydzień naprzód »", _on_advance_week_pressed)


func _on_advance_week_pressed() -> void:
	Calendar.advance_days(DAYS_PER_WEEK_ADVANCE)
	_update_status()


func _update_status() -> void:
	status_label.text = "Gotówka: %.0f M | Data: %s | Obrazy: %d/40" % [
		Economy.player_money,
		Calendar.get_date_string(),
		Paintings.owned_count(),
	]
