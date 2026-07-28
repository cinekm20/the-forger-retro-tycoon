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
const BANNER_TEXTURE_PATHS := ["res://art/backgrounds/advertising1.jpg", "res://art/backgrounds/advertising2.jpg"]
const BANNER_CARD_HEIGHT_RATIO := 0.9  ## ułamek BANNER_HEIGHT — szerokość kafelka liczona z proporcji tekstury
const BANNER_CARD_WIDTH_STRETCH := 1.5  ## zgłoszenie użytkownika: grafiki mają być rozciągnięte na boki (szerzej niż oryginalna proporcja), tekst zostaje wyśrodkowany bez zmian
const BANNER_GAP := 24.0
const BANNER_SCROLL_SPEED := 90.0  ## px/s

const GRASS_TEXTURE_PATH := "res://art/backgrounds/race_grass.png"
const GROUND_TEXTURE_PATH := "res://art/backgrounds/race_track_ground.png"
const GROUND_TILE_SIZE := 320.0  ## kafelek tła (grunt/podłoże) pod całą sceną
const GROUND_SCROLL_SPEED := 160.0  ## szybciej niż banery = wrażenie głębi (paralaksa)

const LINE_WIDTH := 16.0
## Zgłoszenie użytkownika: linia startu ma "odlecieć" z ekranu zaraz po
## starcie, linia mety ma "dolecieć" od lewej dopiero po pewnym czasie —
## oba w jednostkach t (ułamek DURATION).
const START_LINE_EXIT_END := 0.12
const FINISH_LINE_ENTRY_START := 0.2
const FINISH_LINE_ENTRY_END := 0.5

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

var banner_cards: Array[TextureRect] = []
var banner_labels: Array[Label] = []
var banner_card_width: float = 0.0
var ground_tiles: Array[TextureRect] = []
var ground_tile_width: float = 0.0
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

	_build_backdrop()

	_build_banner_strip()
	_build_ground_strip()
	_build_start_line()
	_build_finish_line()
	_build_horses()
	_build_injury_label()
	_build_skip_button()


## Podłoże pod całą sceną (res://art/backgrounds/race_track_ground.png,
## kafelkowane, bez przewijania) — leży POD banerami/trawą/końmi, więc
## przezroczysta górna część kafelków trawy (_build_ground_strip) pokazuje
## tę teksturę zamiast dawnego płaskiego ciemnozielonego tła.
func _build_backdrop() -> void:
	var backdrop := Control.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = view_size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.clip_contents = true
	add_child(backdrop)

	var ground_tex: Texture2D = load(GROUND_TEXTURE_PATH)
	var cols := int(ceil(view_size.x / GROUND_TILE_SIZE))
	var rows := int(ceil(view_size.y / GROUND_TILE_SIZE))
	for row in rows:
		for col in cols:
			var tile := TextureRect.new()
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.texture = ground_tex
			tile.size = Vector2(GROUND_TILE_SIZE, GROUND_TILE_SIZE)
			tile.position = Vector2(col * GROUND_TILE_SIZE, row * GROUND_TILE_SIZE)
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			backdrop.add_child(tile)


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

	var banner_textures: Array[Texture2D] = []
	for path in BANNER_TEXTURE_PATHS:
		banner_textures.append(load(path))

	var card_height := BANNER_HEIGHT * BANNER_CARD_HEIGHT_RATIO
	var tex_size: Vector2 = banner_textures[0].get_size()
	banner_card_width = card_height * (tex_size.x / tex_size.y) * BANNER_CARD_WIDTH_STRETCH
	var card_position_y := (BANNER_HEIGHT - card_height) * 0.5

	var pattern_width := banner_card_width + BANNER_GAP
	var card_count := int(ceil(view_size.x / pattern_width)) + 2
	for i in card_count:
		## Zgłoszenie użytkownika: dwie grafiki plakietek reklamowych mają się
		## pojawiać NA ZMIANĘ (advertising1/advertising2.jpg wg parzystości i)
		## z podpisem (BANNER_TEXTS) wyrenderowanym NAD nimi jako osobny Label.
		var card := TextureRect.new()
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_SCALE
		card.texture = banner_textures[i % banner_textures.size()]
		card.size = Vector2(banner_card_width, card_height)
		card.position.y = card_position_y
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(card)
		banner_cards.append(card)

		var label := Label.new()
		label.text = tr(BANNER_TEXTS[i % BANNER_TEXTS.size()])
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(0.25, 0.14, 0.08))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = card.size
		label.position.y = card_position_y
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(label)
		banner_labels.append(label)


