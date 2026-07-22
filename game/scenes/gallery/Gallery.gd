extends Control
## Placeholder — docelowo 8 sekcji stylistycznych, po 5 slotów.
## Patrz GDD.md pkt. 4.7. Ochrona/kradzieże: docs/DODATKOWE_MECHANIKI.md.

var security_label: Label


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/private_gallery.jpg")
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Galeria (placeholder)")
	ScreenHelpers.make_turn_indicator(root)

	ScreenHelpers.make_label(root, tr("Twoja kolekcja: %d/%d (próg zwycięstwa)") % [
		Paintings.owned_count(), Paintings.win_threshold,
	])

	for category_id in Paintings.CATEGORIES:
		var category_name: String = Paintings.CATEGORY_NAMES[category_id]
		var owned_in_category := 0
		for number in Paintings.catalogued_numbers:
			if Paintings.get_category(number) == category_id:
				owned_in_category += 1
		ScreenHelpers.make_label(root, tr("%s: %d/5") % [category_name, owned_in_category])

	if Players.is_multiplayer():
		ScreenHelpers.make_title(root, "Gracze")
		for i in Players.player_count:
			var marker := tr(" (Ty)") if i == Players.active_index else ""
			ScreenHelpers.make_label(root, tr("%s%s: %d obrazów") % [
				Players.player_names[i], marker, Players.get_painting_count(i),
			])

	ScreenHelpers.make_title(root, "Ochrona")
	security_label = ScreenHelpers.make_label(root, "")
	var bodyguard_btn := ScreenHelpers.make_button(
		root,
		tr("Zatrudnij ochroniarza (%.0f M)") % Security.BODYGUARD_COST,
		_on_hire_bodyguard_pressed,
	)
	bodyguard_btn.disabled = Security.has_bodyguard
	_update_security_label()

	ScreenHelpers.make_title(root, "Rywale")
	for rival in AIPlayers.rivals:
		var rival_row := HBoxContainer.new()
		rival_row.alignment = BoxContainer.ALIGNMENT_CENTER
		root.add_child(rival_row)
		var rival_label := Label.new()
		rival_label.text = tr("%s: %d obrazów") % [rival["name"], AIPlayers.get_rival_painting_count(rival["id"])]
		rival_row.add_child(rival_label)
		var gangster_btn := Button.new()
		gangster_btn.text = tr("Wyślij gangstera (%.0f M)") % Security.GANGSTER_COST
		gangster_btn.pressed.connect(_on_send_gangster_pressed.bind(rival["id"]))
		rival_row.add_child(gangster_btn)

	ScreenHelpers.make_back_button(root)


func _on_hire_bodyguard_pressed() -> void:
	if Security.hire_bodyguard():
		_update_security_label()
		SceneRouter.goto_scene(SceneRouter.GALLERY)  # przeładuj, żeby odświeżyć stan przycisku


func _on_send_gangster_pressed(rival_id: String) -> void:
	var success := Security.send_gangster(rival_id)
	security_label.text = (
		tr("Gangster wraca z obrazem!") if success else tr("Gangster wraca z pustymi rękami — pieniądze przepadły.")
	)


func _update_security_label() -> void:
	security_label.text = (
		tr("Masz ochroniarza — obrazy chronione przed kradzieżą.")
		if Security.has_bodyguard
		else tr("Bez ochrony — Twoja kolekcja jest narażona na kradzież (~%.0f%% szans/tydzień).") % [
			Security.WEEKLY_THEFT_CHANCE_UNPROTECTED * 100.0,
		]
	)
