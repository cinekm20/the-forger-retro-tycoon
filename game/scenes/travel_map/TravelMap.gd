extends Control
## Mapa świata z klikalnymi pinezkami — osobny ekran, wywoływany z Hubu
## przyciskiem "Jedź »" (patrz GDD.md pkt. 4.9). Wybór celu podróży = tap na
## pinezkę, potem animacja podróży (scenes/travel_animation). UI (tytuł,
## info o podróży, przyciski) w pasku przyklejonym do PRAWEGO DOLNEGO rogu
## (make_root_bottom, ta sama ozdobna ramka co w Hub.gd) — pełnowysokościowy
## pasek z prawej krawędzi (dawne make_root_side) zasłaniał pinezki
## rozrzucone po całej mapie, w tym te blisko prawej krawędzi.

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


func _ready() -> void:
	ScreenHelpers.make_background(self, Cities.MAP_BACKGROUND_PATH)
	_build_pins()

	var root := ScreenHelpers.make_root_bottom(self, true)
	ScreenHelpers.make_title(root, "Dokąd jedziemy?")
	info_label = ScreenHelpers.make_label(root, _default_info_text())
	## autowrap + szerokość ograniczona do wnętrza paska (420 szerokości
	## całego panelu - 2×26 marginesu ramki, patrz make_root_bottom) — bez
	## tego długi tekst (np. "Podróż do Rio de Janeiro: 5.3 dnia
	## (samolotem)") był szerszy niż panel i rozpychał go ponad zamierzone
	## 420px, niespójnie zależnie od nazwy miasta (przegląd czytelności/
	## dopasowania do rozdzielczości na żądanie użytkownika).
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_label.custom_minimum_size = Vector2(360, 0)
	confirm_button = ScreenHelpers.make_button(root, "Jedź »", _on_confirm_pressed)
	cancel_button = ScreenHelpers.make_button(root, "Anuluj", _on_cancel_pressed)
	confirm_button.visible = false
	cancel_button.visible = false
	ScreenHelpers.make_button(root, "« Powrót", func(): SceneRouter.goto_hub())


func _default_info_text() -> String:
	return tr("Jesteś w: %s — dotknij pinezkę celu podróży") % Cities.get_city_name(Travel.current_city)


## Pinezki NIE dostają jednorazowo wyliczonej pozycji w pikselach (`position =
## frac * get_viewport_rect().size`, tak było wcześniej) — to liczy się raz,
## w momencie budowania ekranu, i później się nie przelicza, więc przy każdej
## zmianie rozdzielczości/proporcji okna (albo jeśli w momencie _ready()
## viewport jeszcze nie miał ostatecznego rozmiaru z "stretch/aspect=expand")
## pinezki zostają w miejscu wyliczonym dla STAREGO rozmiaru, a tło (które
## skaluje się przez anchory) już nie — stąd pinezki "uciekają" z właściwych
## miejsc. Zamiast tego każda pinezka dostaje anchor_left=anchor_right=frac.x,
## anchor_top=anchor_bottom=frac.y (jeden punkt zakotwiczenia) + stały,
## pikselowy offset na wielkość PIN_SIZE — layout Godota sam przelicza tę
## pozycję na nowo przy KAŻDEJ zmianie rozmiaru rodzica, tak samo jak robi to
## tło (ScreenHelpers.make_background, STRETCH_SCALE na całym FULL_RECT), więc
## oba zawsze poruszają się razem, niezależnie od rozdzielczości czy momentu
## przeliczenia.
func _build_pins() -> void:
	var pins_layer := Control.new()
	pins_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pins_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(pins_layer)

	for city_id in Cities.CITIES.keys():
		var pin: Button = MapPinScript.new()
		var city_type: String = Cities.CITIES[city_id]["type"]
		pin.pin_color = CURRENT_CITY_PIN_COLOR if city_id == Travel.current_city else TYPE_PIN_COLORS.get(city_type, Color.GRAY)
		var frac: Vector2 = Cities.get_map_position(city_id)
		pin.anchor_left = frac.x
		pin.anchor_right = frac.x
		pin.anchor_top = frac.y
		pin.anchor_bottom = frac.y
		## Zgłoszone przez użytkownika: skalibrowany punkt (frac) ma pokrywać się
		## z KONIUSZKIEM pinezki (ostry czubek na dole grafiki, patrz MapPin.gd
		## _draw — tip = Vector2(w*0.5, size.y)), nie ze środkiem całego
		## prostokąta. W poziomie pinezka zostaje wyśrodkowana (czubek leży na
		## środku szerokości), w pionie offset_bottom=0 przypina sam dół
		## (czubek) dokładnie do punktu zakotwiczenia, a offset_top=-PIN_SIZE.y
		## rozciąga resztę grafiki W GÓRĘ od tego punktu.
		pin.offset_left = -MapPinScript.PIN_SIZE.x / 2.0
		pin.offset_right = MapPinScript.PIN_SIZE.x / 2.0
		pin.offset_top = -MapPinScript.PIN_SIZE.y
		pin.offset_bottom = 0.0
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
	var vehicle_name := tr("pociągiem") if preview["vehicle"] == Travel.Vehicle.TRAIN else tr("samolotem")
	info_label.text = tr("Podróż do %s: %.1f dnia (%s)") % [Cities.get_city_name(city_id), preview["days"], vehicle_name]
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
