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
const TRAINING_DAYS := 14
const EXPERTISE_GAIN_CORRECT := 0.15
const EXPERTISE_GAIN_WRONG := 0.05
const QUIZ_IMAGE_SIZE := 280.0

var info_label: Label
var course_button: Button
var quiz_section: VBoxContainer
var quiz_result_label: Label
var quiz_painting_number: int = -1


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/art_school.jpg")
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Szkoła sztuki")
	ScreenHelpers.make_turn_indicator(root)

	info_label = ScreenHelpers.make_label(root, "")
	## autowrap + custom_minimum_size (SZEROKOŚĆ i WYSOKOŚĆ oba stałe) —
	## pierwsza linia jest bardzo długa (całe zdanie o działaniu
	## eksperckości); bez zawijania renderowała się jako jeden, bardzo
	## szeroki wiersz wychodzący poza ramkę ekranu na wąskich/portretowych
	## rozdzielczościach (przegląd czytelności/dopasowania do rozdzielczości
	## na żądanie użytkownika). Stała wysokość rezerwuje miejsce na
	## najdłuższy możliwy wariant (zawinięta 1. linia + 2. linia
	## gotówka/data), żeby przycisk poniżej nigdy się nie przesuwał.
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_label.custom_minimum_size = Vector2(700, 110)

	course_button = ScreenHelpers.make_button(
		root,
		tr("Kurs (%.0f M, %d dni)") % [TRAINING_COST, TRAINING_DAYS],
		_on_train_pressed,
	)

	## Sekcja quizu — ukryta, dopóki nie wykupiony jest kurs. Podmienia się z
	## info_label/course_button (patrz _start_quiz/_close_quiz), żeby ekran
	## nie pokazywał obu naraz.
	quiz_section = VBoxContainer.new()
	quiz_section.visible = false
	root.add_child(quiz_section)

	ScreenHelpers.make_back_button(root)
	_update_info()


func _on_train_pressed() -> void:
	if not Economy.spend(TRAINING_COST):
		info_label.text = tr("Za mało gotówki na kurs.")
		return
	Calendar.advance_days(TRAINING_DAYS)
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
		_update_info()
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
	info_label.visible = false
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
	info_label.visible = true
	_update_info()


func _update_info() -> void:
	## Jawnie wypisane, co eksperckość robi (a czego NIE robi) — tester
	## zgłosił, że spodziewał się dokładniejszej szacowanej wartości obrazu
	## podczas aukcji i nie widział różnicy, bo to nie jest jej działanie.
	info_label.text = tr("Eksperckość: %.0f%% — zwiększa szansę na wczesne ostrzeżenie o podróbce w Domu aukcyjnym (NIE wpływa na szacowaną wartość obrazu)\nGotówka: %.0f M | Data: %s") % [
		Paintings.expertise * 100.0, Economy.player_money, Calendar.get_date_string(),
	]
