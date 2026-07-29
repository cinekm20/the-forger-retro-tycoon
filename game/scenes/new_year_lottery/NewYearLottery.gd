extends Control
## Noworoczna Loteria (Neujahrstombola, docs/GDD.md pkt. 4.8) — krótka,
## satysfakcjonująca animacja (fajerwerki, konfetti, kalendarz przewracający
## rok) pokazywana automatycznie na przełomie roku w grze (patrz Hub.gd
## _ready, ten sam wzorzec co WorldEventCard.gd/YearSummary.gd). Samo
## losowanie (kto wygrywa, ile, czy trafia się obraz) już się odbyło w
## Players.grant_new_year_to_random_player (wywołane z Economy._on_new_year)
## — ten ekran TYLKO wizualizuje gotowy wynik (Lottery.consume_pending()),
## tak jak RaceTrackView/HeistView nigdy nie decydują o wyniku, tylko go
## pokazują (patrz scripts/ui/RaceTrackView.gd).
##
## Brak shaderów/particle-node'ów (ten sam styl co RaceTrackView — proste
## węzły Control/ColorRect repozycjonowane co klatkę w _process, zamiast
## CPUParticles2D) — konfetti to pula ColorRect-ów spadających i kołyszących
## się w poziomie, fajerwerki to kilka "wybuchów" małych ColorRect-ów
## lecących promieniście na zewnątrz i gasnących (Tween na position/modulate).

const DURATION := 5.0  ## sekundy do odsłonięcia wyniku (Pomiń » skraca od razu)
const CONFETTI_COUNT := 50
const CONFETTI_SIZE := Vector2(10.0, 16.0)
const CONFETTI_FALL_SPEED_RANGE := Vector2(120.0, 260.0)
const CONFETTI_WOBBLE_SPEED_RANGE := Vector2(0.5, 2.0)
const CONFETTI_WOBBLE_AMPLITUDE := 30.0
const CONFETTI_SPIN_RANGE := Vector2(-4.0, 4.0)
const CONFETTI_COLORS := [
	Color(0.85, 0.65, 0.2), Color(1.0, 0.83, 0.4), Color(0.75, 0.1, 0.1),
	Color(0.95, 0.88, 0.72), Color(0.3, 0.55, 0.85), Color(0.35, 0.7, 0.35),
]

const FIREWORK_COUNT := 5
const FIREWORK_PARTICLES := 16
const FIREWORK_RADIUS_RANGE := Vector2(70.0, 140.0)
const FIREWORK_INTERVAL_RANGE := Vector2(0.5, 1.0)
const FIREWORK_PARTICLE_SIZE := Vector2(6.0, 6.0)
const FIREWORK_FLIGHT_DURATION := 0.7

var result: Dictionary = {}
var view_size: Vector2 = Vector2(1280.0, 720.0)

var confetti_nodes: Array[ColorRect] = []
var confetti_fall_speed: Array[float] = []
var confetti_wobble_speed: Array[float] = []
var confetti_spin_speed: Array[float] = []

var elapsed: float = 0.0
var fireworks_spawned: int = 0
var next_firework_time: float = 0.0
var revealed: bool = false

var result_label: Label
var skip_button: Button
var continue_root: Control


func _ready() -> void:
	result = Lottery.consume_pending()
	view_size = get_viewport_rect().size

	ScreenHelpers.make_background(self, _background_path())

	_build_calendar_flip()
	_build_confetti()
	_build_result_label()
	_build_skip_button()
	_build_continue_button()

	set_process(true)


func _background_path() -> String:
	var path := "res://art/events/lottery.jpg"
	if ResourceLoader.exists(path):
		return path
	return "res://art/backgrounds/stock_market.jpg"


## Etykieta "ROK 1918" zamienia się w "ROK 1919" krótkim obrotem wokół osi X
## (scale.y 1 -> 0 -> 1) — jak przewracana kartka kalendarza.
func _build_calendar_flip() -> void:
	var year_new: int = int(result.get("year", Calendar.get_year()))
	var year_old: int = year_new - 1
	var box_size := Vector2(320.0, 90.0)

	var container := Control.new()
	container.position = Vector2(view_size.x * 0.5 - box_size.x * 0.5, 50.0)
	container.size = box_size
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	var panel := ColorRect.new()
	panel.color = ScreenHelpers.COLOR_BURGUNDY_DARK
	panel.size = box_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(panel)

	var old_label := _make_year_label(container, box_size, year_old)
	var new_label := _make_year_label(container, box_size, year_new)
	new_label.scale.y = 0.0

	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(old_label, "scale:y", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(new_label, "scale:y", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _make_year_label(container: Control, box_size: Vector2, year: int) -> Label:
	var label := Label.new()
	label.text = tr("ROK %d") % year
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = box_size
	label.pivot_offset = box_size * 0.5
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)
	return label


func _build_confetti() -> void:
	confetti_nodes.clear()
	confetti_fall_speed.clear()
	confetti_wobble_speed.clear()
	confetti_spin_speed.clear()
	for i in CONFETTI_COUNT:
		var piece := ColorRect.new()
		piece.color = CONFETTI_COLORS[i % CONFETTI_COLORS.size()]
		piece.size = CONFETTI_SIZE
		piece.pivot_offset = CONFETTI_SIZE * 0.5
		piece.position = Vector2(randf() * view_size.x, -randf() * view_size.y)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(piece)
		confetti_nodes.append(piece)
		confetti_fall_speed.append(randf_range(CONFETTI_FALL_SPEED_RANGE.x, CONFETTI_FALL_SPEED_RANGE.y))
		confetti_wobble_speed.append(randf_range(CONFETTI_WOBBLE_SPEED_RANGE.x, CONFETTI_WOBBLE_SPEED_RANGE.y))
		confetti_spin_speed.append(randf_range(CONFETTI_SPIN_RANGE.x, CONFETTI_SPIN_RANGE.y))


func _build_result_label() -> void:
	result_label = Label.new()
	result_label.text = _result_text()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	result_label.custom_minimum_size = Vector2(700.0, 0.0)
	result_label.size = Vector2(700.0, 180.0)
	result_label.position = Vector2(view_size.x * 0.5 - 350.0, view_size.y * 0.6)
	result_label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	result_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
	result_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	result_label.add_theme_constant_override("shadow_offset_x", 1)
	result_label.add_theme_constant_override("shadow_offset_y", 1)
	result_label.modulate.a = 0.0
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result_label)


