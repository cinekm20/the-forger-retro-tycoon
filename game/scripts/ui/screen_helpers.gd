class_name ScreenHelpers
## Wspólne, minimalne budowniczowie UI dla placeholderowych ekranów.
## Docelowo zastąpione właściwymi scenami z grafiką (docs/GRAFIKA_LEONARDO.md).


## Pełnoekranowe tło + półprzezroczysta nakładka (dla czytelności tekstu na
## bogatej w szczegóły grafice). Wywoływać PRZED make_root, żeby tło zostało
## dodane jako pierwsze dziecko (czyli renderuje się pod resztą UI).
static func make_background(parent: Control, texture_path: String) -> TextureRect:
	var bg := TextureRect.new()
	bg.texture = load(texture_path)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(bg)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	return bg


## mouse_filter = IGNORE na kontenerze jest ważne: bez tego niewidzialne tło
## pełnoekranowego VBoxContainer przechwytuje kliknięcia na CAŁYM ekranie
## (nawet w miejscach bez żadnego widocznego elementu UI), blokując np.
## pinezki mapy leżące pod spodem. Same przyciski/etykiety w środku mają
## własny filtr i nadal reagują na dotyk normalnie.
static func make_root(parent: Control) -> VBoxContainer:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)
	return root


## Wariant zakotwiczony na dole ekranu zamiast wyśrodkowany na całej
## wysokości — dla ekranów, gdzie góra/środek musi zostać odsłonięty
## (np. mapa z klikalnymi pinezkami pod spodem). CELOWO pełnoekranowy
## (PRESET_FULL_RECT), tak jak make_root(), tylko z inną osią wyrównania —
## PRESET_BOTTOM_WIDE tu NIE działa: set_anchors_preset() liczy offsety na
## podstawie rozmiaru kontenera W MOMENCIE WYWOŁANIA, czyli zanim dojdą
## jakiekolwiek dzieci (rozmiar 0×0) — kontener zostaje trwale spłaszczony
## do zerowej wysokości, więc cała jego zawartość renderuje się poza
## ekranem. ALIGNMENT_END na pełnoekranowym kontenerze daje ten sam efekt
## wizualny (treść przy dolnej krawędzi) bez tej pułapki.
static func make_root_bottom(parent: Control) -> VBoxContainer:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_END
	root.add_theme_constant_override("separation", 10)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)
	return root


## Paleta art déco (docs/GRAFIKA_LEONARDO.md — złoto/burgund/sepia).
const COLOR_GOLD := Color(0.85, 0.65, 0.2)
const COLOR_GOLD_BRIGHT := Color(1.0, 0.83, 0.4)
const COLOR_CREAM := Color(0.95, 0.88, 0.72)
const COLOR_BURGUNDY_DARK := Color(0.13, 0.04, 0.06)


static func make_title(root: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(label)
	return label


static func make_label(root: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_CREAM)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(label)
	return label


## Przyciski w stylu art déco (ciemny burgund + złota ramka) zamiast
## domyślnego szarego wyglądu Godota — jeden wspólny styl dla całej gry.
static func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(COLOR_BURGUNDY_DARK.r, COLOR_BURGUNDY_DARK.g, COLOR_BURGUNDY_DARK.b, 0.88)
	normal.border_color = COLOR_GOLD
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10

	var hover := normal.duplicate()
	hover.bg_color = Color(0.28, 0.09, 0.13, 0.92)
	hover.border_color = COLOR_GOLD_BRIGHT

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.06, 0.02, 0.03, 0.95)
	pressed.border_color = COLOR_GOLD_BRIGHT

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.2, 0.2, 0.2, 0.55)
	disabled.border_color = Color(0.45, 0.45, 0.45)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", COLOR_CREAM)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
	btn.add_theme_color_override("font_pressed_color", COLOR_GOLD_BRIGHT)
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
	btn.add_theme_font_size_override("font_size", 18)


static func make_button(root: VBoxContainer, text: String, on_pressed: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 46)
	btn.pressed.connect(on_pressed)
	_style_button(btn)
	root.add_child(btn)
	return btn


static func make_back_button(root: VBoxContainer) -> Button:
	return make_button(root, "« Powrót", func(): SceneRouter.goto_hub())


## W hot-seat multiplayer pokazuje, czyja jest tura — ważne, żeby osoba
## trzymająca telefon wiedziała, w czyim imieniu działa. W solo nic nie
## dodaje (zwraca null).
static func make_turn_indicator(root: VBoxContainer) -> Label:
	if not Players.is_multiplayer():
		return null
	return make_label(root, "Tura: %s" % Players.active_name())
