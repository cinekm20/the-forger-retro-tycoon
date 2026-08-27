extends Control
## Szkoła sztuki — kurs podnoszący eksperckość (Paintings.expertise), która
## zwiększa szansę na wczesne ostrzeżenie o podróbce w domu aukcyjnym.
## Patrz GDD.md pkt. 4.6.
##
## Zgłoszone przez użytkownika: kurs to teraz mini-gra "znajdź podróbkę" —
## zamiast samego przycisku, gracz porównuje DWA obrazy (prawdziwy i jego
## dedykowany wariant podróbki, patrz Paintings.get_numbers_with_fake_variant)
## i wskazuje, który to fałszywka. Trafiona odpowiedź daje więcej
## eksperckości niż nietrafiona — uczy realnie patrzeć na obrazy, zamiast
## dawać eksperckość za sam fakt kliknięcia przycisku.

const TRAINING_COST := 2000.0
## Zgłoszone przez użytkownika (docs/DODATKOWE_MECHANIKI.md, tipy do
## sequela): "Akademia Sztuki w konkretnym mieście z dłuższymi kursami" —
## Akademia jest teraz dostępna TYLKO w Paryżu (patrz Hub.LOCATION_GATED_DESTINATIONS,
## "Szkoła sztuki" -> requires_cities=["paris"]), a kurs trwa 2× dłużej niż
## dawniej (14 -> 28 dni) jako rekompensata za tę utratę dostępności —
## rzadsza, ale bardziej znacząca podróż do jednego konkretnego miasta.
const TRAINING_DAYS := 28
const EXPERTISE_GAIN_CORRECT := 0.15
const EXPERTISE_GAIN_WRONG := 0.05
const QUIZ_IMAGE_SIZE := 280.0

const ExpertisePuzzleScript := preload("res://scripts/ui/ExpertisePuzzle.gd")
const StatIconScript := preload("res://scripts/ui/StatIcon.gd")
const EXPERTISE_PUZZLE_IMAGE := "res://art/art_school/expertise_puzzle.jpg"
const EXPERTISE_PUZZLE_SIZE := Vector2(240, 240)

## Zgłoszenie użytkownika: zdanie tłumaczące, co robi eksperckość, ma być
## "trochę większe" niż zwykły tekst — stąd osobny, większy font_size
## (zwykły make_label zawsze daje ScreenHelpers.BODY_FONT_SIZE=22).
const EXPLANATION_FONT_SIZE := 28

var explanation_label: Label
var location_label: Label
var money_label: Label
var status_label: Label
var expertise_label: Label
var expertise_row: HBoxContainer
var course_button: Button
var quiz_section: VBoxContainer
var quiz_result_label: Label
var quiz_painting_number: int = -1

