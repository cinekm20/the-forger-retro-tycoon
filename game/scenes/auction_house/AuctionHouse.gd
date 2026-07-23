extends Control
## Dom aukcyjny — działająca licytacja przeciw AI (w tym Vico).
## Patrz GDD.md pkt. 4.5, docs/MECHANIKI_EKONOMICZNE.md pkt. 9.
##
## Aukcje trzyma harmonogram w Auctions.gd (jedno miasto + jeden dzień na
## raz, tak jak w oryginale — patrz zrzut ekranu użytkownika z boksem
## "NEXT AUCTION IS: 17.1.1918 BERLIN"). Ten ekran już NIE pozwala klikać
## "Nowa aukcja" bez ograniczeń (użytkownik: "aucje powinny być dostępne
## tylko w wybranym czasie, nie żeby mogę ileś obrazów na raz kupić") —
## jeśli gracz jest w mieście aukcyjnym poza terminem, widzi tylko
## informację, kiedy i gdzie jest następna aukcja.

const BID_INCREMENT_RATIO := 0.1  ## gracz podbija o 10% szacunkowej wartości
const BID_TIME_LIMIT := 20.0  ## sekundy realnego czasu na podbicie oferty

var current_number: int = -1
var current_bid: float = 0.0
var current_leader: String = ""  ## "" = nikt, "player", albo id rywala
var current_forgery_warning: bool = false  ## losowane raz na aukcję w _start_new_auction

var auction_active: bool = false  ## true = odlicza czas na kolejny ruch gracza
var bid_time_remaining: float = 0.0
## Rywal nie czeka już zawsze do samego końca licznika, żeby ewentualnie
## podbić — losowy moment w trakcie odliczania, w którym sprawdzamy, czy
## któryś rywal podbija (patrz _start_bid_timer/_process).
var rival_check_threshold: float = 0.0
var rival_checked_this_round: bool = false

var schedule_label: Label
var painting_label: Label
var bid_label: Label
var money_label: Label
var warning_label: Label
var status_label: Label
var timer_label: Label
var timer_bar: ProgressBar
var painting_texture_rect: TextureRect
var leader_portrait_rect: TextureRect
var bid_btn: Button
var resolve_btn: Button

## 190 = 225 pomniejszone o kolejne ~15% (użytkownik: najpierw -25% z 300,
## potem jeszcze -15%) — ekran nie ma już ramki+ScrollContainer (użytkownik:
## "nie ma być ramki na cały ekran"), więc treść musi zmieścić się w jednym,
## niescrollowanym widoku bez przycinania dolnych przycisków.
const PAINTING_DISPLAY_SIZE := Vector2(190, 190)


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/auction_house.jpg")

	## Gotówka w stałej skrzynce w prawym górnym rogu (jak w Hubie/Giełdzie),
	## NIE w wierszu z ofertą — użytkownik zgłosił, że powinna zostać na górze,
	## niezależnie od reszty licytacji. Lewa skrzynka (nieużywana tu) jest po
	## prostu ukryta, zamiast pokazywać pustą ramkę bez treści.
	var corner := ScreenHelpers.make_corner_status_row(self, "", "")
	corner["left"].get_parent().visible = false
	money_label = corner["right"]

	## use_menu_frame=false: użytkownik zgłosił, że ozdobna ramka na cały
	## ekran (ta sama co w Hub/TravelMap) tu tylko przeszkadzała — ma zostać
	## WYŁĄCZNIE oprawiona skrzynka do podbijania oferty w prawym dolnym rogu
	## (make_root_bottom w _build_active_auction_ui, osobny wywołanie, dalej
	## z use_menu_frame=true), reszta ekranu leży bezpośrednio na tle.
	var root := ScreenHelpers.make_root(self, false)
	ScreenHelpers.make_title(root, "Dom aukcyjny")
	ScreenHelpers.make_turn_indicator(root)

	schedule_label = ScreenHelpers.make_info_box(root, "")

	if not Auctions.is_open(Travel.current_city):
		ScreenHelpers.make_label(root, tr("W tym mieście nie odbywa się teraz żadna aukcja.\nWróć w podanym terminie."))
		schedule_label.text = Auctions.get_schedule_string()
		ScreenHelpers.make_back_button(root)
		return

	_build_active_auction_ui(root)
	_start_new_auction()


