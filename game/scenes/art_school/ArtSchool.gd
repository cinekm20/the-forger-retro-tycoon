extends Control
## Placeholder — docelowo mini-gra porównawcza obrazów, podnosząca szansę
## na wczesne ostrzeżenie o duplikacie numeru katalogowego. Patrz GDD.md
## pkt. 4.6.

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Szkoła sztuki (placeholder)")
	ScreenHelpers.make_label(root, "TODO: mini-gra autentykacji, statystyka eksperckości")
	ScreenHelpers.make_back_button(root)