## Zgłoszenie użytkownika: eksperckość ma się pokazywać jako układanka,
## która "randomowo się układa" w miarę wzrostu procentów, zamiast (obok,
## nie zamiast) gołej liczby w info_label — patrz ExpertisePuzzle.gd.
## Typowana jako Control (nie ExpertisePuzzle) — ta sama konwencja co
## race_track w Races.gd/shipping_chart w StockMarket.gd, wywołania
## setup()/set_progress() i tak działają przez dynamiczne wiązanie GDScript.
var expertise_puzzle: Control


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/art_school.jpg")
	ScreenHelpers.make_instructions_button(self)
	## Zgłoszenie użytkownika: gotówka MA być wyłącznie w skrzynce w prawym
	## górnym rogu, dokładnie jak w Giełdzie/Rynku (ScreenHelpers.make_corner_status_row),
	## zamiast w zdaniu "Gotówka: X M | Data: Y" w środku ekranu.
	var corner := ScreenHelpers.make_corner_status_row(self, "", "")
	location_label = corner["left"]
	money_label = corner["right"]

	## use_menu_frame=false + ALIGNMENT_BEGIN + JEDEN rozpychacz na końcu:
	## zgłoszone przez użytkownika — ozdobna ramka znika, nazwa ekranu zostaje
	## przypięta na samej górze, przycisk powrotu na samym dole. Treść leci
	## zaraz pod tytułem (bez rozpychacza między nimi) — patrz Races.gd po
	## szczegółowe uzasadnienie, czemu JEDEN rozpychacz (nie dwa).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Szkoła sztuki")
	ScreenHelpers.make_turn_indicator(root)

	## Zdanie o działaniu eksperckości — WŁASNY (większy) font_size, patrz
	## EXPLANATION_FONT_SIZE. Tekst STAŁY (nie zależy od wartości
	## eksperckości), więc ustawiany raz tutaj, nie w _update_info().
	## autowrap + custom_minimum_size (SZEROKOŚĆ i WYSOKOŚĆ oba stałe) — bez
	## zawijania renderowało się jako jeden, bardzo szeroki wiersz wychodzący
	## poza ramkę ekranu na wąskich/portretowych rozdzielczościach (przegląd
	## czytelności/dopasowania do rozdzielczości na żądanie użytkownika).
	explanation_label = ScreenHelpers.make_label(
		root,
		tr("Eksperckość zwiększa szansę na wczesne ostrzeżenie o podróbce w Domu aukcyjnym\n(NIE wpływa na szacowaną wartość obrazu)"),
	)
	explanation_label.add_theme_font_size_override("font_size", EXPLANATION_FONT_SIZE)
	explanation_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	explanation_label.custom_minimum_size = Vector2(700, 90)

	status_label = ScreenHelpers.make_label(root, "")

	expertise_puzzle = ExpertisePuzzleScript.new()
	expertise_puzzle.setup(EXPERTISE_PUZZLE_IMAGE, EXPERTISE_PUZZLE_SIZE)
	root.add_child(expertise_puzzle)

	## Zgłoszenie użytkownika: "Eksperckość: NN%" ma być POD obrazem (nie
	## razem z resztą tekstu nad nim) — jak podpis pod portretem konia w
	## Races.gd. Ikona lupy (docs/GRAFIKA_LEONARDO.md wiersz 7b) doklejona z
	## boku w osobnym wierszu — expertise_row (nie expertise_label) chowany/
	## pokazywany razem z quizem, żeby ikona nie zostawała samotnie widoczna.
	expertise_row = HBoxContainer.new()
	expertise_row.alignment = BoxContainer.ALIGNMENT_CENTER
	expertise_row.add_theme_constant_override("separation", 8)
	root.add_child(expertise_row)
	expertise_row.add_child(StatIconScript.new(StatIconScript.Kind.EXPERTISE))
	expertise_label = ScreenHelpers.make_label(expertise_row, "")

	## Sekcja quizu — ukryta, dopóki nie wykupiony jest kurs. Podmienia się z
	## powyższymi etykietami/course_button (patrz _start_quiz/_close_quiz),
	## żeby ekran nie pokazywał obu naraz.
	quiz_section = VBoxContainer.new()
	quiz_section.visible = false
	root.add_child(quiz_section)

	## Zgłoszenie użytkownika: przycisk startu kursu ma "wylądować" w tej
	## samej skrzynce co przycisk powrotu — dokładnie jak zakład w Races.gd,
	## dołączony do TEJ SAMEJ ozdobnej ramki Art Deco w prawym dolnym rogu,
	## zamiast osobnego przycisku w środku ekranu. Widoczność course_button
	## nadal przełącza się niezależnie od tego, gdzie w drzewie węzłów
	## siedzi (patrz _start_quiz/_close_quiz) — to zwykła właściwość Control.
	var corner_box := ScreenHelpers.make_root_bottom(self, true)
	course_button = ScreenHelpers.make_button(
		corner_box,
		tr("Kurs (%.0f M, %d dni)") % [TRAINING_COST, TRAINING_DAYS],
		_on_train_pressed,
	)
	ScreenHelpers.make_back_button(corner_box)
	_update_info()


func _on_train_pressed() -> void:
	## Zgłoszenie użytkownika: przy 90% (Paintings.MAX_EXPERTISE) kurs i tak
	## nie dawał już nic więcej (increase_expertise samo się ucina), ale
	## gracz płacił za niego TRAINING_COST/dni bez żadnego efektu — myślał,
	## że to błąd. Teraz kurs w ogóle się nie zaczyna (żadnej opłaty/dni),
	## a przycisk jest disabled (patrz _update_info) z czytelnym komunikatem
	## zamiast cichego "nic się nie stało".
	if Paintings.expertise >= Paintings.MAX_EXPERTISE:
		return
	if not Economy.spend(TRAINING_COST):
		status_label.text = tr("Za mało gotówki na kurs.")
		return
	Players.advance_active_player_time(TRAINING_DAYS)
	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)
		return
	_start_quiz()