## Buduje UI aktywnej licytacji. Nazwa/opis obrazu to oprawiona skrzynka
## PRZY GÓRZE ekranu (obok skrzynki terminu aukcji) — użytkownik zgłosił, że
## nieoprawiony tekst pod obrazem nachodził na pasek akcji w prawym dolnym
## rogu. Sam obraz NIE ma już grubej złotej ramki wokół (użytkownik: "nie
## powinna być taka ogromna rama") — leży bezpośrednio na tle karty, żeby
## wyglądał jak wstawiony w scenę, a nie zamknięty w osobnym pudełku. Malejący
## czas na podbicie + przyciski są w OSOBNYM pasku przyklejonym do prawego
## dolnego rogu ekranu (make_root_bottom) — zgodnie z prośbą użytkownika, żeby
## akcje licytacji nie leżały wymieszane w pionowej liście opisów.
func _build_active_auction_ui(root: VBoxContainer) -> void:
	## make_root(false) domyślnie centruje wszystkie dzieci jako jedną grupę
	## (ALIGNMENT_CENTER) — użytkownik zgłosił, że górne skrzynki (termin +
	## nazwa obrazu) mają być na SAMEJ górze ekranu, a dolne (oferta/gotówka +
	## status + powrót) na SAMYM dole, z obrazem gdzieś pośrodku. BEGIN +
	## dwa rozciągliwe spacery (jeden przed obrazem, jeden przed dolnym
	## klastrem) rozpychają te trzy grupy do krawędzi zamiast trzymać je
	## zbite na środku.
	root.alignment = BoxContainer.ALIGNMENT_BEGIN

	painting_label = ScreenHelpers.make_info_box(root, "")
	painting_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	painting_label.custom_minimum_size = Vector2(760, 0)

	root.add_child(_make_expand_spacer())

	var painting_center := CenterContainer.new()
	root.add_child(painting_center)

	painting_texture_rect = TextureRect.new()
	painting_texture_rect.custom_minimum_size = PAINTING_DISPLAY_SIZE
	painting_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painting_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	painting_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painting_center.add_child(painting_texture_rect)

	root.add_child(_make_expand_spacer())

	warning_label = ScreenHelpers.make_label(root, "")

	## Jedna wspólna, oprawiona skrzynka (make_boxed_row) na portret PROWADZĄCEGO
	## rywala + tekst oferty — użytkownik zgłosił, że portret ma być W ŚRODKU
	## tej ramki (nie osobno, obok niej) i trochę większy.
	var bid_row := ScreenHelpers.make_boxed_row(root)

	leader_portrait_rect = TextureRect.new()
	leader_portrait_rect.custom_minimum_size = Vector2(84, 84)
	leader_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leader_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	leader_portrait_rect.visible = false
	bid_row.add_child(leader_portrait_rect)

	## font_size 26 (zamiast domyślnych 19) — użytkownik zgłosił, że oferta i
	## informacja "kto prowadzi" powinny być trochę większe. autowrap +
	## custom_minimum_size (SZEROKOŚĆ i WYSOKOŚĆ oba stałe): długie imię
	## rywala (np. "Contessa Isabella Moreau") mogło zawinąć się na dodatkową
	## linię, zmieniając wysokość skrzynki i przesuwając layout — zgłoszone
	## przez użytkownika, ten sam problem co wcześniej na ekranie Plantacji.
	## Stała wysokość (2 pełne linie przy font_size 26) gwarantuje, że skrzynka
	## nigdy się nie rusza, niezależnie od długości imienia.
	bid_label = Label.new()
	bid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bid_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
	bid_label.add_theme_font_size_override("font_size", 26)
	bid_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bid_label.custom_minimum_size = Vector2(340, 70)
	bid_row.add_child(bid_label)

	status_label = ScreenHelpers.make_label(root, "")
	ScreenHelpers.make_back_button(root)

	var action_root := ScreenHelpers.make_root_bottom(self, true, 380.0, true)
	timer_label = ScreenHelpers.make_label(action_root, "")
	timer_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)

	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size = Vector2(280, 20)
	timer_bar.show_percentage = false
	timer_bar.min_value = 0.0
	timer_bar.max_value = BID_TIME_LIMIT
	timer_bar.step = 0.01
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(ScreenHelpers.COLOR_BURGUNDY_DARK.r, ScreenHelpers.COLOR_BURGUNDY_DARK.g, ScreenHelpers.COLOR_BURGUNDY_DARK.b, 0.9)
	bar_bg.border_color = ScreenHelpers.COLOR_GOLD
	bar_bg.set_border_width_all(2)
	bar_bg.set_corner_radius_all(4)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = ScreenHelpers.COLOR_GOLD_BRIGHT
	bar_fill.set_corner_radius_all(4)
	timer_bar.add_theme_stylebox_override("background", bar_bg)
	timer_bar.add_theme_stylebox_override("fill", bar_fill)
	action_root.add_child(timer_bar)

	bid_btn = ScreenHelpers.make_button(action_root, tr("Podbij (+10%)"), _on_bid_pressed)
	resolve_btn = ScreenHelpers.make_button(action_root, tr("Zakończ rundę"), _on_resolve_round_pressed)


