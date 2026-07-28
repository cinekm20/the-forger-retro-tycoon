class_name HeistView
extends Control
## Animowana scena skoku gangstera — zgłoszenie użytkownika: "ataki na
## innych" (SecurityScreen.gd, Security.gd) mają dostać animowaną scenę,
## podobnie jak wyścigi konne (RaceTrackView.gd), zamiast rozstrzygać się od
## razu po kliknięciu przycisku.
##
## KLUCZOWA ZASADA UCZCIWOŚCI: wynik jest znany PRZED zbudowaniem tego widoku
## (SecurityScreen.gd woła Security.resolve_gangster_attempt() i dopiero
## potem setup()) — ta klasa TYLKO wizualizuje już ustalony wynik, dokładnie
## ten sam podział co RaceTrackView. `outcome` to jeden z trzech stanów:
## - "success": gangster dochodzi do celu (rywala), zabiera obraz, ucieka.
## - "failure_caught": gangster nie dochodzi do celu — reflektor ochrony
##   dogania go w drodze, zatrzymuje się złapany (patrz Security.gd
##   CAUGHT_CHANCE_ON_FAILURE/CAUGHT_FINE — dodatkowa grzywna nakładana
##   PRZEZ SecurityScreen.gd po zakończeniu animacji, nie tutaj).
## - "failure_escaped": gangster traci odwagę w połowie drogi i wraca się bez
##   niczego, ale bez złapania.
## Reflektor ochrony przemiata scenę losowo w tle (czysto kosmetyczne
## napięcie) i "namierza" gangstera na stałe TYLKO przy outcome ==
## "failure_caught" — dla pozostałych dwóch wyników nigdy nie zatrzymuje się
## na nim, więc wizualizacja nigdy nie zaprzecza już ustalonemu wynikowi.
##
## Ten sam styl co RaceTrackView.gd/MapPin.gd: proste węzły Control zamiast
## shaderów/customowych tekstur, jawny position/size zamiast anchorów (patrz
## komentarz w RaceTrackView.gd o buncie size=(0,0) przy dodawaniu Control do
## drzewa w trakcie działania gry).

signal finished

const DURATION := 11.0
const EDGE_INSET := 110.0
const GROUND_HEIGHT := 70.0
const GANGSTER_ICON_SIZE := Vector2(72.0, 72.0)
const TARGET_ICON_SIZE := Vector2(100.0, 100.0)

const SUCCESS_REACH_T := 0.55  ## gangster dochodzi do celu
const SUCCESS_RETREAT_START := 0.7  ## zaraz potem zaczyna ucieczkę z łupem
const FAIL_ESCAPE_TURN_T := 0.45  ## gangster traci odwagę i zawraca
const CAUGHT_T := 0.5  ## moment złapania (reflektor "namierza" na stałe)

const ESCAPE_PROGRESS_RANGE := Vector2(0.3, 0.55)  ## jak daleko doszedł, zanim zawrócił bez złapania
const CAUGHT_PROGRESS_RANGE := Vector2(0.5, 0.75)  ## jak daleko doszedł, zanim złapano

const SPOTLIGHT_SIZE := Vector2(160.0, 0.0)  ## wysokość dopełniana do obszaru sceny w _build_visuals
const SPOTLIGHT_SWEEP_SPEED := 0.35  ## przemiatań/s (czysto kosmetyczne, patrz komentarz nagłówkowy)

var view_size: Vector2 = Vector2(1280.0, 720.0)
var start_x: float = 0.0
var target_x: float = 0.0
var lane_y: float = 0.0
var scene_top: float = 0.0
var scene_height: float = 0.0

var outcome: String = "failure_escaped"
var turn_x: float = 0.0  ## dla failure_escaped/failure_caught: x, do którego gangster faktycznie dochodzi

var elapsed: float = 0.0

var gangster_icon: TextureRect
var target_icon: TextureRect
var spotlight: ColorRect
var tension_bar_bg: ColorRect
var tension_bar_fill: ColorRect
var caught_label: Label
var success_label: Label
var skip_button: Button


func _ready() -> void:
	set_process(false)


