extends Control
## Spichlerz — zbiorczy widok zebranych plonów ze wszystkich plantacji
## gracza, po jednym "silosie" na uprawę (patrz zrzut ekranu oryginału:
## KAFFEE/TABAK/TEE/KAKAO — poziom wypełnienia silosu + ilość + cena).
## Dostępny tylko w miastach typu "plantation" (patrz Hub.gd), tak jak w
## oryginale (ANKARA DEN ...).

## Czysto wizualna referencja "pełnego silosu" — bez znaczenia
## ekonomicznego, tylko skaluje pasek wypełnienia na ekranie.
const SILO_VISUAL_CAPACITY := 500.0
const SILO_HEIGHT := 120.0
const SILO_WIDTH := 70.0

var fill_rects: Dictionary = {}
var amount_labels: Dictionary = {}
var status_label: Label


func _ready() -> void:
	var corner := ScreenHelpers.make_corner_status_row(self, "", "")
	var location_label: Label = corner["left"]
	var money_label: Label = corner["right"]
	location_label.text = tr("%s\n%s") % [Cities.get_city_name(Travel.current_city), Calendar.get_date_string()]
	money_label.text = tr("%.0f M") % Economy.player_money

	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Spichlerz")
	ScreenHelpers.make_turn_indicator(root)

	var silo_row := HBoxContainer.new()
	silo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	silo_row.add_theme_constant_override("separation", 24)
	root.add_child(silo_row)

	for crop in Crops.CROPS:
		silo_row.add_child(_build_silo(crop))

	status_label = ScreenHelpers.make_label(root, "")

	ScreenHelpers.make_back_button(root)

	_update_info()


func _build_silo(crop: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)

	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.05, 0.05, 0.1, 0.6)
	frame_style.border_color = ScreenHelpers.COLOR_GOLD
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(6)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.custom_minimum_size = Vector2(SILO_WIDTH, SILO_HEIGHT)
	column.add_child(frame)

	## Silos "napełnia się" od dołu: fill_anchor wypełnia całą ramkę
	## (size_flags EXPAND_FILL — wewnątrz Containera anchory na dziecku nic
	## by nie dały, PanelContainer i tak sam ustawia jego prostokąt), a
	## ALIGNMENT_END przykleja właściwy prostokąt wypełnienia do dołu; jego
	## wysokość (custom_minimum_size.y) aktualizuje _update_info() wg
	## poziomu zapasów.
	var fill_anchor := VBoxContainer.new()
	fill_anchor.alignment = BoxContainer.ALIGNMENT_END
	fill_anchor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill_anchor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(fill_anchor)

	var fill := ColorRect.new()
	fill.color = _crop_color(crop)
	fill.custom_minimum_size = Vector2(SILO_WIDTH - 12, 0)
	fill_anchor.add_child(fill)
	fill_rects[crop] = fill

	var name_label := Label.new()
	name_label.text = Crops.CROP_NAMES[crop].to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
	column.add_child(name_label)

	var amount_label := Label.new()
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
	column.add_child(amount_label)
	amount_labels[crop] = amount_label

	var sell_btn := Button.new()
	sell_btn.text = tr("Wyślij i sprzedaj")
	sell_btn.pressed.connect(_on_sell_pressed.bind(crop))
	column.add_child(sell_btn)

	return column


func _crop_color(crop: String) -> Color:
	match crop:
		"coffee":
			return Color(0.45, 0.28, 0.14)
		"tobacco":
			return Color(0.55, 0.4, 0.2)
		"tea":
			return Color(0.3, 0.5, 0.25)
		"cocoa":
			return Color(0.35, 0.2, 0.1)
		_:
			return ScreenHelpers.COLOR_GOLD


func _on_sell_pressed(crop: String) -> void:
	var amount := PlayerPlantations.ship_and_sell_all(crop, "new_york")
	if amount > 0:
		status_label.text = tr("Sprzedano %d jednostek: %s.") % [amount, Crops.CROP_NAMES[crop]]
	else:
		status_label.text = tr("Brak zapasów do sprzedania: %s.") % Crops.CROP_NAMES[crop]
	_update_info()


func _update_info() -> void:
	for crop in Crops.CROPS:
		var stored := PlayerPlantations.get_total_stored(crop)
		var ratio := clampf(stored / SILO_VISUAL_CAPACITY, 0.0, 1.0)
		fill_rects[crop].custom_minimum_size.y = (SILO_HEIGHT - 12) * ratio
		amount_labels[crop].text = tr("%d szt. — %.1f M/szt.") % [stored, Crops.get_price(crop)]
