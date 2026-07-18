extends Control

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "VERMEER")
	ScreenHelpers.make_label(root, "Ekonomiczna gra strategiczna — lata 20. XX wieku")

	ScreenHelpers.make_button(root, "Nowa gra", func():
		Calendar.reset_new_game()
		Economy.reset_new_game()
		Crops.reset_new_game()
		Paintings.reset_new_game()
		ShippingCompanies.reset_new_game()
		ForwardContracts.reset_new_game()
		AIPlayers.reset_new_game()
		PlayerPlantations.reset_new_game()
		Travel.reset_new_game()
		SceneRouter.goto_hub()
	)

	var continue_btn := ScreenHelpers.make_button(root, "Wczytaj grę", func():
		SaveGame.load_game()
		SceneRouter.goto_hub()
	)
	continue_btn.disabled = not SaveGame.has_save()
