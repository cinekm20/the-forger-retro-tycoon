extends Control
## Mapa świata z klikalnymi pinezkami — osobny ekran, wywoływany z Hubu
## przyciskiem "Jedź »" (patrz GDD.md pkt. 4.9). Wybór celu podróży = tap na
## pinezkę, potem animacja podróży (scenes/travel_animation). UI (tytuł,
## info o podróży, przyciski) w pasku przyklejonym do PRAWEGO DOLNEGO rogu
## (make_root_bottom, ta sama ozdobna ramka co w Hub.gd) — pełnowysokościowy
## pasek z prawej krawędzi (dawne make_root_side) zasłaniał pinezki
## rozrzucone po całej mapie, w tym te blisko prawej krawędzi.
##
## Zgłoszenie użytkownika: samą mapę (tło + pinezki) da się przybliżać
## (uszczypnięcie na dotyku/kółko myszy) i przesuwać (przeciąganie), a
## pinezki przy tym trochę się powiększają (nie 1:1 z zoomem mapy — patrz
## PIN_ZOOM_DAMPING) i ZOSTAJĄ na dokładnie tych samych, skalibrowanych
## miejscach. Architektura: map_content (tło + warstwa pinezek) dostaje
## `scale`/`position` sterowane przez _apply_zoom/_apply_pan zamiast
## anchorów świata-do-ekranu — to WEWNĄTRZ map_content pinezki nadal są
## anchor-owane fakturą (frac.x/frac.y) tak jak wcześniej, więc automatycznie
## poruszają się/skalują RAZEM z tłem (są jego potomkiem), niezależnie od
## aktualnego zoomu/panu. Każda pinezka dostaje DODATKOWO WŁASNE `scale`,
## które DZIELI docelowy (stonowany) rozmiar przez bieżący zoom mapy — to
## KASUJE odziedziczoną skalę rodzica i zastępuje ją stonowaną, więc pinezki
## rosną WOLNIEJ niż sama mapa (patrz _update_pin_scale). `pivot_offset`
## każdej pinezki ustawiony na jej koniuszek (ten sam punkt, który wcześniej
## dostawał offset_bottom=0 — patrz komentarz w _build_pins) — skalowanie
## wokół koniuszka, nie środka pinezki, jest KONIECZNE, żeby koniuszek został
## dokładnie na skalibrowanym miejscu niezależnie od tego, jak bardzo pinezka
## akurat urosła.

const TYPE_PIN_COLORS := {
	"plantation": Color(0.85, 0.65, 0.2),
	"auction": Color(0.55, 0.1, 0.15),
	"hub": Color(0.1, 0.55, 0.55),
}
const CURRENT_CITY_PIN_COLOR := Color(1.0, 1.0, 1.0)

const MapPinScript := preload("res://scripts/ui/MapPin.gd")

const MIN_ZOOM := 1.0
const MAX_ZOOM := 2.5
## Pinezki rosną WOLNIEJ niż mapa — przy MAX_ZOOM mapa jest 2.5× większa, ale
## pinezki tylko ok. 1.5× (1.0 + 1.5*0.35 ≈ 1.53) — zgłoszenie użytkownika:
## "trochę powiększały się pinezki", nie tyle samo co mapa (co przy dużym
## zoomie zamieniłoby je w nieczytelne plamy).
const PIN_ZOOM_DAMPING := 0.35
const WHEEL_ZOOM_STEP := 0.15  ## na jedno kliknięcie kółka myszy (test/desktop)

var info_label: Label
var confirm_button: Button
var cancel_button: Button
var selected_city: String = ""

var map_viewport: Control
var map_content: Control
var pins: Array[Button] = []
var zoom: float = MIN_ZOOM


func _ready() -> void:
	_build_map(Cities.MAP_BACKGROUND_PATH)
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


