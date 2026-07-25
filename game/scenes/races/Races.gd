extends Control
## Wyścigi konne — zakłady rozstrzygane od razu (bez animacji, którą podepniemy
## po dojściu grafiki). Patrz GDD.md pkt. 4.4.

const HORSES := [
	{"name": "Komet", "odds": 2.0},
	{"name": "Grom", "odds": 3.5},
	{"name": "Cyklon", "odds": 5.0},
	{"name": "Błyskawica", "odds": 8.0},
	{"name": "Wicher", "odds": 12.0},
]

var horse_option: OptionButton
var bet_spin: SpinBox
var result_label: Label
var info_label: Label


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/races.jpg")
	## use_menu_frame=false + ALIGNMENT_BEGIN + rozpychacze: zgłoszone przez
	## użytkownika — ozdobna ramka znika, nazwa ekranu zostaje przypięta na
	## samej górze, przycisk powrotu na samym dole (ten sam wzorzec co
	## Gallery.gd _build_category_detail_view).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Wyścigi konne")
	ScreenHelpers.make_turn_indicator(root)
	root.add_child(ScreenHelpers.make_expand_spacer())

	for horse in HORSES:
		ScreenHelpers.make_label(root, tr("%s — kurs ×%.1f") % [horse["name"], horse["odds"]])

	var bet_row := HBoxContainer.new()
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bet_row)

	horse_option = OptionButton.new()
	for horse in HORSES:
		horse_option.add_item(horse["name"])
	bet_row.add_child(horse_option)

	bet_spin = SpinBox.new()
	bet_spin.min_value = 100
	bet_spin.max_value = 50000
	bet_spin.step = 100
	bet_spin.value = 500
	bet_row.add_child(bet_spin)

	ScreenHelpers.make_button(root, "Postaw zakład", _on_bet_pressed)

	result_label = ScreenHelpers.make_label(root, "")
	info_label = ScreenHelpers.make_label(root, "")

	root.add_child(ScreenHelpers.make_expand_spacer())
	ScreenHelpers.make_back_button(root)

	_update_info()


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

	_update_info()


func _update_info() -> void:
	info_label.text = tr("Gotówka: %.0f M") % Economy.player_money
