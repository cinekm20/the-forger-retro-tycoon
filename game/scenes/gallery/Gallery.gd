extends Control
## Placeholder — docelowo 8 sekcji stylistycznych, po 5 slotów.
## Patrz GDD.md pkt. 4.7.

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Galeria (placeholder)")

	ScreenHelpers.make_label(root, "Twoja kolekcja: %d/%d (próg zwycięstwa)" % [
		Paintings.owned_count(), Paintings.win_threshold,
	])

	for category_id in Paintings.CATEGORIES:
		var category_name: String = Paintings.CATEGORY_NAMES[category_id]
		var owned_in_category := 0
		for number in Paintings.catalogued_numbers:
			if Paintings.get_category(number) == category_id:
				owned_in_category += 1
		ScreenHelpers.make_label(root, "%s: %d/5" % [category_name, owned_in_category])

	if Players.is_multiplayer():
		ScreenHelpers.make_title(root, "Gracze")
		for i in Players.player_count:
			var marker := " (Ty)" if i == Players.active_index else ""
			ScreenHelpers.make_label(root, "%s%s: %d obrazów" % [
				Players.player_names[i], marker, Players.get_painting_count(i),
			])

	ScreenHelpers.make_title(root, "Rywale")
	for rival in AIPlayers.rivals:
		ScreenHelpers.make_label(root, "%s: %d obrazów" % [
			rival["name"], AIPlayers.get_rival_painting_count(rival["id"]),
		])

	ScreenHelpers.make_back_button(root)
