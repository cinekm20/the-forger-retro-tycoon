extends Control
## Wyścigi konne. Patrz GDD.md pkt. 4.4.
##
## Zgłoszenie użytkownika: wynik nie może być oczywisty od razu, wyścig ma
## trwać min. 30 sekund, z przewijanym torem 2D i realnymi zmianami
## prowadzenia — cała ta animacja jest w RaceTrackView.gd (scripts/ui/),
## Races.gd tylko: (1) ustala zwycięzcę OD RAZU przez _pick_winner_index(),
## dokładnie jak wcześniej, (2) buduje RaceTrackView i czeka na jego sygnał
## `finished`, (3) DOPIERO wtedy nalicza wypłatę/tekst wyniku — czyli ta sama
## logika ekonomiczna co przedtem, tylko przesunięta na koniec animacji
## zamiast natychmiast po kliknięciu.
##
## Zgłoszone przez użytkownika: limit Players.DAYS_PER_TURN (7 dni, TA SAMA
## stała co skok "Koniec tury") między zakładami — bez tego dało się postawić
## nieskończenie wiele zakładów w obrębie jednej tury. Players.last_race_day/
## days_since_last_race (Tor B, WŁASNY czas aktywnego gracza) pilnują tego
## per gracz, patrz komentarz tam.
##
## Tożsamość koni (nazwa/portret) jest tu, ale KURSY już nie — zgłoszone przez
## użytkownika: kursy mają dryfować jak ceny na Giełdzie/Rynku, nie być raz na
## zawsze ustawioną stałą. Przeniesione do autoloadu Horses.gd (Tor A, wspólny
## dla wszystkich graczy, podłączony do Calendar.day_advanced) — patrz
## komentarz tam. horse_ids ustala STAŁĄ kolejność (Dictionary.keys() w
## GDScript zachowuje kolejność wstawienia, ale trzymamy osobną kopię, żeby
## indeks z horse_option.selected zawsze trafiał w ten sam koń, niezależnie
## od tego, co się dzieje z Horses.HORSES).
var horse_ids: Array[String] = []

const RaceTrackScript := preload("res://scripts/ui/RaceTrackView.gd")

var horse_option: OptionButton
var bet_spin: SpinBox
var bet_button: Button
var result_label: Label
var cooldown_label: Label
var location_label: Label
var money_label: Label
var back_btn: Button

## Widok animacji, budowany dopiero w _on_bet_pressed (ten sam powód co
## AuctionHouse.gd _build_bottom_menu_box — nie trzymamy pustego węzła
## czekającego bezczynnie, tylko tworzymy go w momencie, gdy faktycznie jest
## potrzebny). is_racing to DODATKOWE zabezpieczenie przed drugim zakładem w
## trakcie animacji (bet_button i tak jest disabled, patrz _on_bet_pressed).
var race_track: Control
var is_racing: bool = false


