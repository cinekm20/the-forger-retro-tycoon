extends Control
## Szkoła sztuki — kurs podnoszący eksperckość (Paintings.expertise), która
## zwiększa szansę na wczesne ostrzeżenie o podróbce w domu aukcyjnym.
## Patrz GDD.md pkt. 4.6.

const TRAINING_COST := 2000.0
const TRAINING_DAYS := 14
const EXPERTISE_GAIN := 0.1

var info_label: Label


func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Szkoła sztuki")
	ScreenHelpers.make_turn_indicator(root)

	info_label = ScreenHelpers.make_label(root, "")

	ScreenHelpers.make_button(
		root,
		tr("Kurs (%.0f M, %d dni)") % [TRAINING_COST, TRAINING_DAYS],
		_on_train_pressed,
	)

	ScreenHelpers.make_back_button(root)
	_update_info()


func _on_train_pressed() -> void:
	if not Economy.spend(TRAINING_COST):
		info_label.text = "Za mało gotówki na kurs."
		return
	Paintings.increase_expertise(EXPERTISE_GAIN)
	Calendar.advance_days(TRAINING_DAYS)
	_update_info()
	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)


func _update_info() -> void:
	## Jawnie wypisane, co eksperckość robi (a czego NIE robi) — tester
	## zgłosił, że spodziewał się dokładniejszej szacowanej wartości obrazu
	## podczas aukcji i nie widział różnicy, bo to nie jest jej działanie.
	info_label.text = tr("Eksperckość: %.0f%% — zwiększa szansę na wczesne ostrzeżenie o podróbce w Domu aukcyjnym (NIE wpływa na szacowaną wartość obrazu)\nGotówka: %.0f M | Data: %s") % [
		Paintings.expertise * 100.0, Economy.player_money, Calendar.get_date_string(),
	]
