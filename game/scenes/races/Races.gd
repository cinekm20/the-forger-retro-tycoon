extends Control
## Placeholder — docelowo lista koni z kursami, animowany wyścig, zakłady.
## Patrz GDD.md pkt. 4.4.

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Wyścigi konne (placeholder)")
	ScreenHelpers.make_label(root, "TODO: lista koni, kursy, animacja wyścigu, zakłady")
	ScreenHelpers.make_back_button(root)
