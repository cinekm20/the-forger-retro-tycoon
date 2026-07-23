extends Control
## Ekran plantacji — działająca logika (siatka pól, rzeka, uprawa, robotnicy,
## zbiory, wysyłka) na placeholderowym UI z podstawowych kontrolek Godota.
## Grafikę (docs/GRAFIKA_LEONARDO.md §3) podepniemy później bez zmiany logiki.

const PlantationTileIconScript := preload("res://scripts/ui/PlantationTileIcon.gd")

var plantation_index: int = -1

var grid_container: GridContainer
var legend_label: Label
var info_label: Label
var harvest_status_label: Label
var crop_option: OptionButton
var worker_spin: SpinBox


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/plantation.jpg")
	var root := ScreenHelpers.make_root(self)

	## Siatka (16x16) po LEWEJ, wszystkie guziki/informacje po PRAWEJ, jeden
	## obok drugiego w jednym rzędzie — zamiast wszystkiego w jednej pionowej
	## kolumnie (poprzedni układ), który przy tylu elementach (legenda,
	## wybór miasta, siatka, uprawa, robotnicy, akcje, status) wymagał
	## przewijania, a przewijanie dotykiem na telefonie zawodzi (zgłoszone
	## przez użytkownika). Obie kolumny razem mieszczą się w ramce ekranu
	## bez potrzeby scrolla.
	var main_row := HBoxContainer.new()
	main_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_row.add_theme_constant_override("separation", 24)
	root.add_child(main_row)

	var left_column := VBoxContainer.new()
	left_column.alignment = BoxContainer.ALIGNMENT_CENTER
	main_row.add_child(left_column)

	var right_column := VBoxContainer.new()
	right_column.alignment = BoxContainer.ALIGNMENT_CENTER
	right_column.add_theme_constant_override("separation", 8)
	main_row.add_child(right_column)

	ScreenHelpers.make_title(right_column, "Plantacje")
	ScreenHelpers.make_turn_indicator(right_column)

	## Bez wyboru miasta z listy — zgłoszone przez użytkownika: stojąc na
	## plantacji w jednym mieście nie powinno dać się zdalnie sadzić na
	## plantacji w INNYM mieście. Ekran zawsze zarządza plantacją miasta, w
	## którym gracz aktualnie się znajduje (Hub i tak pokazuje "Plantacje"
	## tylko w miastach typu plantacyjnego, patrz
	## Hub.LOCATION_GATED_DESTINATIONS, więc Travel.current_city zawsze jest
	## poprawnym miastem plantacyjnym, kiedy ten ekran jest w ogóle osiągalny).
	ScreenHelpers.make_label(right_column, Cities.get_city_name(Travel.current_city))

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_label.add_theme_font_size_override("font_size", 19)
	## custom_minimum_size.y: rezerwuje miejsce na zawsze DOKŁADNIE 4 wiersze
	## (patrz _update_info) — bez tego wysokość zależałaby od aktualnej
	## treści i przesuwałaby resztę kolumny przy każdej zmianie (patrz
	## komentarz przy _update_info).
	info_label.custom_minimum_size = Vector2(340, 100)
	right_column.add_child(info_label)

	## Siatka 16x16 (256 pól) w oprawionej ramce, jak w oryginale (zrzut
	## ekranu użytkownika: zielone pole z rzeką w niebieskiej ramce) — widok
	## płaski od góry, NIE izometryczny. Przy tylu polach przyciski 36x36 z
	## poprzedniej, mniejszej siatki (6x6) w ogóle by się nie zmieściły, więc
	## kafelki są teraz małe (22x22 + 2px odstępu = 16*24-2 ≈ 382px szerokości
	## całej siatki) — mieści się w ramce bez potrzeby przewijania.
	var grid_frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.05, 0.15, 0.05, 0.6)
	frame_style.border_color = ScreenHelpers.COLOR_GOLD
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(4)
	frame_style.content_margin_left = 8
	frame_style.content_margin_right = 8
	frame_style.content_margin_top = 8
	frame_style.content_margin_bottom = 8
	grid_frame.add_theme_stylebox_override("panel", frame_style)
	grid_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left_column.add_child(grid_frame)

	grid_container = GridContainer.new()
	grid_container.columns = PlayerPlantations.GRID_SIZE
	grid_container.add_theme_constant_override("h_separation", 2)
	grid_container.add_theme_constant_override("v_separation", 2)
	grid_frame.add_child(grid_container)

	## Legenda: ile pól jest obsianych którą uprawą — zgłoszone przez
	## użytkownika. ZAWSZE dokładnie 4 wiersze (po jednym na każdą z 4 upraw,
	## nawet przy 0 pól), tak samo jak info_label niżej — stała liczba
	## wierszy niezależnie od wartości, żeby nic nie "skakało" przy sadzeniu.
	legend_label = ScreenHelpers.make_label(left_column, "")
	legend_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	legend_label.custom_minimum_size = Vector2(300, 100)

	## Jedna plantacja może jednocześnie uprawiać WSZYSTKIE 4 rodzaje towaru
	## naraz (zgłoszone przez użytkownika) — każde pole ma WŁASNĄ uprawę
	## (patrz PlayerPlantations.plant_tile), więc to nie jest już "uprawa
	## całej plantacji". Ten dropdown wybiera tylko, KTÓRĄ uprawę zasadzić
	## przy najbliższym dotknięciu gołego (kupionego, ale niezasianego) pola.
	var crop_row := HBoxContainer.new()
	crop_row.alignment = BoxContainer.ALIGNMENT_CENTER
	right_column.add_child(crop_row)
	var crop_caption := Label.new()
	crop_caption.text = tr("Sadzić:")
	crop_row.add_child(crop_caption)
	crop_option = OptionButton.new()
	for crop in Crops.CROPS:
		crop_option.add_item(Crops.CROP_NAMES[crop])
	crop_row.add_child(crop_option)

	var worker_row := HBoxContainer.new()
	worker_row.alignment = BoxContainer.ALIGNMENT_CENTER
	right_column.add_child(worker_row)
	var worker_caption := Label.new()
	worker_caption.text = tr("Robotnicy:")
	worker_row.add_child(worker_caption)
	worker_spin = SpinBox.new()
	worker_spin.min_value = 0
	worker_spin.max_value = PlayerPlantations.MAX_WORKERS
	worker_spin.step = 10
	worker_spin.value_changed.connect(_on_workers_changed)
	worker_row.add_child(worker_spin)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	right_column.add_child(action_row)
	var harvest_btn := Button.new()
	harvest_btn.text = "Zbierz plony"
	harvest_btn.pressed.connect(_on_harvest_pressed)
	action_row.add_child(harvest_btn)
	var sell_btn := Button.new()
	sell_btn.text = "Wyślij i sprzedaj (Nowy Jork)"
	sell_btn.pressed.connect(_on_sell_pressed)
	action_row.add_child(sell_btn)

	harvest_status_label = ScreenHelpers.make_label(right_column, "")
	harvest_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	## custom_minimum_size.y: rezerwuje miejsce na 2 wiersze na stałe — bez
	## tego przełączanie między pustym tekstem (przed zbiorami) i najdłuższym
	## komunikatem ("Nic do zebrania — ...", 2 linie) zmieniało wysokość
	## etykiety i przesuwało guziki poniżej (ten sam problem co info_label
	## wyżej — patrz _update_info).
	harvest_status_label.custom_minimum_size = Vector2(340, 50)

	ScreenHelpers.make_button(right_column, "Spichlerz »", func(): SceneRouter.goto_scene(SceneRouter.WAREHOUSE))
	ScreenHelpers.make_back_button(right_column)

	_setup_current_plantation()


