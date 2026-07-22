extends Control

var easy_mode_check: CheckBox
var player_count_option: OptionButton


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/main_menu_title.jpg")
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "VERMEER")
	ScreenHelpers.make_label(root, "Ekonomiczna gra strategiczna — lata 20. XX wieku")

	var player_row := HBoxContainer.new()
	player_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(player_row)
	var player_caption := Label.new()
	player_caption.text = "Liczba graczy (hot-seat):"
	player_row.add_child(player_caption)
	player_count_option = OptionButton.new()
	for count in range(1, Players.MAX_PLAYERS + 1):
		player_count_option.add_item(str(count))
	player_row.add_child(player_count_option)

	easy_mode_check = CheckBox.new()
	easy_mode_check.text = "Tryb łatwy (%d/%d obrazów do wygranej)" % [Paintings.EASY_WIN_THRESHOLD, Paintings.CATALOG.size()]
	root.add_child(easy_mode_check)

	ScreenHelpers.make_button(root, "Nowa gra", func():
		Calendar.reset_new_game()
		Economy.reset_new_game()
		Crops.reset_new_game()
		Paintings.reset_new_game(easy_mode_check.button_pressed)
		Auctions.reset_new_game()
		ShippingCompanies.reset_new_game()
		ForwardContracts.reset_new_game()
		AIPlayers.reset_new_game()
		PlayerPlantations.reset_new_game()
		Travel.reset_new_game()
		Security.reset_new_game()
		Players.reset_new_game(player_count_option.selected + 1)
		GameState.reset_new_game()
		SceneRouter.goto_hub()
	)

	var continue_btn := ScreenHelpers.make_button(root, "Wczytaj grę", func():
		SaveGame.load_game()
		SceneRouter.goto_hub()
	)
	continue_btn.disabled = not SaveGame.has_save()
