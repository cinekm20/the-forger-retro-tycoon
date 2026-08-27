extends Node
## Centralny router scen, żeby ścieżki .tscn nie były rozrzucone po całym kodzie.

const MAIN_MENU := "res://scenes/main_menu/MainMenu.tscn"
const HUB := "res://scenes/hub/Hub.tscn"
const PLANTATION := "res://scenes/plantation/Plantation.tscn"
const WAREHOUSE := "res://scenes/warehouse/Warehouse.tscn"
const STOCK_MARKET := "res://scenes/stock_market/StockMarket.tscn"
const MARKET := "res://scenes/market/Market.tscn"
const RACES := "res://scenes/races/Races.tscn"
const AUCTION_HOUSE := "res://scenes/auction_house/AuctionHouse.tscn"
const ART_SCHOOL := "res://scenes/art_school/ArtSchool.tscn"
const GALLERY := "res://scenes/gallery/Gallery.tscn"
const SECURITY := "res://scenes/security/SecurityScreen.tscn"
const ENDING := "res://scenes/ending/Ending.tscn"
const TRAVEL_MAP := "res://scenes/travel_map/TravelMap.tscn"
const TRAVEL_ANIMATION := "res://scenes/travel_animation/TravelAnimation.tscn"
const SETTINGS := "res://scenes/settings/Settings.tscn"
const INSTRUCTIONS := "res://scenes/instructions/Instructions.tscn"
const YEAR_SUMMARY := "res://scenes/year_summary/YearSummary.tscn"
const WORLD_EVENT := "res://scenes/world_event/WorldEventCard.tscn"
const NEW_YEAR_LOTTERY := "res://scenes/new_year_lottery/NewYearLottery.tscn"


func goto_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func goto_hub() -> void:
	goto_scene(HUB)


var _snapshot_layer: CanvasLayer
var _snapshot_rect: TextureRect


func _get_snapshot_rect() -> TextureRect:
	if _snapshot_layer == null:
		_snapshot_layer = CanvasLayer.new()
		_snapshot_layer.layer = 100
		add_child(_snapshot_layer)
		_snapshot_rect = TextureRect.new()
		_snapshot_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_snapshot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_snapshot_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_snapshot_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_snapshot_rect.visible = false
		_snapshot_layer.add_child(_snapshot_rect)
	return _snapshot_rect


## Jak goto_scene(), ale bez mrugnięcia/czerni: zamiast przyciemniać ekran,
## robi zrzut DOKŁADNIE tej klatki, którą właśnie widać (czyli ostatniej
## klatki animacji zoom w Hub.gd/TravelAnimation.gd) i pokazuje go jako
## nieruchomy obrazek NAD wszystkim, w CanvasLayer należącym do tego
## autoloadu (więc przetrwa change_scene_to_file(), który usuwa tylko
## drzewo aktualnej sceny). Pod tym zamrożonym zrzutem silnik w spokoju
## usuwa starą scenę i buduje nową (Hub.gd/TravelMap.gd tworzą sporo UI
## programistycznie w _ready(), stąd dwie klatki odczekane na pierwszy
## pełny _ready() + narysowaną klatkę) — dopiero potem zrzut płynnie
## znika, odsłaniając nową scenę. Koniec animacji zoom i początek kolejnej
## sceny z założenia wyglądają niemal identycznie (to samo tło, ta sama
## nakładka), więc przejście wychodzi jako płynne pojawienie się, a nie
## cięcie do czerni.
func goto_scene_crossfade(path: String) -> void:
	var snapshot := _get_snapshot_rect()
	var img := get_viewport().get_texture().get_image()
	snapshot.texture = ImageTexture.create_from_image(img)
	snapshot.modulate.a = 1.0
	snapshot.visible = true

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_property(snapshot, "modulate:a", 0.0, 0.3)
	await tween.finished
	snapshot.visible = false
