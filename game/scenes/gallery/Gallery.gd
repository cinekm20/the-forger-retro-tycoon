extends Control
## Placeholder — docelowo 8 sekcji stylistycznych, po 5 slotów.
## Patrz GDD.md pkt. 4.7.

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Galeria (placeholder)")

	for category_id in Paintings.CATEGORIES:
		var category_name: String = Paintings.CATEGORY_NAMES[category_id]
		var owned_in_category := 0
		for number in Paintings.catalogued_numbers:
			if Paintings.get_category(number) == category_id:
				owned_in_category += 1
		ScreenHelpers.make_label(root, "%s: %d/5" % [category_name, owned_in_category])

	ScreenHelpers.make_back_button(root)