func _result_text() -> String:
	var winner_index: int = int(result.get("winner_index", 0))
	var winner_name: String = (
		Players.player_names[winner_index] if winner_index < Players.player_names.size() else tr("Gracz")
	)
	var money: float = float(result.get("money", 0.0))
	var painting_number: int = int(result.get("painting_number", -1))

	var text := tr("Noworoczna Loteria!\n%s wygrywa %.0f M.") % [winner_name, money]
	if painting_number > 0:
		var info: Dictionary = Paintings.get_painting_info(painting_number)
		text += "\n" + tr("Dodatkowo w kopercie czekał prawdziwy obraz: „%s” (%s, %s)!") % [
			info.get("title", ""), info.get("artist", ""), info.get("year", ""),
		]
	return text


func _build_skip_button() -> void:
	skip_button = Button.new()
	skip_button.text = tr("Pomiń »")
	skip_button.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	skip_button.pressed.connect(_on_skip_pressed)
	skip_button.size = Vector2(130.0, 40.0)
	skip_button.position = Vector2(view_size.x - 150.0, 20.0)
	add_child(skip_button)


## Ozdobna skrzynka Art Deco w prawym dolnym rogu, TA SAMA co boczny panel na
## TravelMap.gd/Hub.gd — zgłoszone przez użytkownika (dotyczy innych ekranów,
## ten sam wzorzec): przycisk powrotu ma wyglądać tak samo wszędzie. Ukryta do
## czasu odsłonięcia wyniku (_reveal_result) — gracz najpierw widzi animację.
func _build_continue_button() -> void:
	continue_root = ScreenHelpers.make_root_bottom(self, true)
	ScreenHelpers.make_button(continue_root, tr("Kontynuuj »"), func(): SceneRouter.goto_hub())
	continue_root.visible = false


func _process(delta: float) -> void:
	elapsed += delta
	_update_confetti(delta)
	_update_fireworks()

	if elapsed >= DURATION and not revealed:
		_reveal_result()


func _update_confetti(delta: float) -> void:
	for i in confetti_nodes.size():
		var piece := confetti_nodes[i]
		piece.position.y += confetti_fall_speed[i] * delta
		piece.position.x += sin(elapsed * confetti_wobble_speed[i] + i) * CONFETTI_WOBBLE_AMPLITUDE * delta
		piece.rotation += confetti_spin_speed[i] * delta
		if piece.position.y > view_size.y + CONFETTI_SIZE.y:
			piece.position.y = -randf_range(20.0, 200.0)
			piece.position.x = randf() * view_size.x


func _update_fireworks() -> void:
	if fireworks_spawned >= FIREWORK_COUNT:
		return
	if elapsed >= next_firework_time:
		_spawn_firework()
		fireworks_spawned += 1
		next_firework_time = elapsed + randf_range(FIREWORK_INTERVAL_RANGE.x, FIREWORK_INTERVAL_RANGE.y)


func _spawn_firework() -> void:
	var center := Vector2(
		randf_range(view_size.x * 0.15, view_size.x * 0.85),
		randf_range(view_size.y * 0.15, view_size.y * 0.55),
	)
	var color: Color = CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()]
	for i in FIREWORK_PARTICLES:
		var angle := TAU * float(i) / float(FIREWORK_PARTICLES)
		var particle := ColorRect.new()
		particle.color = color
		particle.size = FIREWORK_PARTICLE_SIZE
		particle.pivot_offset = FIREWORK_PARTICLE_SIZE * 0.5
		particle.position = center - FIREWORK_PARTICLE_SIZE * 0.5
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(particle)

		var radius := randf_range(FIREWORK_RADIUS_RANGE.x, FIREWORK_RADIUS_RANGE.y)
		var target := center + Vector2.RIGHT.rotated(angle) * radius - FIREWORK_PARTICLE_SIZE * 0.5
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target, FIREWORK_FLIGHT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, FIREWORK_FLIGHT_DURATION).set_delay(0.15)
		tween.finished.connect(particle.queue_free)


func _on_skip_pressed() -> void:
	skip_button.visible = false
	elapsed = DURATION
	if not revealed:
		_reveal_result()


func _reveal_result() -> void:
	revealed = true
	var tween := create_tween()
	tween.tween_property(result_label, "modulate:a", 1.0, 0.5)
	continue_root.visible = true
