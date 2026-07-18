extends Control
## Placeholder — docelowo licytacja w czasie rzeczywistym, portrety rywali
## (w tym Vico), system autentykacji wg numeru katalogowego.
## Patrz GDD.md pkt. 4.5, docs/MECHANIKI_EKONOMICZNE.md pkt. 9.

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Dom aukcyjny (placeholder)")
	ScreenHelpers.make_label(root, "TODO: licytacja, portrety rywali, autentykacja wg numeru")
	ScreenHelpers.make_back_button(root)
