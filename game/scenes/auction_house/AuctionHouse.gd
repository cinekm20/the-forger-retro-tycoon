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
var back_btn: Button

## 268 = 190 (poprzedni rozmiar samego obrazu, patrz historia komentarza w
## _build_active_auction_ui) powiększone tak, żeby po doliczeniu ramki
## (art/icons/frame.png) WNĘTRZE ramki znów wychodziło na ~190×190 — ekran
## nie ma już ramki na CAŁY ekran + ScrollContainer (użytkownik: "nie ma być
## ramki na cały ekran"), więc treść musi zmieścić się w jednym,
## niescrollowanym widoku bez przycinania dolnych przycisków.
const FRAME_HOLDER_SIZE := Vector2(268, 268)
const FRAME_TEXTURE_PATH := "res://art/icons/frame.png"
## Ułamek FRAME_HOLDER_SIZE zajęty przez sam brzeg ramy z każdej strony —
## zmierzone na art/icons/frame.png (kwadratowy plik, kwadratowy otwór w
## środku, przezroczyste tło dookoła ramy — patrz poprawiony prompt w
## docs/GRAFIKA_LEONARDO.md §6). painting_texture_rect jest zakotwiczony
## dokładnie w tym ułamku, więc kwadratowy obraz (896×896) wypełnia otwór
## idealnie, bez żadnych pustych pasów.
const FRAME_INNER_INSET := 0.145


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
## rogu. Sam obraz ma teraz cienką ozdobną ramę (art/icons/frame.png,
## dostarczona przez użytkownika) — WCZEŚNIEJ obraz w ogóle nie miał ramki
## (użytkownik zgłosił wtedy, że natywnie rysowana rama wychodziła "ogromna"),
## ale ta grafika ma celowo cienki brzeg i duży kwadratowy otwór w środku
## (patrz docs/GRAFIKA_LEONARDO.md §6), więc nie zajmuje dużo miejsca. Malejący
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

	var frame_holder := Control.new()
	frame_holder.custom_minimum_size = FRAME_HOLDER_SIZE
	frame_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painting_center.add_child(frame_holder)

	## Rama dodana PIERWSZA (rysuje się pod spodem) — jej wnętrze na
	## frame.png jest w całości nieprzezroczyste (płaskie "puste płótno"),
	## więc dopiero obraz DODANY PO NIEJ (rysuje się na wierzchu, dokładnie w
	## ułamku FRAME_INNER_INSET) w pełni je zasłania, zostawiając widoczny
	## tylko ozdobny brzeg dookoła — bez tego kolejność odwrotna: rama
	## zasłoniłaby obraz.
	var frame_rect := TextureRect.new()
	frame_rect.texture = load(FRAME_TEXTURE_PATH)
	frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	## EXPAND_IGNORE_SIZE: bez tego minimalny rozmiar TextureRect to naturalny
	## rozmiar tekstury (frame.png = 1024×1024 px), który wygrywa z małym
	## FRAME_HOLDER_SIZE i rama renderuje się w swoim naturalnym, ogromnym
	## rozmiarze zamiast się zmniejszyć — zgłoszone przez użytkownika na
	## zrzucie ekranu (rama "jakby w ogóle nie zmniejszona").
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_holder.add_child(frame_rect)

	painting_texture_rect = TextureRect.new()
	painting_texture_rect.anchor_left = FRAME_INNER_INSET
	painting_texture_rect.anchor_top = FRAME_INNER_INSET
	painting_texture_rect.anchor_right = 1.0 - FRAME_INNER_INSET
	painting_texture_rect.anchor_bottom = 1.0 - FRAME_INNER_INSET
	painting_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painting_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	painting_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_holder.add_child(painting_texture_rect)

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
	resolve_btn = ScreenHelpers.make_button(action_root, tr("Rezygnuję z aukcji"), _on_resolve_round_pressed)

	## W TYM SAMYM, zawsze widocznym pasku co przyciski licytacji (nie w
	## środkowej kolumnie z opisem — tam przy dłuższym statusie/dłuższym
	## opisie obrazu potrafił wypaść poza dolną krawędź ekranu, bo root(false)
	## nie ma ScrollContainera, patrz zgłoszenie użytkownika ze zrzutem
	## ekranu: "nie widać klawisza powrót"). Podmienia się z bid_btn/resolve_btn
	## dopiero po rozstrzygnięciu aukcji (patrz _resolve_auction) — do tego
	## momentu ukryty, żeby nie dało się wyjść i wrócić do wciąż otwartej
	## aukcji (zgłoszone wcześniej przez użytkownika).
	back_btn = ScreenHelpers.make_back_button(action_root)
	back_btn.visible = false


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
	if _try_rival_counter_bid():
		return
	_resolve_auction()