static func _make_expand_spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _process(delta: float) -> void:
	if not auction_active:
		return
	bid_time_remaining -= delta
	if bid_time_remaining <= 0.0:
		bid_time_remaining = 0.0
		auction_active = false
		timer_label.text = tr("Czas minął!")
		timer_bar.value = 0.0
		_on_time_expired()
		return

	timer_label.text = tr("Czas na podbicie: %d s") % int(ceil(bid_time_remaining))
	timer_bar.value = bid_time_remaining

	if not rival_checked_this_round and bid_time_remaining <= rival_check_threshold:
		rival_checked_this_round = true
		_try_rival_counter_bid()


func _start_bid_timer() -> void:
	bid_time_remaining = BID_TIME_LIMIT
	auction_active = true
	timer_bar.value = BID_TIME_LIMIT
	rival_checked_this_round = false
	rival_check_threshold = randf_range(2.0, BID_TIME_LIMIT - 3.0)


func _on_time_expired() -> void:
	status_label.text = tr("Zabrakło czasu na podbicie — rywale odpowiadają.")
	_on_resolve_round_pressed()


## Sprawdza, czy któryś rywal podbija bieżącą ofertę — wywoływane zarówno z
## losowego, wcześniejszego momentu w trakcie odliczania (_process), jak i
## przy "Zakończ rundę"/wygaśnięciu czasu. Zwraca true, jeśli ktoś podbił
## (i licznik został zresetowany na nową rundę) — wywołujący wie wtedy, że
## nie powinien od razu rozstrzygać aukcji.
func _try_rival_counter_bid() -> bool:
	var estimated_value := Paintings.get_estimated_value(current_number)
	var best_rival_id := ""
	var best_rival_bid := current_bid
	for rival in AIPlayers.rivals:
		## Rywal, który już prowadzi, nie może "podbić samego siebie" —
		## zgłoszone przez użytkownika: ten sam przeciwnik nie powinien
		## podbijać ofertę pod rząd, musi ustąpić miejsca komuś innemu (albo
		## nikomu, jeśli nikt inny nie chce przebić).
		if rival["id"] == current_leader:
			continue
		var rival_bid: float = AIPlayers.decide_bid(rival["id"], current_bid, estimated_value)
		if rival_bid > best_rival_bid:
			best_rival_bid = rival_bid
			best_rival_id = rival["id"]

	if best_rival_id == "":
		return false

	current_bid = best_rival_bid
	current_leader = best_rival_id
	status_label.text = tr("%s podbija ofertę.") % AIPlayers.get_rival(best_rival_id)["name"]
	_update_labels()
	_start_bid_timer()
	return true


func _start_new_auction() -> void:
	current_number = Auctions.get_current_painting_number()
	var estimated_value := Paintings.get_estimated_value(current_number)
	current_bid = estimated_value * 0.2
	current_leader = ""
	current_forgery_warning = Paintings.warns_about_forgery(current_number)
	_update_labels()
	_start_bid_timer()


func _on_bid_pressed() -> void:
	var estimated_value := Paintings.get_estimated_value(current_number)
	var next_bid := current_bid + estimated_value * BID_INCREMENT_RATIO
	if not Economy.can_afford(next_bid):
		status_label.text = tr("Za mało gotówki na taką ofertę.")
		return
	current_bid = next_bid
	current_leader = "player"
	_update_labels()
	_start_bid_timer()


func _on_resolve_round_pressed() -> void:
	if _try_rival_counter_bid():
		return
	_resolve_auction()


