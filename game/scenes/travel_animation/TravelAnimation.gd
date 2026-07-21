extends Control
## Krótka animacja podróży — pociąg (podróż w obrębie tego samego regionu)
## albo samolot (inny region, zwykle przez ocean), patrz Travel.gd
## start_travel(). Po zakończeniu (albo po "Pomiń") wraca do Hubu.

const ANIMATION_DURATION := 1.6

const TravelVehicleScript := preload("res://scripts/ui/TravelVehicle.gd")

var vehicle_icon: Control
var finished: bool = false


func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Podróż")
	ScreenHelpers.make_label(root, "%s → %s" % [
		Cities.get_city_name(Travel.last_travel_from), Cities.get_city_name(Travel.last_travel_to),
	])

	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 120)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(track)

	vehicle_icon = TravelVehicleScript.new()
	vehicle_icon.is_plane = Travel.last_travel_vehicle == Travel.Vehicle.PLANE
	vehicle_icon.position = Vector2(-TravelVehicleScript.ICON_SIZE.x, 40)
	track.add_child(vehicle_icon)

	ScreenHelpers.make_button(root, "Pomiń »", _on_finished)

	var viewport_width := get_viewport_rect().size.x
	var tween := create_tween()
	tween.tween_property(vehicle_icon, "position:x", viewport_width, ANIMATION_DURATION)
	tween.finished.connect(_on_finished)


func _on_finished() -> void:
	if finished:
		return
	finished = true
	SceneRouter.goto_hub()