## Przewijana trawa u dołu — kafelki grafiki (res://art/backgrounds/
## race_grass.png, przezroczyste tło) zamiast dawnych ColorRect-ów. Szerokość
## kafelka liczona z proporcji tekstury, żeby przy skalowaniu do GROUND_HEIGHT
## trawa nie wyglądała na rozciągniętą.
func _build_ground_strip() -> void:
	var strip := Control.new()
	strip.position = Vector2(0.0, view_size.y - GROUND_HEIGHT)
	strip.size = Vector2(view_size.x, GROUND_HEIGHT)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.clip_contents = true
	add_child(strip)

	var grass_tex: Texture2D = load(GRASS_TEXTURE_PATH)
	ground_tile_width = GROUND_HEIGHT * (grass_tex.get_width() / float(grass_tex.get_height()))

	var tile_count := int(ceil(view_size.x / ground_tile_width)) + 2
	for i in tile_count:
		var tile := TextureRect.new()
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_SCALE
		tile.texture = grass_tex
		tile.size = Vector2(ground_tile_width, GROUND_HEIGHT)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(tile)
		ground_tiles.append(tile)


## Linia startu — jednolita biała. Zgłoszenie użytkownika: konie startują na
## niej, a ona sama zaraz potem "odlatuje" z ekranu (w prawo, tak jak banery/
## trawa — patrz _update_lines) — zostaje za końmi, tak jak prawdziwa linia
## startu. Budowana na start_x, animacja wylotu w _update_lines.
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


## Linia mety — biało-czerwona w kratkę. Zgłoszenie użytkownika: ma "dolecieć"
## od lewej krawędzi ekranu po pewnym czasie (patrz _update_lines), a nie być
## widoczna od samego początku — budowana od razu POZA ekranem po lewej,
## dopiero animacja wjazdu ustawia ją docelowo na finish_x. Sam finish_x
## (środek, niezależny od chwilowej pozycji linii-widoku) to nadal jedyne
## źródło prawdy dla matematyki koni (_horse_x) — animacja linii jest czysto
## kosmetyczna i nigdy nie zmienia, KIEDY koń faktycznie kończy bieg.
func _build_finish_line() -> void:
	finish_line = Control.new()
	finish_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish_line.size = Vector2(LINE_WIDTH, view_size.y - BANNER_HEIGHT - GROUND_HEIGHT)
	finish_line.position = Vector2(-LINE_WIDTH - 60.0, BANNER_HEIGHT)
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
	_update_lines(t)
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


## Zgłoszenie użytkownika: banery/trawa mają się przesuwać w DRUGĄ stronę
## (w prawo, nie w lewo jak poprzednio) — + zamiast - w formule fposmod,
## reszta wzoru (standardowy trik na nieskończone przewijanie bez utraty
## ciągłości na krawędzi) bez zmian.
##
## Zgłoszenie użytkownika: kafelek na lewej krawędzi potrafił "wyskoczyć"
## od razu w całości zamiast wjechać płynnie zza ekranu — fposmod() sam w
## sobie ZAWSZE zawija wynik do [0, total_width), a 0 to lewa krawędź
## ekranu, więc moment zawinięcia (teleport z dalekiego prawego offscreenu
## na x=0) wypadał na widoku. Odjęcie jednego pattern_width przesuwa ten
## moment zawinięcia o cały kafelek w lewo (na x=-pattern_width), czyli
## poza ekran — od tej chwili kafelek wjeżdża płynnie od lewej zamiast
## pojawiać się nagle w całości.
func _update_banner_positions() -> void:
	var pattern_width := banner_card_width + BANNER_GAP
	var total_width := pattern_width * banner_cards.size()
	for i in banner_cards.size():
		var x := fposmod(i * pattern_width + banner_scroll_x, total_width) - pattern_width
		banner_cards[i].position.x = x
		banner_labels[i].position.x = x


func _update_ground_positions() -> void:
	var total_width := ground_tile_width * ground_tiles.size()
	for i in ground_tiles.size():
		ground_tiles[i].position.x = fposmod(i * ground_tile_width + ground_scroll_x, total_width) - ground_tile_width


## Linia startu "odlatuje" w prawo i znika za ekranem zaraz po starcie;
## linia mety "dolatuje" od lewej krawędzi dopiero po pewnym czasie i
## zatrzymuje się na finish_x — obie animacje czysto kosmetyczne (patrz
## komentarz w _build_finish_line), matematyka koni (_horse_x) zawsze liczy
## względem stałych start_x/finish_x, niezależnie od chwilowej pozycji
## samej grafiki linii.
func _update_lines(t: float) -> void:
	var exit_t := clampf(t / START_LINE_EXIT_END, 0.0, 1.0)
	start_line.position.x = lerp(start_x - LINE_WIDTH * 0.5, view_size.x + 60.0, smoothstep(0.0, 1.0, exit_t))

	var entry_t := clampf((t - FINISH_LINE_ENTRY_START) / (FINISH_LINE_ENTRY_END - FINISH_LINE_ENTRY_START), 0.0, 1.0)
	finish_line.position.x = lerp(-LINE_WIDTH - 60.0, finish_x - LINE_WIDTH * 0.5, smoothstep(0.0, 1.0, entry_t))


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