func _setup_current_plantation() -> void:
	var current_city := Travel.current_city
	plantation_index = PlayerPlantations.find_plantation_index(current_city)
	if plantation_index == -1:
		plantation_index = PlayerPlantations.found_plantation(current_city)

	## Bez tego pole "Robotnicy" zawsze pokazywało wartość domyślną (0) przy
	## wejściu na ten ekran, niezależnie od tego, co faktycznie zapisano dla
	## tej plantacji — tester zgłosił, że po powrocie z Hub liczba
	## robotników "znowu wynosi 0", mimo że w danych gry nadal była
	## zapamiętana poprawnie. set_value_no_signal nie wywołuje
	## value_changed, więc nie nadpisuje tego, co właśnie odczytaliśmy.
	var plantation: Dictionary = PlayerPlantations.plantations[plantation_index]
	worker_spin.set_value_no_signal(plantation["workers"])

	harvest_status_label.text = ""
	_rebuild_grid()
	_update_info()


## Kafelki rysowane jako ikonki (PlantationTileIcon) zamiast tekstu ~/+/✓/✓+.
## btn.flat = true: zwykłe tło/ramka przycisku wyłączone, widoczna jest tylko
## ikonka wypełniająca cały kafelek. Trzy klikalne stany: "+" (kup pole),
## goła ziemia (kup, ale jeszcze nie zasiane — dotknij, żeby zasadzić
## wybraną w dropdownie uprawę) i rzeka/obsiane pole (nieklikalne). Jedna
## plantacja może mieć różne uprawy na różnych polach naraz (zgłoszone przez
## użytkownika) — kolor/ikonka zależy od uprawy TEGO konkretnego pola.
func _rebuild_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	var plantation: Dictionary = PlayerPlantations.plantations[plantation_index]
	var tile_crops: Array = plantation["tile_crops"]
	for tile_index in plantation["grid"].size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(22, 22)
		btn.flat = true

		var icon: Control = PlantationTileIconScript.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if PlayerPlantations.is_river_tile(plantation_index, tile_index):
			icon.kind = PlantationTileIconScript.Kind.RIVER
			btn.disabled = true
		elif plantation["grid"][tile_index]:
			icon.river_adjacent = PlayerPlantations.is_adjacent_to_river(plantation_index, tile_index)
			var tile_crop: String = tile_crops[tile_index]
			if tile_crop != "":
				icon.kind = PlantationTileIconScript.Kind.CROP
				icon.crop = tile_crop
				btn.disabled = true
			else:
				icon.kind = PlantationTileIconScript.Kind.SOIL
				btn.pressed.connect(_on_plant_tile_pressed.bind(tile_index))
		else:
			icon.kind = PlantationTileIconScript.Kind.VACANT
			btn.pressed.connect(_on_tile_pressed.bind(tile_index))

		btn.add_child(icon)
		grid_container.add_child(btn)


