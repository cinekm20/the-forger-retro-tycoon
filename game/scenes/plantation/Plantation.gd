extends Control
## Ekran plantacji — działająca logika (siatka pól, rzeka, uprawa, robotnicy,
## zbiory, wysyłka) na placeholderowym UI z podstawowych kontrolek Godota.
## Grafikę (docs/GRAFIKA_LEONARDO.md §3) podepniemy później bez zmiany logiki.

var selected_city: String = ""
var plantation_index: int = -1

var grid_container: GridContainer
var info_label: Label
var harvest_status_label: Label
var crop_option: OptionButton
var worker_spin: SpinBox


func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Plantacje")
	ScreenHelpers.make_turn_indicator(root)

	## Krótka legenda — bez tego nie było jasne, co robią pola siatki ani
	## przyciski (zgłoszone przez testera: "nie bardzo wiadomo co tam robić").
	ScreenHelpers.make_label(
		root,
		tr("~ rzeka (niedostępna) · + wolne pole (dotknij, by kupić) · ✓ Twoje pole (✓+ = przy rzece, większy plon)\nWybierz uprawę i liczbę robotników, potem \"Zbierz plony\" (raz na jakiś czas) i wyślij do sprzedaży."),
	)

	var city_option := OptionButton.new()
	for city_id in Cities.get_plantation_cities():
		city_option.add_item(Cities.get_city_name(city_id))
		city_option.set_item_metadata(city_option.item_count - 1, city_id)
	city_option.item_selected.connect(_on_city_selected)
	root.add_child(city_option)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)

	grid_container = GridContainer.new()
	grid_container.columns = PlayerPlantations.GRID_SIZE
	root.add_child(grid_container)

	var crop_row := HBoxContainer.new()
	crop_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(crop_row)
	crop_option = OptionButton.new()
	for crop in Crops.CROPS:
		crop_option.add_item(Crops.CROP_NAMES[crop])
	crop_option.item_selected.connect(_on_crop_selected)
	crop_row.add_child(crop_option)

	var worker_row := HBoxContainer.new()
	worker_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(worker_row)
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
	root.add_child(action_row)
	var harvest_btn := Button.new()
	harvest_btn.text = "Zbierz plony"
	harvest_btn.pressed.connect(_on_harvest_pressed)
	action_row.add_child(harvest_btn)
	var sell_btn := Button.new()
	sell_btn.text = "Wyślij i sprzedaj (Nowy Jork)"
	sell_btn.pressed.connect(_on_sell_pressed)
	action_row.add_child(sell_btn)

	harvest_status_label = ScreenHelpers.make_label(root, "")

	ScreenHelpers.make_back_button(root)

	if Cities.get_plantation_cities().size() > 0:
		_on_city_selected(0)


func _on_city_selected(index: int) -> void:
	selected_city = Cities.get_plantation_cities()[index]
	plantation_index = -1
	for i in PlayerPlantations.plantations.size():
		if PlayerPlantations.plantations[i]["city"] == selected_city:
			plantation_index = i
			break
	if plantation_index == -1:
		plantation_index = PlayerPlantations.found_plantation(selected_city)

	## Bez tego pola "Robotnicy"/"Uprawa" zawsze pokazywały wartość domyślną
	## (0 / pierwsza uprawa) przy wejściu na ten ekran, niezależnie od tego,
	## co faktycznie zapisano dla tej plantacji — tester zgłosił, że po
	## powrocie z Hub liczba robotników "znowu wynosi 0", mimo że w danych
	## gry nadal była zapamiętana poprawnie. set_value_no_signal/select() nie
	## wywołują value_changed/item_selected, więc nie nadpisują tego, co
	## właśnie odczytaliśmy.
	var plantation: Dictionary = PlayerPlantations.plantations[plantation_index]
	worker_spin.set_value_no_signal(plantation["workers"])
	var crop_index: int = Crops.CROPS.find(plantation["crop"])
	if crop_index != -1:
		crop_option.select(crop_index)

	harvest_status_label.text = ""
	_rebuild_grid()
	_update_info()


func _rebuild_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	var plantation: Dictionary = PlayerPlantations.plantations[plantation_index]
	for tile_index in plantation["grid"].size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(36, 36)
		if PlayerPlantations.is_river_tile(tile_index):
			btn.text = "~"
			btn.disabled = true
		elif plantation["grid"][tile_index]:
			btn.text = "✓" if not PlayerPlantations.is_adjacent_to_river(tile_index) else "✓+"
			btn.disabled = true
		else:
			btn.text = "+"
			btn.pressed.connect(_on_tile_pressed.bind(tile_index))
		grid_container.add_child(btn)


func _on_tile_pressed(tile_index: int) -> void:
	if PlayerPlantations.buy_tile(plantation_index, tile_index):
		_rebuild_grid()
		_update_info()


func _on_crop_selected(index: int) -> void:
	PlayerPlantations.set_crop(plantation_index, Crops.CROPS[index])
	_update_info()


func _on_workers_changed(value: float) -> void:
	PlayerPlantations.hire_workers(plantation_index, int(value))
	_update_info()


func _on_harvest_pressed() -> void:
	## Widoczna informacja o wyniku — wcześniej przycisk nic nie pokazywał,
	## więc kliknięcie wyglądało, jakby nic się nie działo (zgłoszone przez
	## testera), nawet gdy zbiory faktycznie się liczyły (albo świadomie
	## wynosiły 0, bo od poprzednich zbiorów nie minął jeszcze żaden dzień).
	var amount := PlayerPlantations.harvest(plantation_index)
	if amount > 0:
		harvest_status_label.text = tr("Zebrano: %d jednostek.") % amount
	else:
		harvest_status_label.text = tr("Nic do zebrania — brak uprawy, robotników albo nie minął jeszcze czas od ostatnich zbiorów.")
	_update_info()


func _on_sell_pressed() -> void:
	PlayerPlantations.ship_and_sell(plantation_index, "new_york")
	_update_info()


func _update_info() -> void:
	var plantation: Dictionary = PlayerPlantations.plantations[plantation_index]
	var crop: String = plantation["crop"]
	var crop_name: String = Crops.CROP_NAMES.get(crop, tr("brak")) if crop != "" else tr("brak")
	info_label.text = tr("Gotówka: %.0f M | Pola: %d | Uprawa: %s | Robotnicy: %d | Zboże w magazynie: %d") % [
		Economy.player_money,
		PlayerPlantations.get_owned_tile_count(plantation_index),
		crop_name,
		int(plantation["workers"]),
		plantation["stored_goods"],
	]
