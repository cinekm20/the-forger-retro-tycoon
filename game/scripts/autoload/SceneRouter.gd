extends Node
## Centralny router scen, żeby ścieżki .tscn nie były rozrzucone po całym kodzie.

const MAIN_MENU := "res://scenes/main_menu/MainMenu.tscn"
const HUB := "res://scenes/hub/Hub.tscn"
const PLANTATION := "res://scenes/plantation/Plantation.tscn"
const STOCK_MARKET := "res://scenes/stock_market/StockMarket.tscn"
const RACES := "res://scenes/races/Races.tscn"
const AUCTION_HOUSE := "res://scenes/auction_house/AuctionHouse.tscn"
const ART_SCHOOL := "res://scenes/art_school/ArtSchool.tscn"
const GALLERY := "res://scenes/gallery/Gallery.tscn"
const ENDING := "res://scenes/ending/Ending.tscn"
const TRAVEL_MAP := "res://scenes/travel_map/TravelMap.tscn"
const TRAVEL_ANIMATION := "res://scenes/travel_animation/TravelAnimation.tscn"


func goto_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func goto_hub() -> void:
	goto_scene(HUB)


## Jak goto_scene(), ale maskuje samo przełączenie krótką, natychmiastową
## czernią — change_scene_to_file() usuwa starą scenę i buduje nową
## (Hub.gd/TravelMap.gd tworzą sporo UI programistycznie w _ready()), więc
## silnik potrafi wyrenderować klatkę pustego/domyślnego tła między starą
## a nową sceną. Zwykle niezauważalne przy zwykłej nawigacji z menu, ale
## bardzo widoczne jako mrugnięcie, gdy przełączenie kończy płynną animację
## zoom (Hub._on_travel_pressed / TravelAnimation._play_arrival_zoom_in) —
## tam oko śledzi ciągły ruch, więc nawet jedna przerwana klatka rzuca się
## w oczy. Warstwa żyje jako dziecko SceneRouter (autoload), więc przetrwa
## samo usunięcie starej sceny.
func goto_scene_masked(path: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var cover := ColorRect.new()
	cover.color = Color.BLACK
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cover)

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_property(cover, "color:a", 0.0, 0.25)
	await tween.finished
	layer.queue_free()