func _resolve_auction() -> void:
	auction_active = false
	bid_btn.disabled = true
	resolve_btn.disabled = true
	timer_label.text = ""
	timer_bar.value = 0.0

	if current_leader == "player":
		Economy.spend(current_bid)
		if Paintings.is_forgery_by_duplicate(current_number):
			status_label.text = tr("To była FAŁSZYWKA! Pieniądze przepadły, obraz nie trafia do kolekcji.")
		else:
			Paintings.catalogue(current_number)
			status_label.text = tr("Wygrywasz aukcję! Obraz trafia do kolekcji (%d/%d).") % [
				Paintings.owned_count(), Paintings.win_threshold,
			]
	elif current_leader == "":
		status_label.text = tr("Nikt nie licytował — obraz zostaje niesprzedany.")
	else:
		AIPlayers.award_painting(current_leader, current_number, current_bid)
		status_label.text = tr("%s wygrywa aukcję.") % AIPlayers.get_rival(current_leader)["name"]
	_update_labels()

	Auctions.resolve_and_reschedule()
	schedule_label.text = Auctions.get_schedule_string()
	status_label.text += "\n" + Auctions.get_schedule_string()

	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)


func _update_labels() -> void:
	schedule_label.text = tr("Aukcja w toku: %s — %s") % [Cities.get_city_name(Travel.current_city), Calendar.get_date_string()]

	var category: String = Paintings.get_category(current_number)
	var category_name: String = Paintings.CATEGORY_NAMES.get(category, category)
	var info := Paintings.get_painting_info(current_number)
	if not info.is_empty():
		painting_label.text = tr("Na sprzedaż: „%s” — %s, %s (%s) — szac. wartość %.0f M") % [
			tr(info["title"]), info["artist"], info["year"], category_name, Paintings.get_estimated_value(current_number),
		]
	else:
		painting_label.text = tr("Na sprzedaż: obraz nr %d (%s) — szac. wartość %.0f M") % [
			current_number, category_name, Paintings.get_estimated_value(current_number),
		]

	## Grafika obrazu opcjonalna — jeśli plik danego numeru jeszcze nie
	## istnieje (docs/GRAFIKA_LEONARDO.md §7), ramka zostaje pusta zamiast
	## crashować na load() brakującego pliku. is_fake: prawdziwa fałszywość
	## (Paintings.is_forgery_by_duplicate), NIEZALEŻNIE od tego, czy
	## ekspertyza akurat wyświetliła ostrzeżenie (warns_about_forgery) — więc
	## bystry gracz może rozpoznać podróbkę "na oko", nawet bez ostrzeżenia.
	var texture_path := Paintings.get_texture_path(current_number, Paintings.is_forgery_by_duplicate(current_number))
	painting_texture_rect.texture = load(texture_path) if ResourceLoader.exists(texture_path) else null

	## visible = false (nie tylko pusty tekst) — bez ramki+ScrollContainer ten
	## ekran ma ograniczoną wysokość, więc pusty wiersz niepotrzebnie zabierałby
	## miejsce (separacja VBoxContainer nadal by się liczyła).
	warning_label.visible = current_forgery_warning
	if current_forgery_warning:
		warning_label.text = tr("⚠ Szkoła Sztuki ostrzega: ten numer już masz w kolekcji — to może być podróbka!")

	var leader_text := tr("nikt")
	leader_portrait_rect.visible = false
	if current_leader == "player":
		leader_text = tr("Ty")
	elif current_leader != "":
		leader_text = AIPlayers.get_rival(current_leader)["name"]
		var portrait_path := AIPlayers.get_portrait_path(current_leader)
		if ResourceLoader.exists(portrait_path):
			leader_portrait_rect.texture = load(portrait_path)
			leader_portrait_rect.visible = true
	## Bez dopisku "jeśli nikt Cię nie przebije — wygrywasz" — użytkownik
	## zgłosił, że ta trzecia linijka (widoczna tylko gdy prowadzi gracz)
	## zmieniała wysokość skrzynki i przesuwała layout; ma zawsze zostać
	## dokładnie dwuwierszowa, niezależnie od tego, kto prowadzi.
	bid_label.text = tr("Oferta: %.0f M\n(prowadzi: %s)") % [current_bid, leader_text]
	money_label.text = tr("Gotówka: %.0f M") % Economy.player_money
