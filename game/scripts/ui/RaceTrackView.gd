class_name RaceTrackView
extends Control
## Animowany tor wyścigowy — przewijane banery reklamowe u góry, przewijana
## trawa u dołu, konie (reużyte portrety Horses.HORSES) faktycznie biegnące
## od PRAWEJ (biała linia startu) do LEWEJ (biało-czerwona linia mety).
## Zgłoszenie użytkownika: start na białej linii z prawej, bieg w lewo do
## mety, każdy koń po przekroczeniu mety dostaje podpis z miejscem i nazwą.
## Wynik nie może być oczywisty od razu, wyścig ma trwać min. 30 sekund.
##
## KLUCZOWA ZASADA UCZCIWOŚCI: zwycięzca jest znany PRZED zbudowaniem tego
## widoku (Races.gd woła _pick_winner_index() i dopiero potem setup()) — ta
## klasa TYLKO wizualizuje już ustalony wynik. Każdy koń dostaje WŁASNY
## moment przekroczenia mety t_cross[i] (ułamek DURATION) — zwycięzca
## dostaje NAJMNIEJSZĄ wartość ze wszystkich, więc zawsze przybiega
## pierwszy, niezależnie od tego, jak wygląda bieg po drodze. Między startem
## a swoim t_cross[i] koń porusza się wg krzywej potęgowej o losowym
## wykładniku (kilka koni "wychodzi szybko i zwalnia", inne "goni na
## finiszu") — to daje realne, organiczne zmiany prowadzenia (który koń jest
## FIZYCZNIE bliżej mety w danej chwili), bez potrzeby cofania konia. Jeden
## losowy NIE-zwycięski koń może dodatkowo dostać "kontuzję" (tymczasowy,
## zanikający dołek WSTECZ na jego własnej krzywej, zawsze bezpiecznie przed
## jego własnym t_cross[i]) — bezpieczne dla uczciwości wyniku.
##
## Brak shaderów/customowych tekstur do przewijania (ten sam styl co
## MapPin.gd/TravelVehicle.gd — proste węzły Control zamiast grafiki) —
## banery/trawa to po prostu pula ColorRect/Label kafelków, repozycjonowana
## co klatkę wg wzoru fposmod(slot - scroll, total_width), standardowy trik
## na nieskończone przewijanie bez utraty ciągłości na krawędzi.

signal finished

const DURATION := 32.0
const BANNER_HEIGHT := 70.0
const GROUND_HEIGHT := 60.0
const HORSE_ICON_SIZE := Vector2(60.0, 60.0)
const EDGE_INSET := 90.0  ## odstęp linii startu/mety od krawędzi ekranu

const WINNER_CROSS_RANGE := Vector2(0.55, 0.75)  ## kiedy (ułamek DURATION) zwycięzca dobiega do mety
const OTHER_CROSS_MARGIN := 0.05  ## pozostali muszą przekroczyć metę PÓŹNIEJ niż zwycięzca o co najmniej tyle
const OTHER_CROSS_MAX := 0.98  ## nigdy dokładnie 1.0 — każdy zdąży dobiec i pokazać podpis przed końcem animacji
const POWER_RANGE := Vector2(0.6, 1.6)  ## <1: szybki start i zwolnienie, >1: wolny start i final. sprint

const INJURY_CHANCE := 0.25
const INJURY_DEPTH := 90.0  ## px, tymczasowe cofnięcie (w stronę startu) podczas kontuzji
const INJURY_WIDTH := 0.06  ## "szerokość" dołka w jednostkach t
const INJURY_CENTER_FRACTION_RANGE := Vector2(0.3, 0.6)  ## ułamek WŁASNEGO t_cross[i] konia

const BANNER_TEXTS := ["CYGARA CYKLON", "BANK FALKENSTEIN", "PIWO GROM", "PERFUMY COLOMBO", "HOTEL ASHCOMBE"]
const BANNER_CARD_WIDTH := 200.0
const BANNER_GAP := 24.0
const BANNER_SCROLL_SPEED := 90.0  ## px/s

const GROUND_DASH_WIDTH := 10.0
const GROUND_DASH_GAP := 50.0
const GROUND_SCROLL_SPEED := 160.0  ## szybciej niż banery = wrażenie głębi (paralaksa)

const LINE_WIDTH := 16.0

var view_size: Vector2 = Vector2(1280.0, 720.0)
var start_x: float = 0.0
var finish_x: float = 0.0
var lane_height: float = 100.0