func _on_tile_pressed(tile_index: int) -> void:
	if PlayerPlantations.buy_tile(plantation_index, tile_index):
		_rebuild_grid()
		_update_info()


func _on_plant_tile_pressed(tile_index: int) -> void:
	var crop: String = Crops.CROPS[crop_option.selected]
	if PlayerPlantations.plant_tile(plantation_index, tile_index, crop):
		_rebuild_grid()
		_update_info()


func _on_workers_changed(value: float) -> void:
	PlayerPlantations.hire_workers(plantation_index, int(value))
	_update_info()


func _on_harvest_pressed() -> void:
	## Widoczna informacja o wyniku — wcześniej przycisk nic nie pokazywał,
	## więc kliknięcie wyglądało, jakby nic się nie działo (zgłoszone przez
	## testera), nawet gdy zbiory faktycznie się liczyły (albo świadomie
	## wynosiły 0, bo od poprzednich zbiorów nie minął jeszcze żaden dzień).
	## harvest() zwraca teraz słownik uprawa->ilość (jedna plantacja może
	## zbierać kilka różnych upraw naraz) — status pokazuje sumę, żeby
	## komunikat zostawał zawsze tej samej, krótkiej postaci.
	var amounts := PlayerPlantations.harvest(plantation_index)
	var total := 0
	for amount in amounts.values():
		total += amount
	if total > 0:
		harvest_status_label.text = tr("Zebrano: %d jednostek.") % total
	else:
		harvest_status_label.text = tr("Nic do zebrania — brak uprawy, robotników albo nie minął jeszcze czas od ostatnich zbiorów.")
	_update_info()


func _on_sell_pressed() -> void:
	PlayerPlantations.ship_and_sell(plantation_index, "new_york")
	_update_info()


## CZTERY krótkie, stałe wiersze (każdy z osobna, sam jeden, zawsze mieści
## się w custom_minimum_size.x bez zawijania) zamiast jednego długiego
## zdania z autowrap — długość samej TREŚCI zmieniała liczbę zawiniętych
## linii, więc wysokość etykiety się zmieniała i przesuwała wszystko
## poniżej niej w tej samej kolumnie (zgłoszone przez użytkownika). "Uprawa"
## zniknęła z tej listy (jedna plantacja ma teraz WIELE upraw naraz, patrz
## _update_legend) — zamiast niej "Pola" ma teraz własny, osobny wiersz.
func _update_info() -> void:
	var plantation: Dictionary = PlayerPlantations.plantations[plantation_index]
	var stored: Dictionary = plantation["stored_goods"]
	var total_stored := 0
	for amount in stored.values():
		total_stored += int(amount)
	info_label.text = "%s\n%s\n%s\n%s" % [
		tr("Gotówka: %.0f M") % Economy.player_money,
		tr("Pola: %d") % PlayerPlantations.get_owned_tile_count(plantation_index),
		tr("Robotnicy: %d") % int(plantation["workers"]),
		tr("Zboże w magazynie: %d") % total_stored,
	]
	_update_legend()


## Ile pól jest obsianych którą uprawą — zgłoszone przez użytkownika. ZAWSZE
## dokładnie 4 wiersze (po jednym na każdą z 4 upraw, nawet przy 0 pól),
## tak samo jak info_label wyżej — stała liczba wierszy niezależnie od
## wartości, żeby nic nie "skakało" przy sadzeniu kolejnych pól.
func _update_legend() -> void:
	var lines: Array[String] = []
	for crop in Crops.CROPS:
		lines.append(tr("%s: %d pól") % [Crops.CROP_NAMES[crop], PlayerPlantations.get_planted_tile_count(plantation_index, crop)])
	legend_label.text = "\n".join(lines)
