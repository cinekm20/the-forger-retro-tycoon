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

var schedule_label: Label
var painting_label: Label
var bid_label: Label
var money_label: Label
var warning_label: Label
var status_label: Label
var timer_label: Label
var painting_texture_rect: TextureRect
var bid_btn: Button
var resolve_btn: Button

## Większy niż poprzednio (220) — użytkownik zgłosił, że obraz musi być
## "super widoczny", nie tylko odznaczony małą ramką wśród opisów.
const PAINTING_DISPLAY_SIZE := Vector2(320, 320)


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/auction_house.jpg")

	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Dom aukcyjny")
	ScreenHelpers.make_turn_indicator(root)

	schedule_label = ScreenHelpers.make_info_box(root, "")

	if not Auctions.is_open(Travel.current_city):
		ScreenHelpers.make_label(root, "W tym mieście nie odbywa się teraz żadna aukcja.\nWróć w podanym terminie.")
		schedule_label.text = Auctions.get_schedule_string()
		ScreenHelpers.make_back_button(root)
		return

	_build_active_auction_ui(root)
	_start_new_auction()


## Buduje UI aktywnej licytacji: duży obraz w oprawionej ramce w głównej
## karcie, a przyciski podbijania + malejący licznik czasu w OSOBNYM pasku
## przyklejonym do prawego dolnego rogu ekranu (make_root_bottom) — zgodnie
## z prośbą użytkownika, żeby akcje licytacji nie leżały wymieszane w
## pionowej liście opisów, tylko osobno "na dole albo z boku".
func _build_active_auction_ui(root: VBoxContainer) -> void:
	var painting_box := StyleBoxFlat.new()
	painting_box.bg_color = Color(ScreenHelpers.COLOR_BURGUNDY_DARK.r, ScreenHelpers.COLOR_BURGUNDY_DARK.g, ScreenHelpers.COLOR_BURGUNDY_DARK.b, 0.85)
	painting_box.border_color = ScreenHelpers.COLOR_GOLD
	painting_box.set_border_width_all(4)
	painting_box.set_corner_radius_all(4)
	painting_box.content_margin_left = 10
	painting_box.content_margin_right = 10
	painting_box.content_margin_top = 10
	painting_box.content_margin_bottom = 10
	var painting_panel := PanelContainer.new()
	painting_panel.add_theme_stylebox_override("panel", painting_box)
	painting_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(painting_panel)

	painting_texture_rect = TextureRect.new()
	painting_texture_rect.custom_minimum_size = PAINTING_DISPLAY_SIZE
	painting_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painting_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	painting_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painting_panel.add_child(painting_texture_rect)

	painting_label = ScreenHelpers.make_label(root, "")
	warning_label = ScreenHelpers.make_label(root, "")

	var bid_row := HBoxContainer.new()
	bid_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bid_row.add_theme_constant_override("separation", 14)
	root.add_child(bid_row)
	bid_label = ScreenHelpers.make_info_box(bid_row, "")
	money_label = ScreenHelpers.make_info_box(bid_row, "")

	status_label = ScreenHelpers.make_label(root, "")
	ScreenHelpers.make_back_button(root)

	var action_root := ScreenHelpers.make_root_bottom(self, true, 340.0, true)
	timer_label = ScreenHelpers.make_label(action_root, "")
	timer_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
	bid_btn = ScreenHelpers.make_button(action_root, "Podbij (+10%)", _on_bid_pressed)
	resolve_btn = ScreenHelpers.make_button(action_root, "Zakończ rundę", _on_resolve_round_pressed)


func _process(delta: float) -> void:
	if not auction_active:
		return
	bid_time_remaining -= delta
	if bid_time_remaining <= 0.0:
		bid_time_remaining = 0.0
		auction_active = false
		timer_label.text = "Czas minął!"
		_on_time_expired()
	else:
		timer_label.text = "Czas na podbicie: %d s" % int(ceil(bid_time_remaining))


func _start_bid_timer() -> void:
	bid_time_remaining = BID_TIME_LIMIT
	auction_active = true