## Wołane RAZ przez SecurityScreen.gd, zaraz po Security.resolve_gangster_attempt().
func setup(gangster_image_path: String, target_portrait_path: String, result_outcome: String, viewport_size: Vector2) -> void:
	view_size = viewport_size
	outcome = result_outcome
	start_x = EDGE_INSET
	target_x = view_size.x - EDGE_INSET
	scene_top = 0.0
	scene_height = view_size.y - GROUND_HEIGHT
	lane_y = scene_top + scene_height * 0.5

	match outcome:
		"failure_caught":
			turn_x = lerp(start_x, target_x, randf_range(CAUGHT_PROGRESS_RANGE.x, CAUGHT_PROGRESS_RANGE.y))
		"failure_escaped":
			turn_x = lerp(start_x, target_x, randf_range(ESCAPE_PROGRESS_RANGE.x, ESCAPE_PROGRESS_RANGE.y))
		_:
			turn_x = target_x

	_build_visuals(gangster_image_path, target_portrait_path)

	elapsed = 0.0
	set_process(true)


func _build_visuals(gangster_image_path: String, target_portrait_path: String) -> void:
	## Jawny position/size zamiast anchorów — patrz komentarz nagłówkowy i
	## RaceTrackView.gd (ten sam bug ze size=(0,0) przy dodaniu do drzewa w
	## trakcie działania gry, nie przy starcie sceny).
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = Vector2.ZERO
	size = view_size
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.04, 0.08, 1.0)
	backdrop.position = Vector2.ZERO
	backdrop.size = view_size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var ground := ColorRect.new()
	ground.color = Color(0.1, 0.08, 0.06)
	ground.position = Vector2(0.0, view_size.y - GROUND_HEIGHT)
	ground.size = Vector2(view_size.x, GROUND_HEIGHT)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)

	## Reflektor ochrony — przemiata scenę w tle, "namierza" gangstera na
	## stałe tylko przy outcome == "failure_caught" (patrz _update_spotlight).
	spotlight = ColorRect.new()
	spotlight.color = Color(1.0, 1.0, 0.85, 0.12)
	spotlight.size = Vector2(SPOTLIGHT_SIZE.x, scene_height)
	spotlight.position = Vector2(0.0, scene_top)
	spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spotlight)

	target_icon = TextureRect.new()
	target_icon.size = TARGET_ICON_SIZE
	target_icon.position = Vector2(target_x - TARGET_ICON_SIZE.x * 0.5, lane_y - TARGET_ICON_SIZE.y * 0.5)
	target_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	target_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(target_portrait_path):
		target_icon.texture = load(target_portrait_path)
	add_child(target_icon)

	gangster_icon = TextureRect.new()
	gangster_icon.size = GANGSTER_ICON_SIZE
	gangster_icon.pivot_offset = GANGSTER_ICON_SIZE * 0.5
	gangster_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gangster_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gangster_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(gangster_image_path):
		gangster_icon.texture = load(gangster_image_path)
	add_child(gangster_icon)

	## Pasek napięcia — rośnie w miarę zbliżania się gangstera do celu, maleje
	## przy wycofywaniu się (patrz _update_tension_bar) — naturalny wskaźnik
	## "jak blisko", zamiast oderwanego od akcji odliczania czasu.
	tension_bar_bg = ColorRect.new()
	tension_bar_bg.color = Color(0.15, 0.05, 0.05, 0.85)
	tension_bar_bg.size = Vector2(view_size.x * 0.5, 14.0)
	tension_bar_bg.position = Vector2(view_size.x * 0.25, 24.0)
	tension_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tension_bar_bg)

	tension_bar_fill = ColorRect.new()
	tension_bar_fill.color = ScreenHelpers.COLOR_GOLD_BRIGHT
	tension_bar_fill.size = Vector2(0.0, tension_bar_bg.size.y)
	tension_bar_fill.position = tension_bar_bg.position
	tension_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tension_bar_fill)

	caught_label = Label.new()
	caught_label.text = tr("Złapany!")
	caught_label.add_theme_font_size_override("font_size", 22)
	caught_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	caught_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	caught_label.add_theme_constant_override("shadow_offset_x", 1)
	caught_label.add_theme_constant_override("shadow_offset_y", 1)
	caught_label.visible = false
	caught_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caught_label)

	success_label = Label.new()
	success_label.text = tr("Zdobyty!")
	success_label.add_theme_font_size_override("font_size", 22)
	success_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
	success_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	success_label.add_theme_constant_override("shadow_offset_x", 1)
	success_label.add_theme_constant_override("shadow_offset_y", 1)
	success_label.visible = false
	success_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(success_label)

	skip_button = Button.new()
	skip_button.text = tr("Pomiń »")
	skip_button.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	skip_button.pressed.connect(skip)
	skip_button.size = Vector2(130.0, 40.0)
	skip_button.position = Vector2(view_size.x - 150.0, view_size.y - 56.0)
	add_child(skip_button)


