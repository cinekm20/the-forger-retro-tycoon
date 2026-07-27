extends Control
## Wyścigi konne — zakłady rozstrzygane od razu (bez animacji, którą podepniemy
## po dojściu grafiki). Patrz GDD.md pkt. 4.4.
##
## Zgłoszone przez użytkownika: limit Players.DAYS_PER_TURN (7 dni, TA SAMA
## stała co skok "Koniec tury") między zakładami — bez tego dało się postawić
## nieskończenie wiele zakładów w obrębie jednej tury. Players.last_race_day/
## days_since_last_race (Tor B, WŁASNY czas aktywnego gracza) pilnują tego
## per gracz, patrz komentarz tam.

const HORSES := [
	{"name": "Komet", "odds": 2.0, "image": "res://art/horses/komet.jpg"},
	{"name": "Grom", "odds": 3.5, "image": "res://art/horses/grom.jpg"},
	{"name": "Cyklon", "odds": 5.0, "image": "res://art/horses/cyklon.jpg"},
	{"name": "Błyskawica", "odds": 8.0, "image": "res://art/horses/blyskawica.jpg"},
	{"name": "Wicher", "odds": 12.0, "image": "res://art/horses/wicher.jpg"},
]

var horse_option: OptionButton
var bet_spin: SpinBox
var bet_button: Button
var result_label: Label
var cooldown_label: Label
var info_label: Label


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/races.jpg")
	## use_menu_frame=false + ALIGNMENT_BEGIN + JEDEN rozpychacz na końcu:
	## zgłoszone przez użytkownika — ozdobna ramka znika, nazwa ekranu zostaje
	## przypięta na samej górze, przycisk powrotu na samym dole. Treść leci
	## zaraz pod tytułem (bez rozpychacza między nimi) — przy krótkiej treści
	## (jak tu: kilka linii kursów + jeden rząd zakładu) dwa rozpychacze
	## symetrycznie rozsuwałyby pustą przestrzeń na górę I dół środka,
	## zostawiając przycisk powrotu daleko od faktycznej krawędzi ekranu.
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Wyścigi konne")
	ScreenHelpers.make_turn_indicator(root)

	## Portret konia (wgrany, docs/GRAFIKA_LEONARDO.md §5) obok kursu — po
	## cichu bez obrazka, jeśli plik jeszcze nie istnieje, tak jak wszystkie
	## opcjonalne grafiki w tej grze.
	for horse in HORSES:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		root.add_child(row)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(56, 56)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var image_path: String = horse["image"]
		if ResourceLoader.exists(image_path):
			portrait.texture = load(image_path)
		row.add_child(portrait)

		var label := Label.new()
		label.text = tr("%s — kurs ×%.1f") % [horse["name"], horse["odds"]]
		label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		row.add_child(label)

	var bet_row := HBoxContainer.new()
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bet_row)

	horse_option = OptionButton.new()
	horse_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	for horse in HORSES:
		horse_option.add_item(horse["name"])
	bet_row.add_child(horse_option)

	bet_spin = SpinBox.new()
	bet_spin.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	bet_spin.min_value = 100
	bet_spin.max_value = 50000
	bet_spin.step = 100
	bet_spin.value = 500
	bet_row.add_child(bet_spin)

	bet_button = ScreenHelpers.make_button(root, "Postaw zakład", _on_bet_pressed)

	result_label = ScreenHelpers.make_label(root, "")
	cooldown_label = ScreenHelpers.make_label(root, "")
	info_label = ScreenHelpers.make_label(root, "")

	## Ozdobna skrzynka Art Deco w prawym dolnym rogu, TA SAMA co boczny
	## panel na TravelMap.gd/Hub.gd — zgłoszone przez użytkownika: przycisk
	## powrotu ma wyglądać tak samo na wszystkich ekranach (oprócz Plantacji).
	## Zakotwiczona niezależnie od `root`, więc bez rozpychacza.
	ScreenHelpers.make_boxed_back_button(self)

	_update_info()
	_update_cooldown_status()


func _pick_winner_index() -> int:
	var weights: Array[float] = []
	var total_weight := 0.0
	for horse in HORSES:
		var weight: float = 1.0 / horse["odds"]
		weights.append(weight)
		total_weight += weight

	var roll := randf() * total_weight
	var cumulative := 0.0
	for i in weights.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return i
	return weights.size() - 1


func _on_bet_pressed() -> void:
	## Podwójne zabezpieczenie — przycisk i tak jest disabled w trakcie
	## odliczania (patrz _update_cooldown_status), ale gdyby coś odświeżyło
	## stan między kliknięciami, zakład i tak nie powinien przejść.
	if Players.days_since_last_race() < Players.DAYS_PER_TURN:
		return

	var bet: float = bet_spin.value
	if not Economy.spend(bet):
		result_label.text = tr("Za mało gotówki na taki zakład.")
		return

	var chosen_index := horse_option.selected
	var winner_index := _pick_winner_index()
	var winner: Dictionary = HORSES[winner_index]

	if winner_index == chosen_index:
		var payout: float = bet * HORSES[chosen_index]["odds"]
		Economy.earn(payout)
		result_label.text = tr("Wygrywa %s! Wygrana: %.0f M") % [winner["name"], payout]
	else:
		result_label.text = tr("Wygrywa %s. Twój koń nie zwyciężył — zakład przepadł.") % winner["name"]

	Players.record_race()
	_update_info()
	_update_cooldown_status()


func _update_info() -> void:
	info_label.text = tr("Gotówka: %.0f M") % Economy.player_money


## Osobna od _update_info/result_label — zgłoszone przez użytkownika: limit
## między zakładami. cooldown_label (nie result_label) dostaje ten komunikat,
## żeby nie zamazywać wyniku WŁAŚNIE rozstrzygniętego wyścigu przy odświeżeniu
## zaraz po _on_bet_pressed.
func _update_cooldown_status() -> void:
	var days_left := Players.DAYS_PER_TURN - Players.days_since_last_race()
	bet_button.disabled = days_left > 0
	cooldown_label.text = tr("Następny zakład możliwy za %d dni.") % days_left if days_left > 0 else ""
