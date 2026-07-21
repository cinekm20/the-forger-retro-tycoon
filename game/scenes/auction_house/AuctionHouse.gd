extends Control
## Dom aukcyjny — działająca licytacja przeciw AI (w tym Vico).
## Patrz GDD.md pkt. 4.5, docs/MECHANIKI_EKONOMICZNE.md pkt. 9.

const BID_INCREMENT_RATIO := 0.1  ## gracz podbija o 10% szacunkowej wartości

var current_number: int = -1
var current_bid: float = 0.0
var current_leader: String = ""  ## "" = nikt, "player", albo id rywala
var current_forgery_warning: bool = false  ## losowane raz na aukcję w _start_new_auction

var auction_number_label: Label
var painting_label: Label
var bid_label: Label
var money_label: Label
var warning_label: Label
var status_label: Label


## Układ pudełek nawiązuje do oryginału (patrz screeny użytkownika):
## "AUCTION NUMBER: X" jako osobna skrzynka u góry, "UP FOR AUCTION IS: ..."
## jako zwykła linia, a oferta + gotówka gracza jako dwie skrzynki obok
## siebie (tam odpowiednik to "BID BY VICO 75000 M" + nazwisko gracza).
func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Dom aukcyjny")
	ScreenHelpers.make_turn_indicator(root)

	auction_number_label = ScreenHelpers.make_info_box(root, "")
	painting_label = ScreenHelpers.make_label(root, "")
	warning_label = ScreenHelpers.make_label(root, "")

	var bid_row := HBoxContainer.new()
	bid_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bid_row.add_theme_constant_override("separation", 14)
	root.add_child(bid_row)
	bid_label = ScreenHelpers.make_info_box(bid_row, "")
	money_label = ScreenHelpers.make_info_box(bid_row, "")

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(action_row)

	var bid_btn := Button.new()
	bid_btn.text = "Podbij"
	bid_btn.pressed.connect(_on_bid_pressed)
	action_row.add_child(bid_btn)

	var resolve_btn := Button.new()
	resolve_btn.text = "Zakończ rundę (odpowiedź rywali)"
	resolve_btn.pressed.connect(_on_resolve_round_pressed)
	action_row.add_child(resolve_btn)

	var next_btn := Button.new()
	next_btn.text = "Nowa aukcja"
	next_btn.pressed.connect(_start_new_auction)
	action_row.add_child(next_btn)

	status_label = ScreenHelpers.make_label(root, "")
	ScreenHelpers.make_back_button(root)

	_start_new_auction()


func _start_new_auction() -> void:
	current_number = 1 + randi() % Paintings.CATALOG.size()
	var estimated_value := Paintings.get_estimated_value(current_number)
	current_bid = estimated_value * 0.2
	current_leader = ""
	current_forgery_warning = Paintings.warns_about_forgery(current_number)
	_update_labels()


func _on_bid_pressed() -> void:
	var estimated_value := Paintings.get_estimated_value(current_number)
	var next_bid := current_bid + estimated_value * BID_INCREMENT_RATIO
	if not Economy.can_afford(next_bid):
		status_label.text = "Za mało gotówki na taką ofertę."
		return
	current_bid = next_bid
	current_leader = "player"
	_update_labels()


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
		return

	_resolve_auction()


func _resolve_auction() -> void:
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

	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)


func _update_labels() -> void:
	auction_number_label.text = "Aukcja nr %d" % current_number

	var category: String = Paintings.get_category(current_number)
	var category_name: String = Paintings.CATEGORY_NAMES.get(category, category)
	painting_label.text = "Na sprzedaż: obraz nr %d (%s) — szac. wartość %.0f M" % [
		current_number, category_name, Paintings.get_estimated_value(current_number),
	]

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