func _process(delta: float) -> void:
	elapsed += delta
	var t: float = clampf(elapsed / DURATION, 0.0, 1.0)
	_update_gangster(t)
	_update_spotlight(t)
	if t >= 1.0:
		set_process(false)
		finished.emit()


## Przycisk "Pomiń" — od razu przeskakuje na koniec sceny (ostatnia klatka
## _process ustawia stan finałowy i emituje finished), ten sam patent co
## RaceTrackView.gd::skip().
func skip() -> void:
	if not is_processing():
		return
	elapsed = DURATION
	_process(0.0)


## Pozycja pozioma gangstera w chwili t — trzy różne kształty ruchu wg
## outcome, WYŁĄCZNIE jako wizualizacja już ustalonego wyniku (patrz
## komentarz nagłówkowy). Wszystkie trzy używają smoothstep dla płynności.
func _gangster_x(t: float) -> float:
	match outcome:
		"success":
			if t < SUCCESS_REACH_T:
				return lerp(start_x, target_x, smoothstep(0.0, 1.0, t / SUCCESS_REACH_T))
			elif t < SUCCESS_RETREAT_START:
				return target_x
			else:
				var local_t := (t - SUCCESS_RETREAT_START) / (1.0 - SUCCESS_RETREAT_START)
				return lerp(target_x, start_x - 60.0, smoothstep(0.0, 1.0, local_t))
		"failure_caught":
			if t < CAUGHT_T:
				return lerp(start_x, turn_x, smoothstep(0.0, 1.0, t / CAUGHT_T))
			else:
				return turn_x
		_:  # "failure_escaped"
			if t < FAIL_ESCAPE_TURN_T:
				return lerp(start_x, turn_x, smoothstep(0.0, 1.0, t / FAIL_ESCAPE_TURN_T))
			else:
				var local_t := (t - FAIL_ESCAPE_TURN_T) / (1.0 - FAIL_ESCAPE_TURN_T)
				return lerp(turn_x, start_x - 60.0, smoothstep(0.0, 1.0, local_t))


func _update_gangster(t: float) -> void:
	var x := _gangster_x(t)
	gangster_icon.position = Vector2(x - GANGSTER_ICON_SIZE.x * 0.5, lane_y - GANGSTER_ICON_SIZE.y * 0.5)
	_update_tension_bar(x)

	var frozen := (outcome == "failure_caught" and t >= CAUGHT_T) or (outcome == "success" and t >= SUCCESS_RETREAT_START)
	gangster_icon.rotation = 0.0 if frozen else deg_to_rad(sin(t * 30.0) * 4.0)

	if outcome == "failure_caught" and t >= CAUGHT_T:
		caught_label.visible = true
		caught_label.position = Vector2(x - 40.0, lane_y - GANGSTER_ICON_SIZE.y * 0.5 - 30.0)
	if outcome == "success" and t >= SUCCESS_REACH_T and t < SUCCESS_RETREAT_START:
		success_label.visible = true
		success_label.position = Vector2(target_x - 40.0, lane_y - TARGET_ICON_SIZE.y * 0.5 - 30.0)


## Napięcie = jak blisko celu jest gangster w danej chwili (0 przy starcie,
## 1 dokładnie na celu) — rośnie w drodze tam, maleje przy ucieczce, zamiast
## oderwanego od akcji odliczania czasu.
func _update_tension_bar(gangster_x: float) -> void:
	var progress := clampf((gangster_x - start_x) / (target_x - start_x), 0.0, 1.0)
	tension_bar_fill.size.x = tension_bar_bg.size.x * progress


## Reflektor ochrony — swobodne przemiatanie sceny (czysto kosmetyczne
## napięcie), ale przy outcome == "failure_caught" od CAUGHT_T zbiega się na
## stałe na pozycji gangstera (dramatyczne "złapanie w światło"), nigdy dla
## pozostałych dwóch wyników — patrz komentarz nagłówkowy o uczciwości.
func _update_spotlight(t: float) -> void:
	if outcome == "failure_caught" and t >= CAUGHT_T:
		spotlight.position.x = turn_x - SPOTLIGHT_SIZE.x * 0.5
		spotlight.color.a = 0.28
		return
	var sweep := (sin(elapsed * TAU * SPOTLIGHT_SWEEP_SPEED) + 1.0) * 0.5
	spotlight.position.x = lerp(0.0, view_size.x - SPOTLIGHT_SIZE.x, sweep)
	spotlight.color.a = 0.12