## Sama logika "czy ktoś z rywali podbija current_bid" — liczy najlepszą
## ofertę i, jeśli jest wyższa, STOSUJE ją (current_bid/current_leader), ale
## NIE decyduje, co dalej (nowa runda czy rozstrzygnięcie od razu) — to
## zależy od wywołującego: _try_rival_counter_bid (jeszcze jedna runda) albo
## _on_resolve_round_pressed (rezygnacja gracza, rozstrzygnięcie od razu).
func _apply_best_rival_counter_bid() -> bool:
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
	return true


## Wywoływane z losowego, wcześniejszego momentu w trakcie odliczania
## (_process) i z wygaśnięcia czasu (_on_time_expired) — jeśli rywal
## podbija, runda się NIE kończy, tylko zaczyna nową (gracz dostaje kolejne
## 20 sekund na reakcję). Zwraca true, jeśli ktoś podbił.
## Bez komunikatu w status_label o tym, KTO podbił — zgłoszone przez
## użytkownika (zrzut ekranu): ramka oferty (bid_label, _update_labels) już
## pokazuje "(prowadzi: ...)", więc osobny status dublował tę samą
## informację i na ekranie bez ScrollContainera wypychał layout poza dolną
## krawędź ekranu.
func _try_rival_counter_bid() -> bool:
	if not _apply_best_rival_counter_bid():
		return false
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


## Rezygnacja to JEDNORAZOWA, natychmiastowa akcja — zgłoszone przez
## użytkownika: po kliknięciu gracz nie może już podbić, licznik czasu
## przestaje lecieć, a wynik przelicza się OD RAZU do najwyższej oferty
## rywali (jeśli w ogóle ktoś chce przebić) — w przeciwieństwie do
## _try_rival_counter_bid (używanego, gdy czas naturalnie wygaśnie), tu nie
## ma kolejnej rundy z nowym czasem.
func _on_resolve_round_pressed() -> void:
	_apply_best_rival_counter_bid()
	_resolve_auction()


func _resolve_auction() -> void:
	auction_active = false
	## Ukryte (nie tylko disabled) — zastępowane przez back_btn w tym samym
	## miejscu, zamiast zostawiać dwa wyszarzałe, bezużyteczne przyciski na
	## ekranie (zgłoszone przez użytkownika: po zakończeniu aukcji powinien
	## pojawić się tu klawisz powrotu ZAMIAST "Podbij"/"Rezygnuję z aukcji").
	bid_btn.visible = false
	resolve_btn.visible = false
	back_btn.visible = true
	timer_label.text = ""
	## visible = false (nie tylko value = 0) — zgłoszone przez użytkownika:
	## pusty pasek czasu nie powinien już wisieć na ekranie po rozstrzygnięciu.
	timer_bar.visible = false

	## "Kto wygrał" NIE jest już tu powtarzane tekstem — zgłoszone przez
	## użytkownika: ta informacja jest już widoczna w ramce oferty
	## ("Oferta: X M (prowadzi: ...)", patrz _update_labels/bid_label), więc
	## status_label pokazuje TYLKO to, czego w tamtej ramce nie widać: czy to
	## była podróbka, o ile urosła kolekcja, albo że obraz zostaje niesprzedany.
	if current_leader == "player":
		Economy.spend(current_bid)
		if Paintings.is_forgery_by_duplicate(current_number):
			status_label.text = tr("To była FAŁSZYWKA! Pieniądze przepadły, obraz nie trafia do kolekcji.")
		else:
			Paintings.catalogue(current_number)
			status_label.text = tr("Obraz trafia do kolekcji (%d/%d).") % [
				Paintings.owned_count(), Paintings.win_threshold,
			]
	elif current_leader == "":
		status_label.text = tr("Nikt nie licytował — obraz zostaje niesprzedany.")
	else:
		AIPlayers.award_painting(current_leader, current_number, current_bid)
		status_label.text = ""
	_update_labels()

	## Termin kolejnej aukcji NIE jest już dublowany tu drugi raz — zgłoszone
	## przez użytkownika: ta sama informacja już aktualizuje się w
	## schedule_label na samej górze ekranu (patrz linijka niżej).
	Auctions.resolve_and_reschedule()
	schedule_label.text = Auctions.get_schedule_string()

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
