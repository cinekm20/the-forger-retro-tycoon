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


func goto_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func goto_hub() -> void:
	goto_scene(HUB)
