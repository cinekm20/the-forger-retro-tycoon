extends Control
## Placeholder — docelowo siatka pól z bonusem rzeki, wybór uprawy,
## zatrudnianie robotników. Patrz GDD.md pkt. 4.2.

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Plantacje (placeholder)")
	ScreenHelpers.make_label(root, "TODO: siatka pól, bonus rzeki, robotnicy, zbiory")
	ScreenHelpers.make_back_button(root)