var horse_image_paths: Array[String] = []
var horse_names: Array[String] = []
var winner_index: int = -1
var t_cross: Array[float] = []
var powers: Array[float] = []
var places: Array[int] = []  ## places[i] = 1-indeksowane miejsce konia i (wg t_cross rosnąco)
var injury_horse_index: int = -1
var injury_center: float = 0.0

var elapsed: float = 0.0
var banner_scroll_x: float = 0.0
var ground_scroll_x: float = 0.0
var crossed: Array[bool] = []

var banner_cards: Array[ColorRect] = []
var banner_labels: Array[Label] = []
var ground_dashes: Array[ColorRect] = []
var horse_icons: Array[TextureRect] = []
var place_labels: Array[Label] = []
var start_line: Control
var finish_line: Control
var injury_label: Label
var skip_button: Button


func _ready() -> void:
	set_process(false)


## Wołane RAZ przez Races.gd, zaraz po ustaleniu zwycięzcy — image_paths/
## names w TEJ SAMEJ kolejności co horse_ids/horse_option w Races.gd, więc
## winner_idx/chosen_idx (przekazywane z powrotem przez `finished` w
## Races.gd, bind-owane po stronie wywołującego) trafiają w ten sam koń.
func setup(image_paths: Array[String], names: Array[String], winner_idx: int, viewport_size: Vector2) -> void:
	horse_image_paths = image_paths
	horse_names = names
	winner_index = winner_idx
	view_size = viewport_size
	start_x = view_size.x - EDGE_INSET
	finish_x = EDGE_INSET
	lane_height = (view_size.y - BANNER_HEIGHT - GROUND_HEIGHT) / float(horse_image_paths.size())

	_generate_curves()
	_build_visuals()

	elapsed = 0.0
	set_process(true)


func _generate_curves() -> void:
	t_cross.clear()
	powers.clear()
	crossed.clear()
	var count := horse_image_paths.size()
	t_cross.resize(count)
	powers.resize(count)

	t_cross[winner_index] = randf_range(WINNER_CROSS_RANGE.x, WINNER_CROSS_RANGE.y)
	for i in count:
		if i != winner_index:
			t_cross[i] = randf_range(t_cross[winner_index] + OTHER_CROSS_MARGIN, OTHER_CROSS_MAX)
		powers[i] = randf_range(POWER_RANGE.x, POWER_RANGE.y)
		crossed.append(false)

	## Miejsca 1..N wg rosnącego t_cross (zwycięzca ma najmniejszy, więc
	## zawsze miejsce 1. — matematycznie gwarantowane, nie tylko losowo).
	var order: Array[int] = []
	for i in count:
		order.append(i)
	order.sort_custom(func(a, b): return t_cross[a] < t_cross[b])
	places.resize(count)
	for rank in order.size():
		places[order[rank]] = rank + 1

	injury_horse_index = -1
	if randf() < INJURY_CHANCE:
		var candidates: Array[int] = []
		for i in count:
			if i != winner_index:
				candidates.append(i)
		if not candidates.is_empty():
			injury_horse_index = candidates[randi() % candidates.size()]
			var frac := randf_range(INJURY_CENTER_FRACTION_RANGE.x, INJURY_CENTER_FRACTION_RANGE.y)
			injury_center = t_cross[injury_horse_index] * frac


func _build_visuals() -> void:
	## Zgłoszenie użytkownika (ze zrzutem ekranu): tło/banery/trawa w ogóle
	## się nie pokazywały, tylko ikony koni na wierzchu oryginalnego ekranu —
	## zweryfikowane debugowaniem (Godot headless + Xvfb): `self` dodane do
	## drzewa w trakcie działania gry (nie przy starcie sceny) miało
	## size=(0,0) MIMO set_anchors_preset(FULL_RECT). Zamiast anchorów: JAWNY,
	## stały rozmiar/pozycja na podstawie viewport_size przekazanego z
	## Races.gd — niezawodne niezależnie od tego, kiedy węzeł trafia do drzewa.
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = Vector2.ZERO
	size = view_size
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.07, 0.05, 1.0)
	backdrop.position = Vector2.ZERO
	backdrop.size = view_size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_build_banner_strip()
	_build_ground_strip()
	_build_start_line()
	_build_finish_line()
	_build_horses()
	_build_injury_label()
	_build_skip_button()


