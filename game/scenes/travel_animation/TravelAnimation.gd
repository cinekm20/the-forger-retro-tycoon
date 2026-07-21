extends Control
## Krótka animacja podróży — pociąg (podróż w obrębie tego samego regionu)
## albo samolot (inny region, zwykle przez ocean), patrz Travel.gd
## start_travel(). Pojazd leci/jedzie bezpośrednio po mapie, od pinezki
## startowej do docelowej (te same współrzędne co na TravelMap,
## Cities.get_map_position) — rośnie tuż po starcie i kurczy się tuż przed
## dotarciem do celu, jak wyjeżdżanie/wjeżdżanie w pinezkę. Po zakończeniu
## (albo po "Pomiń") tło miasta docelowego "wchodzi" (zoom-in) z pozycji
## pinezki na cały ekran, zanim gra przełączy się na Hub — symetryczne
## odbicie zoom-outu z Hub.gd _on_travel_pressed().

const ANIMATION_DURATION := 1.8
const ARRIVAL_ZOOM_DURATION := 0.8
const MIN_VEHICLE_SCALE := 0.25

const TravelVehicleScript := preload("res://scripts/ui/TravelVehicle.gd")
const MapPinScript := preload("res://scripts/ui/MapPin.gd")

var vehicle_icon: Control
var root_panel: VBoxContainer
var map_overlay: ColorRect
var finished: bool = false
var from_pos: Vector2
var to_pos: Vector2


func _ready() -> void:
	var bg_layers := ScreenHelpers.make_background_with_overlay(self, Cities.MAP_BACKGROUND_PATH)
	map_overlay = bg_layers["overlay"]

	root_panel = ScreenHelpers.make_root_side(self)
	ScreenHelpers.make_title(root_panel, "Podróż")
	ScreenHelpers.make_label(root_panel, "%s → %s" % [
		Cities.get_city_name(Travel.last_travel_from), Cities.get_city_name(Travel.last_travel_to),
	])
	ScreenHelpers.make_button(root_panel, "Pomiń »", _on_finished)

	var viewport_size := get_viewport_rect().size
	from_pos = Cities.get_map_position(Travel.last_travel_from) * viewport_size
	to_pos = Cities.get_map_position(Travel.last_travel_to) * viewport_size

	vehicle_icon = TravelVehicleScript.new()
	vehicle_icon.is_plane = Travel.last_travel_vehicle == Travel.Vehicle.PLANE
	vehicle_icon.pivot_offset = TravelVehicleScript.ICON_SIZE / 2.0
	add_child(vehicle_icon)
	move_child(vehicle_icon, 1)  # nad tłem mapy, pod panelem bocznym

	var tween := create_tween()
	tween.tween_method(_update_vehicle, 0.0, 1.0, ANIMATION_DURATION)
	tween.finished.connect(_on_finished)


func _update_vehicle(t: float) -> void:
	var center := from_pos.lerp(to_pos, t)
	vehicle_icon.position = center - TravelVehicleScript.ICON_SIZE / 2.0
	var grow_shrink := sin(t * PI)  # 0 na starcie i mecie, 1 w połowie drogi
	var s: float = lerp(MIN_VEHICLE_SCALE, 1.0, grow_shrink)
	vehicle_icon.scale = Vector2(s, s)


func _on_finished() -> void:
	if finished:
		return
	finished = true
	_play_arrival_zoom_in()


func _play_arrival_zoom_in() -> void:
	vehicle_icon.visible = false
	var viewport_size := get_viewport_rect().size

	var arrival_bg := TextureRect.new()
	arrival_bg.texture = load(Cities.get_region_background(Travel.last_travel_to))
	arrival_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	arrival_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrival_bg.stretch_mode = TextureRect.STRETCH_SCALE
	arrival_bg.pivot_offset = to_pos
	arrival_bg.scale = MapPinScript.PIN_SIZE / viewport_size
	add_child(arrival_bg)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(arrival_bg, "scale", Vector2.ONE, ARRIVAL_ZOOM_DURATION)
	tween.tween_property(map_overlay, "modulate:a", 0.0, ARRIVAL_ZOOM_DURATION)
	tween.tween_property(root_panel, "modulate:a", 0.0, ARRIVAL_ZOOM_DURATION * 0.5)
	tween.chain().tween_callback(func(): SceneRouter.goto_hub())
