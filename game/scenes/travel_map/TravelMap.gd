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
var confirm_button: Button
var cancel_button: Button
var selected_city: String = ""

## Wejście na mapę jest tylko przez "Jedź »" na Hubie i kończy się albo
## wyborem celu, albo "Anuluj" — świadomie bez stałego przycisku "Powrót",
## żeby nie zasłaniał pinezek i nie dublował się z "Anuluj" (patrz też
## screen_helpers.make_back_button, który teraz wraca do Huba, a nie mapy).
func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/hub_map.jpg")
	_build_pins()

	var root := ScreenHelpers.make_root_bottom(self)
	ScreenHelpers.make_title(root, "Dokąd jedziemy?")
	info_label = ScreenHelpers.make_label(root, _default_info_text())
	confirm_button = ScreenHelpers.make_button(root, "Jedź »", _on_confirm_pressed)
	cancel_button = ScreenHelpers.make_button(root, "Anuluj", _on_cancel_pressed)
	confirm_button.visible = false
	cancel_button.visible = false


func _default_info_text() -> String:
	return "Jesteś w: %s — dotknij pinezkę celu podróży" % Cities.get_city_name(Travel.current_city)


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
		pin.pressed.connect(_on_pin_selected.bind(city_id))
		pins_layer.add_child(pin)


## Kliknięcie pinezki tylko zaznacza cel i pokazuje czas podróży — nie
## rusza od razu (wcześniej robiło, co myliło graczy: "kliknę i już jadę").
## Rozpoczęcie podróży wymaga potwierdzenia przyciskiem "Jedź »".
func _on_pin_selected(city_id: String) -> void:
	if city_id == Travel.current_city:
		return
	var preview := Travel.preview_travel(city_id)
	if preview.is_empty():
		return
	selected_city = city_id
	var vehicle_name := "pociągiem" if preview["vehicle"] == Travel.Vehicle.TRAIN else "samolotem"
	info_label.text = "Podróż do %s: %.1f dnia (%s)" % [Cities.get_city_name(city_id), preview["days"], vehicle_name]
	confirm_button.visible = true
	cancel_button.visible = true


func _on_confirm_pressed() -> void:
	if selected_city != "" and Travel.start_travel(selected_city):
		SceneRouter.goto_scene(SceneRouter.TRAVEL_ANIMATION)


func _on_cancel_pressed() -> void:
	selected_city = ""
	info_label.text = _default_info_text()
	confirm_button.visible = false
	cancel_button.visible = false