func _build_banner_strip() -> void:
	var strip := Control.new()
	strip.position = Vector2.ZERO
	strip.size = Vector2(view_size.x, BANNER_HEIGHT)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.clip_contents = true
	add_child(strip)

	var strip_bg := ColorRect.new()
	strip_bg.color = Color(0.15, 0.1, 0.06)
	strip_bg.position = Vector2.ZERO
	strip_bg.size = strip.size
	strip_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(strip_bg)

	var pattern_width := BANNER_CARD_WIDTH + BANNER_GAP
	var card_count := int(ceil(view_size.x / pattern_width)) + 2
	for i in card_count:
		var card := ColorRect.new()
		card.color = Color(0.55, 0.4, 0.15)
		card.size = Vector2(BANNER_CARD_WIDTH, BANNER_HEIGHT * 0.7)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(card)
		banner_cards.append(card)

		var label := Label.new()
		label.text = tr(BANNER_TEXTS[i % BANNER_TEXTS.size()])
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = card.size
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(label)
		banner_labels.append(label)


func _build_ground_strip() -> void:
	var strip := Control.new()
	strip.position = Vector2(0.0, view_size.y - GROUND_HEIGHT)
	strip.size = Vector2(view_size.x, GROUND_HEIGHT)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.clip_contents = true
	add_child(strip)

	var strip_bg := ColorRect.new()
	strip_bg.color = Color(0.16, 0.32, 0.14)
	strip_bg.position = Vector2.ZERO
	strip_bg.size = strip.size
	strip_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(strip_bg)

	var pattern_width := GROUND_DASH_WIDTH + GROUND_DASH_GAP
	var dash_count := int(ceil(view_size.x / pattern_width)) + 2
	for i in dash_count:
		var dash := ColorRect.new()
		dash.color = Color(0.1, 0.22, 0.09)
		dash.size = Vector2(GROUND_DASH_WIDTH, GROUND_HEIGHT * 0.6)
		dash.position.y = GROUND_HEIGHT * 0.2
		dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(dash)
		ground_dashes.append(dash)


## Linia startu — jednolita biała, NIERUCHOMA przez cały wyścig (konie
## faktycznie od niej odjeżdżają, w przeciwieństwie do mety, która stoi w
## miejscu i czeka na nie — patrz _build_finish_line).
func _build_start_line() -> void:
	start_line = Control.new()
	start_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_line.size = Vector2(LINE_WIDTH, view_size.y - BANNER_HEIGHT - GROUND_HEIGHT)
	start_line.position = Vector2(start_x - LINE_WIDTH * 0.5, BANNER_HEIGHT)
	add_child(start_line)

	var bar := ColorRect.new()
	bar.color = Color.WHITE
	bar.size = start_line.size
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_line.add_child(bar)


## Linia mety — biało-czerwona w kratkę, NIERUCHOMA (konie do niej dobiegają,
## nie odwrotnie).
func _build_finish_line() -> void:
	finish_line = Control.new()
	finish_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish_line.size = Vector2(LINE_WIDTH, view_size.y - BANNER_HEIGHT - GROUND_HEIGHT)
	finish_line.position = Vector2(finish_x - LINE_WIDTH * 0.5, BANNER_HEIGHT)
	add_child(finish_line)

	var segment_count := 8
	var segment_height := finish_line.size.y / float(segment_count)
	for s in segment_count:
		var seg := ColorRect.new()
		seg.color = Color.WHITE if s % 2 == 0 else Color(0.75, 0.1, 0.1)
		seg.size = Vector2(LINE_WIDTH, segment_height)
		seg.position = Vector2(0.0, s * segment_height)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		finish_line.add_child(seg)


func _build_horses() -> void:
	horse_icons.clear()
	place_labels.clear()
	for path in horse_image_paths:
		var icon := TextureRect.new()
		icon.size = HORSE_ICON_SIZE
		icon.custom_minimum_size = HORSE_ICON_SIZE
		icon.pivot_offset = HORSE_ICON_SIZE * 0.5
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(path):
			icon.texture = load(path)
		add_child(icon)
		horse_icons.append(icon)

		## Podpis "1. Komet" — zgłoszenie użytkownika: po przekroczeniu mety
		## ma się pojawić PRZED koniem (w stronę, z której przybiegł, czyli
		## na prawo od zatrzymanej ikony, patrz _update_horses) jego miejsce
		## i nazwa. Ukryty do czasu przekroczenia, patrz _update_horses.
		var label := Label.new()
		label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		place_labels.append(label)


func _build_injury_label() -> void:
	injury_label = Label.new()
	injury_label.text = tr("Kontuzja!")
	injury_label.add_theme_font_size_override("font_size", 18)
	injury_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	injury_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	injury_label.add_theme_constant_override("shadow_offset_x", 1)
	injury_label.add_theme_constant_override("shadow_offset_y", 1)
	injury_label.visible = false
	injury_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(injury_label)