func _ready() -> void:
	Music.play_track(Music.RACES_TRACK)
	ScreenHelpers.make_background(self, "res://art/backgrounds/races.jpg")
	ScreenHelpers.make_instructions_button(self)
	## Zgłoszenie użytkownika: gotówka MA być wyłącznie w skrzynce w prawym
	## górnym rogu, dokładnie jak w Giełdzie/Rynku (ScreenHelpers.make_corner_status_row),
	## zamiast osobnej etykiety "Gotówka: X M" w środku ekranu.
	var corner := ScreenHelpers.make_corner_status_row(self, "", "")
	location_label = corner["left"]
	money_label = corner["right"]

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

	## Odstęp o stałej wysokości pod tytułem — w trybie solo (bez wskaźnika
	## tury) portrety koni zaczynały się od razu pod tytułem, na tej samej
	## wysokości co skrzynki lokalizacji/gotówki w rogach (ScreenHelpers.
	## make_corner_status_row, zepchnięte niżej pod przycisk instrukcji, patrz
	## ScreenHelpers.CORNER_BUTTON_RESERVED_HEIGHT) — pierwszy i ostatni koń w
	## rzędzie są dość szerocy, żeby fizycznie sięgać w poziomie do obu tych
	## skrzynek, więc nachodziły na nie (zgłoszone przez użytkownika na zrzucie
	## ekranu). Wysokość dobrana tak, żeby rząd koni zaczynał się bezpiecznie
	## poniżej dolnej krawędzi obu skrzynek.
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 80)
	root.add_child(top_spacer)

	horse_ids.assign(Horses.HORSES.keys())

	## Zgłoszenie użytkownika: konie mają stać OBOK SIEBIE (nie jeden pod
	## drugim), z większym portretem, a pod nim nazwa i jeszcze niżej kurs —
	## zamiast poprzedniego pionowego rzędu "portret + jeden napis z obojgiem
	## naraz". Portret (wgrany, docs/GRAFIKA_LEONARDO.md §5) po cichu bez
	## obrazka, jeśli plik jeszcze nie istnieje, tak jak wszystkie opcjonalne
	## grafiki w tej grze. Kurs czytany z Horses.current_odds PRZY BUDOWANIU
	## ekranu — nie musi się odświeżać w trakcie stania na tym ekranie, bo
	## Kalendarz i tak przesuwa się tylko przy akcjach na innych ekranach
	## (Koniec tury/podróż/Szkoła sztuki).
	var horses_row := HBoxContainer.new()
	horses_row.alignment = BoxContainer.ALIGNMENT_CENTER
	horses_row.add_theme_constant_override("separation", 28)
	root.add_child(horses_row)

	for horse_id in horse_ids:
		var horse: Dictionary = Horses.HORSES[horse_id]
		var card := VBoxContainer.new()
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_theme_constant_override("separation", 4)
		horses_row.add_child(card)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(160, 160)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var image_path: String = horse["image"]
		if ResourceLoader.exists(image_path):
			portrait.texture = load(image_path)
		card.add_child(portrait)

		var name_label := Label.new()
		name_label.text = horse["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		name_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		card.add_child(name_label)

		var odds_label := Label.new()
		odds_label.text = tr("kurs ×%.1f") % Horses.get_odds(horse_id)
		odds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		odds_label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		odds_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
		card.add_child(odds_label)

	result_label = ScreenHelpers.make_label(root, "")
	cooldown_label = ScreenHelpers.make_label(root, "")

	## Zgłoszenie użytkownika: zakład (koń + kwota + przycisk) ma być "ładnie
	## wyeksponowany" i dołączony do TEJ SAMEJ skrzynki w prawym dolnym rogu
	## co przycisk powrotu — jedna wspólna ozdobna ramka Art Deco (złota
	## ramka, MenuFrame), nie osobna skrzynka w środku ekranu. TA SAMA
	## make_root_bottom co boczny panel na TravelMap.gd/Hub.gd, ale tu
	## dokładamy WŁASNE dzieci (bet_row, przycisk zakładu, przycisk powrotu)
	## zamiast gotowego make_boxed_back_button (który tworzy swoją OSOBNĄ
	## skrzynkę) — stąd surowe wywołania make_root_bottom/make_back_button.
	var corner_box := ScreenHelpers.make_root_bottom(self, true)

	var bet_row := HBoxContainer.new()
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	corner_box.add_child(bet_row)

	horse_option = OptionButton.new()
	horse_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	for horse_id in horse_ids:
		horse_option.add_item(Horses.HORSES[horse_id]["name"])
	bet_row.add_child(horse_option)

	bet_spin = SpinBox.new()
	bet_spin.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	bet_spin.min_value = 100
	bet_spin.max_value = 50000
	bet_spin.step = 100
	bet_spin.value = 500
	bet_row.add_child(bet_spin)

	bet_button = ScreenHelpers.make_button(corner_box, "Postaw zakład", _on_bet_pressed)

	## Zmienna (nie lokalny wywołanie) — disabled na czas animacji wyścigu,
	## patrz _on_bet_pressed/_on_race_finished, żeby nie dało się wyjść z
	## ekranu w trakcie.
	back_btn = ScreenHelpers.make_back_button(corner_box)

	_update_info()
	_update_cooldown_status()


func _pick_winner_index() -> int:
	var weights: Array[float] = []
	var total_weight := 0.0
	for horse_id in horse_ids:
		var weight: float = 1.0 / Horses.get_odds(horse_id)
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
	## odliczania (patrz _update_cooldown_status) I w trakcie animacji (patrz
	## niżej), ale gdyby coś odświeżyło stan między kliknięciami, zakład i tak
	## nie powinien przejść.
	if Players.days_since_last_race() < Players.DAYS_PER_TURN or is_racing:
		return

	var bet: float = bet_spin.value
	if not Economy.spend(bet):
		result_label.text = tr("Za mało gotówki na taki zakład.")
		return

	## Zwycięzca ustalony OD RAZU, dokładnie jak przed dodaniem animacji —
	## RaceTrackView tylko wizualizuje ten JUŻ ustalony wynik, nigdy go nie
	## zmienia. Wypłata/tekst wyniku czekają na _on_race_finished.
	var chosen_index := horse_option.selected
	var winner_index := _pick_winner_index()

	result_label.text = ""
	is_racing = true
	bet_button.disabled = true
	horse_option.disabled = true
	bet_spin.editable = false
	back_btn.disabled = true

	var image_paths: Array[String] = []
	var names: Array[String] = []
	for horse_id in horse_ids:
		image_paths.append(Horses.HORSES[horse_id]["image"])
		names.append(Horses.HORSES[horse_id]["name"])

	race_track = RaceTrackScript.new()
	add_child(race_track)
	race_track.finished.connect(_on_race_finished.bind(winner_index, chosen_index, bet))
	race_track.setup(image_paths, names, winner_index, get_viewport_rect().size)


func _on_race_finished(winner_index: int, chosen_index: int, bet: float) -> void:
	race_track.queue_free()
	race_track = null
	is_racing = false
	horse_option.disabled = false
	bet_spin.editable = true
	back_btn.disabled = false

	var winner_id: String = horse_ids[winner_index]
	var winner: Dictionary = Horses.HORSES[winner_id]

	if winner_index == chosen_index:
		var payout: float = bet * Horses.get_odds(horse_ids[chosen_index])
		Economy.earn(payout)
		result_label.text = tr("Wygrywa %s! Wygrana: %.0f M") % [winner["name"], payout]
	else:
		result_label.text = tr("Wygrywa %s. Twój koń nie zwyciężył — zakład przepadł.") % winner["name"]

	Players.record_race()
	_update_info()
	_update_cooldown_status()


func _update_info() -> void:
	location_label.text = tr("%s\n%s") % [Cities.get_city_name(Travel.current_city), Calendar.format_day(Players.active_day())]
	money_label.text = tr("%.0f M") % Economy.player_money


## Osobna od _update_info/result_label — zgłoszone przez użytkownika: limit
## między zakładami. cooldown_label (nie result_label) dostaje ten komunikat,
## żeby nie zamazywać wyniku WŁAŚNIE rozstrzygniętego wyścigu przy odświeżeniu
## zaraz po _on_bet_pressed.
func _update_cooldown_status() -> void:
	var days_left := Players.DAYS_PER_TURN - Players.days_since_last_race()
	bet_button.disabled = days_left > 0
	cooldown_label.text = tr("Następny zakład możliwy za %d dni.") % days_left if days_left > 0 else ""
