class_name RaceTrackView
extends Control
## Animowany tor wyścigowy — przewijane banery reklamowe u góry, przewijana
## trawa u dołu, konie (reużyte portrety Horses.HORSES) biegnące środkiem z
## realnymi zmianami prowadzenia i losową kontuzją, meta wjeżdżająca w kadr
## pod koniec. Zgłoszenie użytkownika: wynik nie może być oczywisty od razu,
## wyścig ma trwać min. 30 sekund.
##
## KLUCZOWA ZASADA UCZCIWOŚCI: zwycięzca jest znany PRZED zbudowaniem tego
## widoku (Races.gd woła _pick_winner_index() i dopiero potem setup()) — ta
## klasa TYLKO wizualizuje już ustalony wynik w sposób, który go nie zdradza
## od razu. Każdy koń dostaje krzywą względnej pozycji p_i(t), t=0..1:
## losowe "błądzenie" (kilka nałożonych fal sinusoidalnych) w pierwszych
## ~75% wyścigu daje realne zmiany prowadzenia, po czym zanika i ustępuje
## "ciągnięciu" w stronę finałowej kolejności — zwycięzca ZAWSZE dostaje
## najwyższą finałową wartość, więc wizualnie przybiega pierwszy, niezależnie
## jak wyglądało błądzenie po drodze. Jeden losowy nie-zwycięski koń może
## dostać dodatkowo "kontuzję" (gwałtowny dołek na krzywej + przechył ikony +
## podpis) — bezpieczne dla uczciwości wyniku, bo dotyczy tylko konia, który
## i tak nie miał wygrać.
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
const PACK_CENTER_FRACTION := 0.38  ## ułamek szerokości — stały punkt, wokół którego oscylują konie

const WANDER_WAVE_COUNT := 3
const WANDER_AMPLITUDE_RANGE := Vector2(15.0, 45.0)
const WANDER_FREQ_RANGE := Vector2(1.0, 3.2)  ## cykli na CAŁY wyścig
const FADE_START := 0.75  ## od tego t błądzenie zaczyna zanikać
const RAMP_START := 0.55  ## od tego t zaczyna "ciągnąć" w stronę finałowej kolejności
const RAMP_END := 0.95
const WINNER_FINAL_OFFSET := 70.0
const OTHER_FINAL_OFFSET_RANGE := Vector2(-60.0, 50.0)

const INJURY_CHANCE := 0.25
const INJURY_DEPTH := 90.0
const INJURY_WIDTH := 0.05  ## "szerokość" dołka w jednostkach t
const INJURY_CENTER_RANGE := Vector2(0.25, 0.55)

const BANNER_TEXTS := ["CYGARA CYKLON", "BANK FALKENSTEIN", "PIWO GROM", "PERFUMY COLOMBO", "HOTEL ASHCOMBE"]
const BANNER_CARD_WIDTH := 200.0
const BANNER_GAP := 24.0
const BANNER_SCROLL_SPEED := 90.0  ## px/s

const GROUND_DASH_WIDTH := 10.0
const GROUND_DASH_GAP := 50.0
const GROUND_SCROLL_SPEED := 160.0  ## szybciej niż banery = wrażenie głębi (paralaksa)

const FINISH_FLAG_WIDTH := 16.0

var view_size: Vector2 = Vector2(1280.0, 720.0)
var pack_center_x: float = 0.0
var lane_height: float = 100.0

var horse_image_paths: Array[String] = []
var winner_index: int = -1
var wander_waves: Array = []  ## per koń: Array[Dictionary{freq,phase,amp}]
var final_offsets: Array[float] = []
var injury_horse_index: int = -1
var injury_center: float = 0.0

var elapsed: float = 0.0
var banner_scroll_x: float = 0.0
var ground_scroll_x: float = 0.0

var banner_cards: Array[ColorRect] = []
var banner_labels: Array[Label] = []
var ground_dashes: Array[ColorRect] = []
var horse_icons: Array[TextureRect] = []
var finish_flag: Control
var injury_label: Label
var skip_button: Button


func _ready() -> void:
	set_process(false)


## Wołane RAZ przez Races.gd, zaraz po ustaleniu zwycięzcy — image_paths w
## TEJ SAMEJ kolejności co horse_ids/horse_option w Races.gd, więc
## winner_idx/chosen_idx (przekazywane z powrotem przez `finished` w
## Races.gd, bind-owane po stronie wywołującego) trafiają w ten sam koń.
func setup(image_paths: Array[String], winner_idx: int, viewport_size: Vector2) -> void:
	horse_image_paths = image_paths
	winner_index = winner_idx
	view_size = viewport_size
	pack_center_x = view_size.x * PACK_CENTER_FRACTION
	lane_height = (view_size.y - BANNER_HEIGHT - GROUND_HEIGHT) / float(horse_image_paths.size())

	_generate_curves()
	_build_visuals()

	elapsed = 0.0
	set_process(true)