## Losuje jeden numer katalogowy z dedykowanym wariantem podróbki i pokazuje
## oba obrazy obok siebie w losowej kolejności — gracz klika, który uważa za
## fałszywkę.
func _start_quiz() -> void:
	var candidates := Paintings.get_numbers_with_fake_variant()
	if candidates.is_empty():
		## Zabezpieczenie: gdyby katalog kiedyś nie miał ŻADNEGO wariantu
		## podróbki (np. świeży branch bez tych plików), kurs po prostu daje
		## bazową eksperckość bez quizu, zamiast pokazać pusty ekran.
		Paintings.increase_expertise(EXPERTISE_GAIN_WRONG)
		_end_course_turn()
		return

	quiz_painting_number = candidates[randi() % candidates.size()]
	var fake_on_left := randf() < 0.5

	for child in quiz_section.get_children():
		child.queue_free()

	ScreenHelpers.make_label(quiz_section, tr("Który z tych dwóch obrazów to podróbka?"))

	var compare_row := HBoxContainer.new()
	compare_row.alignment = BoxContainer.ALIGNMENT_CENTER
	compare_row.add_theme_constant_override("separation", 24)
	quiz_section.add_child(compare_row)

	_add_quiz_option(compare_row, fake_on_left)
	_add_quiz_option(compare_row, not fake_on_left)

	quiz_result_label = ScreenHelpers.make_label(quiz_section, "")

	course_button.visible = false
	explanation_label.visible = false
	status_label.visible = false
	expertise_row.visible = false
	expertise_puzzle.visible = false
	quiz_section.visible = true


## Jedna kolumna quizu: obraz + przycisk "Ta jest podróbką". is_fake to
## PRAWDZIWA natura TEGO kafelka (nie zgadywana) — bindowana wprost do
## _on_quiz_guess, więc "gracz kliknął kafelek, który faktycznie jest
## podróbką" i "trafna odpowiedź" to dokładnie ten sam warunek.
func _add_quiz_option(parent: Container, is_fake: bool) -> void:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)

	var texture_path := Paintings.get_texture_path(quiz_painting_number, is_fake)
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(QUIZ_IMAGE_SIZE, QUIZ_IMAGE_SIZE)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(texture_path):
		rect.texture = load(texture_path)
	column.add_child(rect)

	ScreenHelpers.make_button(column, tr("Ta jest podróbką"), _on_quiz_guess.bind(is_fake))


func _on_quiz_guess(is_correct: bool) -> void:
	var gain := EXPERTISE_GAIN_CORRECT if is_correct else EXPERTISE_GAIN_WRONG
	Paintings.increase_expertise(gain)
	quiz_result_label.text = (
		tr("Trafnie! To rzeczywiście była podróbka.") if is_correct
		else tr("Nietrafiona odpowiedź — to był oryginał.")
	) + tr(" Eksperckość +%.0f%%.") % [gain * 100.0]

	_disable_buttons(quiz_section)
	ScreenHelpers.make_button(quiz_section, tr("Zamknij"), _close_quiz)


func _disable_buttons(node: Node) -> void:
	if node is Button:
		node.disabled = true
	for child in node.get_children():
		_disable_buttons(child)


func _close_quiz() -> void:
	quiz_section.visible = false
	course_button.visible = true
	explanation_label.visible = true
	status_label.visible = true
	expertise_row.visible = true
	expertise_puzzle.visible = true
	_end_course_turn()


## Dni kursu (Players.advance_active_player_time) nalicza już _on_train_pressed(),
## ale przekazanie ruchu (Players.pass_turn_to_earliest_player) czeka
## DO TERAZ, na sam koniec — po zastosowaniu eksperckości z quizu w
## _on_quiz_guess (nie zaraz po zapłaceniu za kurs) — Economy.player_money i
## Paintings.expertise są migawkowane PER GRACZ
## (Players._capture_active/_apply_snapshot); przełączenie aktywnego gracza
## wcześniej przypisałoby zdobytą eksperckość złej osobie.
func _end_course_turn() -> void:
	Players.pass_turn_to_earliest_player()
	_update_info()


func _update_info() -> void:
	location_label.text = tr("%s\n%s") % [Cities.get_city_name(Travel.current_city), Calendar.format_day(Players.active_day())]
	money_label.text = tr("%.0f M") % Economy.player_money

	var at_max := Paintings.expertise >= Paintings.MAX_EXPERTISE
	expertise_label.text = tr("Eksperckość: %.0f%%") % [Paintings.expertise * 100.0] + (tr(" (maksimum)") if at_max else "")
	expertise_puzzle.set_progress(Paintings.expertise)

	## Zgłoszenie użytkownika: patrz komentarz w _on_train_pressed — przycisk
	## disabled, żeby od razu było widać, że dalsze kursy już nic nie dadzą,
	## zamiast pozwalać płacić za nie w nieskończoność.
	course_button.disabled = at_max
