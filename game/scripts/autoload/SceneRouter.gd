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


var _fade_cover: ColorRect

## Leniwie tworzy (raz, na cały czas gry) pełnoekranowy czarny prostokąt w
## CanvasLayer należącym do tego autoloadu — dzięki temu przetrwa
## change_scene_to_file() (usuwa tylko drzewo AKTUALNEJ sceny, nie dzieci
## autoloadów). Zwrócony węzeł ma animować SAM wywołujący kod, jako część
## WŁASNEGO tweena zoom (patrz Hub._on_travel_pressed/
## TravelAnimation._play_arrival_zoom_in) — nagłe cover.color.a = 1 tuż przed
## przełączeniem sceny dawałoby dokładnie to samo mrugnięcie/"blink", którego
## unikamy; przyciemnienie musi być płynne i zsynchronizowane z KOŃCEM
## animacji, nie osobnym, nagłym cięciem.
func get_fade_cover() -> ColorRect:
	if _fade_cover == null:
		var layer := CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		_fade_cover = ColorRect.new()
		_fade_cover.color = Color(0, 0, 0, 0)
		_fade_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_fade_cover)
	return _fade_cover


## Wołać, gdy ekran jest już w pełni przykryty przez get_fade_cover()
## (color:a == 1). change_scene_to_file() usuwa starą scenę i buduje nową
## (Hub.gd/TravelMap.gd tworzą sporo UI programistycznie w _ready()), więc
## silnik potrafi wyrenderować klatkę pustego tła między starą a nową sceną
## — stąd dwie klatki odczekane PRZED wygaszeniem przykrycia, żeby dać
## nowej scenie czas na pierwszy pełny _ready() + narysowaną klatkę.
func goto_scene_after_fade(path: String) -> void:
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_fade_cover, "color:a", 0.0, 0.3)