func _generate_curves() -> void:
	wander_waves.clear()
	final_offsets.clear()

	for i in horse_image_paths.size():
		if i == winner_index:
			final_offsets.append(WINNER_FINAL_OFFSET)
		else:
			final_offsets.append(randf_range(OTHER_FINAL_OFFSET_RANGE.x, OTHER_FINAL_OFFSET_RANGE.y))

	for i in horse_image_paths.size():
		var waves: Array = []
		for w in WANDER_WAVE_COUNT:
			waves.append({
				"freq": randf_range(WANDER_FREQ_RANGE.x, WANDER_FREQ_RANGE.y),
				"phase": randf_range(0.0, TAU),
				"amp": randf_range(WANDER_AMPLITUDE_RANGE.x, WANDER_AMPLITUDE_RANGE.y) / WANDER_WAVE_COUNT,
			})
		wander_waves.append(waves)

	injury_horse_index = -1
	if randf() < INJURY_CHANCE:
		var candidates: Array[int] = []
		for i in horse_image_paths.size():
			if i != winner_index:
				candidates.append(i)
		if not candidates.is_empty():
			injury_horse_index = candidates[randi() % candidates.size()]
			injury_center = randf_range(INJURY_CENTER_RANGE.x, INJURY_CENTER_RANGE.y)


func _build_visuals() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.07, 0.05, 0.97)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_build_banner_strip()
	_build_ground_strip()
	_build_finish_flag()
	_build_horses()
	_build_injury_label()
	_build_skip_button()


func _build_banner_strip() -> void:
	var strip := Control.new()
	strip.anchor_left = 0.0
	strip.anchor_right = 1.0
	strip.offset_bottom = BANNER_HEIGHT
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.clip_contents = true
	add_child(strip)

	var strip_bg := ColorRect.new()
	strip_bg.color = Color(0.15, 0.1, 0.06)
	strip_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	strip.anchor_left = 0.0
	strip.anchor_right = 1.0
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_top = -GROUND_HEIGHT
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.clip_contents = true
	add_child(strip)

	var strip_bg := ColorRect.new()
	strip_bg.color = Color(0.16, 0.32, 0.14)
	strip_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
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


func _build_finish_flag() -> void:
	finish_flag = Control.new()
	finish_flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish_flag.size = Vector2(FINISH_FLAG_WIDTH, view_size.y - BANNER_HEIGHT - GROUND_HEIGHT)
	finish_flag.position = Vector2(view_size.x + 150.0, BANNER_HEIGHT)
	add_child(finish_flag)

	var segment_count := 8
	var segment_height := finish_flag.size.y / float(segment_count)
	for s in segment_count:
		var seg := ColorRect.new()
		seg.color = Color.WHITE if s % 2 == 0 else Color(0.75, 0.1, 0.1)
		seg.size = Vector2(FINISH_FLAG_WIDTH, segment_height)
		seg.position = Vector2(0.0, s * segment_height)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		finish_flag.add_child(seg)


func _build_horses() -> void:
	horse_icons.clear()
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
	skip_button.anchor_left = 1.0
	skip_button.anchor_right = 1.0
	skip_button.anchor_top = 1.0
	skip_button.anchor_bottom = 1.0
	skip_button.offset_left = -150.0
	skip_button.offset_right = -20.0
	skip_button.offset_top = -56.0
	skip_button.offset_bottom = -16.0
	add_child(skip_button)


func _process(delta: float) -> void:
	elapsed += delta
	var t: float = clampf(elapsed / DURATION, 0.0, 1.0)
	banner_scroll_x += BANNER_SCROLL_SPEED * delta
	ground_scroll_x += GROUND_SCROLL_SPEED * delta
	_update_banner_positions()
	_update_ground_positions()
	_update_horses(t)
	_update_finish_line(t)
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


## Krzywa względnej pozycji konia i (patrz komentarz na górze pliku) —
## dodatnia wartość = przed stawką, ujemna = za stawką.
func _curve_offset(i: int, t: float) -> float:
	var wander := 0.0
	for wave in wander_waves[i]:
		wander += sin(t * wave["freq"] * TAU + wave["phase"]) * wave["amp"]
	var fade: float = 1.0 - smoothstep(FADE_START, 1.0, t)
	wander *= fade

	if i == injury_horse_index:
		var d: float = t - injury_center
		wander -= INJURY_DEPTH * exp(-(d * d) / (2.0 * INJURY_WIDTH * INJURY_WIDTH))

	var ramp: float = smoothstep(RAMP_START, RAMP_END, t)
	return wander + final_offsets[i] * ramp


func _update_horses(t: float) -> void:
	for i in horse_icons.size():
		var offset := _curve_offset(i, t)
		var x: float = pack_center_x + offset
		var lane_y: float = BANNER_HEIGHT + i * lane_height + lane_height * 0.5
		var bob: float = sin(t * 50.0 + i * 1.7) * 4.0
		var icon := horse_icons[i]
		icon.position = Vector2(x - HORSE_ICON_SIZE.x * 0.5, lane_y - HORSE_ICON_SIZE.y * 0.5 + bob)
		icon.rotation = deg_to_rad(sin(t * 35.0 + i * 2.3) * 3.0)

		if i == injury_horse_index and absf(t - injury_center) < INJURY_WIDTH * 2.5:
			icon.rotation += deg_to_rad(16.0)
			injury_label.visible = true
			injury_label.position = Vector2(x - 36.0, lane_y - HORSE_ICON_SIZE.y * 0.5 - 24.0 + bob)
		elif i == injury_horse_index and injury_label.visible:
			injury_label.visible = false


func _update_finish_line(t: float) -> void:
	var start_x := view_size.x + 150.0
	var end_x := pack_center_x + 30.0
	finish_flag.position.x = lerp(start_x, end_x, smoothstep(0.0, 1.0, t))