func _build_skip_button() -> void:
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
	banner_scroll_x += BANNER_SCROLL_SPEED * delta
	ground_scroll_x += GROUND_SCROLL_SPEED * delta
	_update_banner_positions()
	_update_ground_positions()
	_update_horses(t)
	if t >= 1.0:
		set_process(false)
		finished.emit()


## Przycisk "Pomiń" — od razu przeskakuje na koniec wyścigu (ostatnia klatka
## _process ustawia konie w finałowej kolejności i emituje finished), zamiast
## dodawać osobną ścieżkę kodu na "natychmiastowe rozstrzygnięcie".
func skip() -> void:
	if not is_processing():
		return
	elapsed = DURATION
	_process(0.0)


func _update_banner_positions() -> void:
	var pattern_width := BANNER_CARD_WIDTH + BANNER_GAP
	var total_width := pattern_width * banner_cards.size()
	for i in banner_cards.size():
		var x := fposmod(i * pattern_width - banner_scroll_x, total_width)
		banner_cards[i].position.x = x
		banner_labels[i].position.x = x


func _update_ground_positions() -> void:
	var pattern_width := GROUND_DASH_WIDTH + GROUND_DASH_GAP
	var total_width := pattern_width * ground_dashes.size()
	for i in ground_dashes.size():
		ground_dashes[i].position.x = fposmod(i * pattern_width - ground_scroll_x, total_width)


## Pozycja pozioma konia i w chwili t — krzywa potęgowa reparametryzowana
## własnym czasem konia (local_t = t / t_cross[i]), więc START przy t=0 i
## DOKŁADNIE finish_x w chwili t_cross[i], niezależnie od wykładnika
## powers[i] (< 1: szybki start, zwolnienie; > 1: wolny start, final. sprint
## — różne wykładniki na różnych koniach dają organiczne zmiany prowadzenia
## bez potrzeby cofania konia). Po przekroczeniu mety koń zatrzymuje się
## dokładnie na niej.
func _horse_x(i: int, t: float) -> float:
	var tc: float = t_cross[i]
	if t >= tc:
		return finish_x

	var local_t: float = t / tc
	var prog: float = pow(local_t, powers[i])
	var x: float = lerp(start_x, finish_x, prog)

	## Kontuzja — tymczasowe, zanikające cofnięcie W STRONĘ STARTU (dodatnie,
	## bo x rośnie w prawo/wstecz), zawsze scentrowane w ułamku WŁASNEGO
	## t_cross[i] tego konia, więc zawsze bezpiecznie zanika na długo przed
	## jego metą — nie wpływa na moment/pewność przekroczenia linii.
	if i == injury_horse_index:
		var d: float = t - injury_center
		x += INJURY_DEPTH * exp(-(d * d) / (2.0 * INJURY_WIDTH * INJURY_WIDTH))

	return clampf(x, finish_x, start_x)


func _update_horses(t: float) -> void:
	for i in horse_icons.size():
		var x := _horse_x(i, t)
		var lane_y: float = BANNER_HEIGHT + i * lane_height + lane_height * 0.5
		var just_crossed := t >= t_cross[i]
		## Bujanie/wahanie tylko, dopóki koń biegnie — po przekroczeniu mety
		## stoi nieruchomo obok podpisu z miejscem.
		var bob: float = 0.0 if just_crossed else sin(t * 50.0 + i * 1.7) * 4.0
		var icon := horse_icons[i]
		icon.position = Vector2(x - HORSE_ICON_SIZE.x * 0.5, lane_y - HORSE_ICON_SIZE.y * 0.5 + bob)
		icon.rotation = 0.0 if just_crossed else deg_to_rad(sin(t * 35.0 + i * 2.3) * 3.0)

		if just_crossed and not crossed[i]:
			crossed[i] = true
		if crossed[i]:
			## "Przed koniem" = po prawej od zatrzymanej ikony (skąd
			## przybiegł), zgłoszenie użytkownika.
			var label := place_labels[i]
			label.text = tr("%d. %s") % [places[i], horse_names[i]]
			label.visible = true
			label.position = Vector2(x + HORSE_ICON_SIZE.x * 0.5 + 8.0, lane_y - 12.0)

		if i == injury_horse_index and not just_crossed and absf(t - injury_center) < INJURY_WIDTH * 2.5:
			icon.rotation += deg_to_rad(16.0)
			injury_label.visible = true
			injury_label.position = Vector2(x - 36.0, lane_y - HORSE_ICON_SIZE.y * 0.5 - 24.0 + bob)
		elif i == injury_horse_index and injury_label.visible and not just_crossed:
			injury_label.visible = false