func _on_time_expired() -> void:
	status_label.text = "Zabrakło czasu na podbicie — rywale odpowiadają."
	_on_resolve_round_pressed()


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
		status_label.text = "Za mało gotówki na taką ofertę."
		return
	current_bid = next_bid
	current_leader = "player"
	_update_labels()
	_start_bid_timer()


func _on_resolve_round_pressed() -> void:
	var estimated_value := Paintings.get_estimated_value(current_number)
	var best_rival_id := ""
	var best_rival_bid := current_bid
	for rival in AIPlayers.rivals:
		var rival_bid: float = AIPlayers.decide_bid(rival["id"], current_bid, estimated_value)
		if rival_bid > best_rival_bid:
			best_rival_bid = rival_bid
			best_rival_id = rival["id"]

	if best_rival_id != "":
		current_bid = best_rival_bid
		current_leader = best_rival_id
		status_label.text = "%s podbija ofertę." % AIPlayers.get_rival(best_rival_id)["name"]
		_update_labels()
		_start_bid_timer()
		return

	_resolve_auction()


func _resolve_auction() -> void:
	auction_active = false
	bid_btn.disabled = true
	resolve_btn.disabled = true
	timer_label.text = ""

	if current_leader == "player":
		Economy.spend(current_bid)
		if Paintings.is_forgery_by_duplicate(current_number):
			status_label.text = "To była FAŁSZYWKA! Pieniądze przepadły, obraz nie trafia do kolekcji."
		else:
			Paintings.catalogue(current_number)
			status_label.text = "Wygrywasz aukcję! Obraz trafia do kolekcji (%d/%d)." % [
				Paintings.owned_count(), Paintings.win_threshold,
			]
	elif current_leader == "":
		status_label.text = "Nikt nie licytował — obraz zostaje niesprzedany."
	else:
		AIPlayers.award_painting(current_leader, current_number, current_bid)
		status_label.text = "%s wygrywa aukcję." % AIPlayers.get_rival(current_leader)["name"]
	_update_labels()

	Auctions.resolve_and_reschedule()
	schedule_label.text = Auctions.get_schedule_string()
	status_label.text += "\n" + Auctions.get_schedule_string()

	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)


func _update_labels() -> void:
	schedule_label.text = "Aukcja w toku: %s — %s" % [Cities.get_city_name(Travel.current_city), Calendar.get_date_string()]

	var category: String = Paintings.get_category(current_number)
	var category_name: String = Paintings.CATEGORY_NAMES.get(category, category)
	var info := Paintings.get_painting_info(current_number)
	if not info.is_empty():
		painting_label.text = "Na sprzedaż: „%s” — %s, %s (%s) — szac. wartość %.0f M" % [
			info["title"], info["artist"], info["year"], category_name, Paintings.get_estimated_value(current_number),
		]
	else:
		painting_label.text = "Na sprzedaż: obraz nr %d (%s) — szac. wartość %.0f M" % [
			current_number, category_name, Paintings.get_estimated_value(current_number),
		]

	## Grafika obrazu opcjonalna — jeśli plik danego numeru jeszcze nie
	## istnieje (docs/GRAFIKA_LEONARDO.md §7), ramka zostaje pusta zamiast
	## crashować na load() brakującego pliku.
	var texture_path := Paintings.get_texture_path(current_number)
	painting_texture_rect.texture = load(texture_path) if ResourceLoader.exists(texture_path) else null

	if current_forgery_warning:
		warning_label.text = "⚠ Szkoła Sztuki ostrzega: ten numer już masz w kolekcji — to może być podróbka!"
	else:
		warning_label.text = ""

	var leader_text := "nikt"
	if current_leader == "player":
		leader_text = "Ty"
	elif current_leader != "":
		leader_text = AIPlayers.get_rival(current_leader)["name"]
	bid_label.text = "Oferta: %.0f M\n(prowadzi: %s)" % [current_bid, leader_text]
	money_label.text = "Gotówka: %.0f M" % Economy.player_money