## map_viewport: pełnoekranowy, NIERUCHOMY kontener, wycina (clip_contents)
## wszystko, co przy zoomie/panie wystaje poza ekran — jego WŁASNY `_gui_input`
## odbiera gesty uszczypnięcia/przeciągnięcia/kółka myszy (patrz niżej).
## map_content: to, co faktycznie się skaluje/przesuwa (`scale`/`position`) —
## tło + warstwa pinezek jako jego dzieci, więc poruszają się/skalują RAZEM.
func _build_map(background_path: String) -> void:
	map_viewport = Control.new()
	map_viewport.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_viewport.clip_contents = true
	map_viewport.mouse_filter = Control.MOUSE_FILTER_PASS
	map_viewport.gui_input.connect(_on_map_gui_input)
	add_child(map_viewport)

	map_content = Control.new()
	map_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_content.mouse_filter = Control.MOUSE_FILTER_PASS
	map_viewport.add_child(map_content)

	var bg := TextureRect.new()
	bg.texture = load(background_path)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_content.add_child(bg)


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
## pozycję na nowo przy KAŻDEJ zmianie rozmiaru rodzica (map_content), tak
## samo jak robi to tło, więc oba zawsze poruszają się razem, niezależnie od
## rozdzielczości, momentu przeliczenia CZY aktualnego zoomu/panu mapy.
func _build_pins() -> void:
	var pins_layer := Control.new()
	pins_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pins_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	map_content.add_child(pins_layer)

	pins.clear()
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
		## pivot_offset = koniuszek — pinezka rośnie/maleje (patrz
		## _update_pin_scale) WOKÓŁ tego punktu, więc koniuszek zostaje
		## dokładnie na skalibrowanym miejscu niezależnie od aktualnej skali.
		pin.pivot_offset = Vector2(MapPinScript.PIN_SIZE.x * 0.5, MapPinScript.PIN_SIZE.y)
		pin.tooltip_text = Cities.get_city_name(city_id)
		pin.pressed.connect(_on_pin_selected.bind(city_id))
		pins_layer.add_child(pin)
		pins.append(pin)


## Obsługuje: uszczypnięcie (InputEventMagnifyGesture), przeciąganie dwoma
## palcami (InputEventPanGesture), kółko myszy (zoom, desktop/test) i
## przeciąganie lewym przyciskiem/palcem (pan). Zoom zawsze wokół pozycji
## gestu/kursora (_apply_zoom), więc mapa "przybliża się w to miejsce, gdzie
## uszczypnięto", nie zawsze do środka ekranu.
func _on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_apply_zoom(zoom * event.factor, event.position)
	elif event is InputEventPanGesture:
		_apply_pan(-event.delta)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_apply_zoom(zoom + WHEEL_ZOOM_STEP, event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_apply_zoom(zoom - WHEEL_ZOOM_STEP, event.position)
	elif event is InputEventScreenDrag:
		_apply_pan(event.relative)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_apply_pan(event.relative)


## Zmienia zoom, zachowując POD KURSOREM/PALCEM (`focal`, we współrzędnych
## map_viewport) ten sam punkt mapy co przed zmianą — standardowa transformata
## "zoom do punktu": najpierw liczymy, na jaki punkt WEWNĄTRZ map_content
## (sprzed zmiany skali) wskazuje `focal`, potem dobieramy nową pozycję tak,
## żeby DOKŁADNIE ten sam punkt mapy znów wypadł pod `focal` po zmianie skali.
func _apply_zoom(new_zoom: float, focal: Vector2) -> void:
	new_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(new_zoom, zoom):
		return
	var local_point := (focal - map_content.position) / zoom
	zoom = new_zoom
	map_content.position = focal - local_point * zoom
	map_content.scale = Vector2(zoom, zoom)
	_clamp_pan()
	_update_pin_scale()


func _apply_pan(delta: Vector2) -> void:
	if zoom <= MIN_ZOOM:
		return  ## bez sensu przesuwać, gdy mapa i tak dokładnie wypełnia ekran
	map_content.position += delta
	_clamp_pan()


## Nie pozwala odsłonić pustego marginesu poza teksturą tła — powiększona
## treść (rozmiar = rozmiar viewportu * zoom) zawsze musi w pełni pokrywać
## map_viewport, więc pozycja jest zaciśnięta do przedziału [viewport - treść, 0]
## w obu osiach (przy zoom=1.0 oba krańce wynoszą 0, więc pozycja zawsze
## wraca dokładnie do (0,0) — panowanie bez przybliżenia nie ma efektu, patrz
## _apply_pan wyżej).
func _clamp_pan() -> void:
	var viewport_size := map_viewport.size
	var content_size := viewport_size * zoom
	var min_pos := viewport_size - content_size
	map_content.position.x = clampf(map_content.position.x, min_pos.x, 0.0)
	map_content.position.y = clampf(map_content.position.y, min_pos.y, 0.0)


## Każda pinezka dostaje WŁASNE `scale`, które DZIELI stonowany docelowy
## rozmiar przez bieżący zoom mapy — pinezka jest potomkiem map_content, więc
## automatycznie ODZIEDZICZA jego skalę (zoom); dzielenie przez `zoom` znosi
## tę odziedziczoną skalę i zastępuje ją stonowaną, więc finalny, widoczny
## rozmiar pinezki na ekranie to DOKŁADNIE `target_scale`, niezależnie od
## aktualnego zoomu mapy.
func _update_pin_scale() -> void:
	var target_scale := 1.0 + (zoom - MIN_ZOOM) * PIN_ZOOM_DAMPING
	var compensated := target_scale / zoom
	for pin in pins:
		pin.scale = Vector2(compensated, compensated)


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
