class_name ScreenHelpers
## Wspólne, minimalne budowniczowie UI dla placeholderowych ekranów.
## Docelowo zastąpione właściwymi scenami z grafiką (docs/GRAFIKA_LEONARDO.md).


static func make_root(parent: Control) -> VBoxContainer:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	parent.add_child(root)
	return root


static func make_title(root: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	root.add_child(label)
	return label


static func make_label(root: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label)
	return label


static func make_button(root: VBoxContainer, text: String, on_pressed: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 44)
	btn.pressed.connect(on_pressed)
	root.add_child(btn)
	return btn


static func make_back_button(root: VBoxContainer) -> Button:
	return make_button(root, "« Powrót do mapy", func(): SceneRouter.goto_hub())


## W hot-seat multiplayer pokazuje, czyja jest tura — ważne, żeby osoba
## trzymająca telefon wiedziała, w czyim imieniu działa. W solo nic nie
## dodaje (zwraca null).
static func make_turn_indicator(root: VBoxContainer) -> Label:
	if not Players.is_multiplayer():
		return null
	return make_label(root, "Tura: %s" % Players.active_name())
