extends Node
## Globalny przycisk "Ustawienia" w rogu ekranu, widoczny na każdym ekranie
## poza menu głównym (gdzie nie ma jeszcze co zapisywać) — pozwala zapisać
## grę albo CAŁKOWICIE zamknąć aplikację. "Zapisz i wyjdź do menu" w Hub.gd
## tylko wraca do MainMenu.tscn (proces gry dalej działa w tle) — tu chodzi
## o get_tree().quit(), czyli faktyczne zakończenie procesu i zwolnienie
## pamięci, czego Hub.gd nie robi.

var layer: CanvasLayer
var settings_button: Button
var overlay: Control
var status_label: Label

## Rozmiar/margines w rogu ekranu — na anchorach (anchor_left=anchor_right=1,
## anchor_top=anchor_bottom=0 + stałe pikselowe offsety), tak samo jak
## naprawione pinezki na mapie (TravelMap.gd) — zostaje w tym samym miejscu
## niezależnie od rozdzielczości, zamiast liczyć position raz przy starcie.
## Skrzynki w prawym górnym rogu (Hub.gd _build_top_row,
## ScreenHelpers.make_corner_status_row) mają dodatkowy odstęp od góry
## (offset_top=90 zamiast 12), żeby zrobić miejsce na ten przycisk.
const BUTTON_SIZE := Vector2(56, 56)
const BUTTON_MARGIN := 16.0


func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 90  # pod SceneRouter._snapshot_layer (100), nad resztą UI
	add_child(layer)

	settings_button = Button.new()
	settings_button.text = "☰"
	settings_button.add_theme_font_size_override("font_size", 28)
	ScreenHelpers._style_button(settings_button)
	settings_button.anchor_left = 1.0
	settings_button.anchor_right = 1.0
	settings_button.anchor_top = 0.0
	settings_button.anchor_bottom = 0.0
	settings_button.offset_left = -BUTTON_SIZE.x - BUTTON_MARGIN
	settings_button.offset_right = -BUTTON_MARGIN
	settings_button.offset_top = BUTTON_MARGIN
	settings_button.offset_bottom = BUTTON_MARGIN + BUTTON_SIZE.y
	settings_button.pressed.connect(_toggle_overlay)
	layer.add_child(settings_button)

	_build_overlay()

	get_tree().tree_changed.connect(_update_button_visibility)
	_update_button_visibility()


## Ukryty na ekranie startowym (MainMenu) — nie ma tam jeszcze żadnej gry do
## zapisania, a "Wyjdź z gry" jest tam zbędne (użytkownik i tak nic nie
## rozpoczął). tree_changed leci bardzo często (dowolna zmiana w drzewie
## sceny), ale sam test poniżej jest tani, więc to nieistotne obciążenie.
func _update_button_visibility() -> void:
	var scene := get_tree().current_scene
	var visible_now: bool = scene != null and scene.scene_file_path != SceneRouter.MAIN_MENU
	settings_button.visible = visible_now
	if not visible_now:
		overlay.visible = false


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var box := StyleBoxFlat.new()
	box.bg_color = Color(ScreenHelpers.COLOR_BURGUNDY_DARK.r, ScreenHelpers.COLOR_BURGUNDY_DARK.g, ScreenHelpers.COLOR_BURGUNDY_DARK.b, 0.96)
	box.border_color = ScreenHelpers.COLOR_GOLD
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	box.content_margin_left = 32
	box.content_margin_right = 32
	box.content_margin_top = 24
	box.content_margin_bottom = 24
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	ScreenHelpers.make_title(vbox, "Ustawienia")

	status_label = ScreenHelpers.make_label(vbox, "")

	var save_btn := ScreenHelpers.make_button(vbox, "Zapisz grę", _on_save_pressed)
	save_btn.custom_minimum_size.x = 360

	var quit_btn := ScreenHelpers.make_button(vbox, "Wyjdź z gry (zamknij aplikację)", _on_quit_pressed)
	quit_btn.custom_minimum_size.x = 360

	var close_btn := ScreenHelpers.make_button(vbox, "Zamknij", _on_close_pressed)
	close_btn.custom_minimum_size.x = 360


func _toggle_overlay() -> void:
	overlay.visible = not overlay.visible
	if overlay.visible:
		status_label.text = ""


func _on_save_pressed() -> void:
	SaveGame.save_game()
	status_label.text = "Zapisano grę."


## get_tree().quit() kończy proces aplikacji — to jedyny sposób, żeby na
## Androidzie gra faktycznie się zamknęła i zwolniła pamięć, w
## przeciwieństwie do samego powrotu do MainMenu.tscn (proces zostaje
## uruchomiony, tylko przełącza scenę).
func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_close_pressed() -> void:
	overlay.visible = false
