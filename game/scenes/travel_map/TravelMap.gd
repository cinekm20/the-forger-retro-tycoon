extends Control
## Mapa świata z klikalnymi pinezkami — osobny ekran, wywoływany z Hubu
## przyciskiem "Jedź »" (patrz GDD.md pkt. 4.9). Wybór celu podróży = tap na
## pinezkę, potem animacja podróży (scenes/travel_animation).

const TYPE_PIN_COLORS := {
	"plantation": Color(0.85, 0.65, 0.2),
	"auction": Color(0.55, 0.1, 0.15),
	"hub": Color(0.1, 0.55, 0.55),
}
const CURRENT_CITY_PIN_COLOR := Color(1.0, 1.0, 1.0)

const MapPinScript := preload("res://scripts/ui/MapPin.gd")

var info_label: Label


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/hub_map.jpg")
	_build_pins()

	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Dokąd jedziemy?")
	info_label = ScreenHelpers.make_label(root, "Jesteś w: %s — dotknij pinezkę celu podróży" % Cities.get_city_name(Travel.current_city))
	ScreenHelpers.make_button(root, "« Powrót", func(): SceneRouter.goto_hub())


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
	if Travel.start_travel(city_id):
		SceneRouter.goto_scene(SceneRouter.TRAVEL_ANIMATION)
