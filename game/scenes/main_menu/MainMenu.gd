extends Control

var easy_mode_check: CheckBox
var player_count_option: OptionButton
var setup_section: VBoxContainer
var name_section: VBoxContainer
var name_edits: Array[LineEdit] = []
var root: VBoxContainer


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/main_menu_title.jpg")
	root = ScreenHelpers.make_root(self)

	## Logo ma już wpisany napis "VERMEER" w swojej grafice (styl art déco
	## zgodny z resztą gry) — zastępuje zwykły tekstowy tytuł zamiast leżeć
	## obok niego.
	var logo := TextureRect.new()
	logo.texture = load("res://art/backgrounds/logo.jpg")
	logo.custom_minimum_size = Vector2(240, 240)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(logo)

	ScreenHelpers.make_label(root, "Ekonomiczna gra strategiczna — lata 20. XX wieku")

	setup_section = VBoxContainer.new()
	root.add_child(setup_section)

	var player_row := HBoxContainer.new()
	player_row.alignment = BoxContainer.ALIGNMENT_CENTER
	setup_section.add_child(player_row)
	var player_caption := Label.new()
	player_caption.text = "Liczba graczy (hot-seat):"
	player_row.add_child(player_caption)
	player_count_option = OptionButton.new()
	for count in range(1, Players.MAX_PLAYERS + 1):
		player_count_option.add_item(str(count))
	player_row.add_child(player_count_option)

	easy_mode_check = CheckBox.new()
	easy_mode_check.text = tr("Tryb łatwy (%d/%d obrazów do wygranej)") % [Paintings.EASY_WIN_THRESHOLD, Paintings.CATALOG.size()]
	setup_section.add_child(easy_mode_check)

	ScreenHelpers.make_button(setup_section, "Nowa gra", _show_name_entry)

	var continue_btn := ScreenHelpers.make_button(setup_section, "Wczytaj grę", func():
		SaveGame.load_game()
		SceneRouter.goto_hub()
	)
	continue_btn.disabled = not SaveGame.has_save()

	ScreenHelpers.make_button(setup_section, "Ustawienia", func(): SceneRouter.goto_scene(SceneRouter.SETTINGS))
	ScreenHelpers.make_button(setup_section, "Wyjdź z gry", func(): get_tree().quit())

	name_section = VBoxContainer.new()
	name_section.visible = false
	root.add_child(name_section)


## Zamiast od razu startować grę z domyślnymi nazwami "Gracz 1"/"Gracz 2"...,
## po kliknięciu "Nowa gra" pytamy o imiona graczy (tyle pól, ile wybrano w
## "Liczba graczy") — ważne zwłaszcza w hot-seat, żeby każdy wiedział, kiedy
## jest jego tura (patrz Hub.gd _update_status, Gallery.gd lista graczy).
func _show_name_entry() -> void:
	for child in name_section.get_children():
		child.queue_free()
	name_edits.clear()

	ScreenHelpers.make_title(name_section, "Podaj imiona graczy")

	var count := player_count_option.selected + 1
	for i in count:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		name_section.add_child(row)
		var caption := Label.new()
		caption.text = tr("Gracz %d:") % (i + 1)
		row.add_child(caption)
		var edit := LineEdit.new()
		edit.placeholder_text = tr("Gracz %d") % (i + 1)
		edit.custom_minimum_size = Vector2(200, 0)
		row.add_child(edit)
		name_edits.append(edit)

	ScreenHelpers.make_button(name_section, "Rozpocznij grę", _on_start_confirmed)
	ScreenHelpers.make_button(name_section, "Anuluj", func():
		name_section.visible = false
		setup_section.visible = true
	)

	setup_section.visible = false
	name_section.visible = true


func _on_start_confirmed() -> void:
	Calendar.reset_new_game()
	Economy.reset_new_game()
	Crops.reset_new_game()
	Paintings.reset_new_game(easy_mode_check.button_pressed)
	Auctions.reset_new_game()
	ShippingCompanies.reset_new_game()
	ForwardContracts.reset_new_game()
	YearlyReport.reset_new_game()
	AIPlayers.reset_new_game()
	PlayerPlantations.reset_new_game()
	Travel.reset_new_game()
	Security.reset_new_game()
	Players.reset_new_game(player_count_option.selected + 1)
	GameState.reset_new_game()
	for i in name_edits.size():
		Players.set_player_name(i, name_edits[i].text)
	SceneRouter.goto_hub()
