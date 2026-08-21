extends Control
## Ekran plantacji — działająca logika (siatka pól, rzeka, uprawa, robotnicy,
## zbiory, wysyłka) na placeholderowym UI z podstawowych kontrolek Godota.
## Grafikę (docs/GRAFIKA_LEONARDO.md §3) podepniemy później bez zmiany logiki.

const PlantationTileIconScript := preload("res://scripts/ui/PlantationTileIcon.gd")
const StatIconScript := preload("res://scripts/ui/StatIcon.gd")

## Muszą się zgadzać z faktycznym stylem grid_frame/grid_container niżej —
## używane do przeliczenia rozmiaru POJEDYNCZEGO pola z docelowego rozmiaru
## CAŁEJ (kwadratowej) siatki, patrz _ready().
const GRID_CONTENT_MARGIN := 8.0
const GRID_CELL_SEPARATION := 2.0
const LEGEND_ICON_SIZE := 28.0
## Odstęp między siatką a prawą połową, i między dwiema kolumnami w tej
## połowie — ta sama wartość w obu miejscach, więc liczenie column_width w
## _ready() (ile miejsca ZOSTAJE na kolumnę po odjęciu siatki i separatorów)
## faktycznie odpowiada temu, co Container narysuje.
const COLUMN_SEPARATION := 24.0
## Zgłoszone przez użytkownika: litery mają być większe (domyślne z
## ScreenHelpers.make_label to 19).
const BODY_FONT_SIZE := 22

var plantation_index: int = -1

var grid_container: GridContainer
var legend_crop_rows: VBoxContainer
var location_label: Label
var money_label: Label
var info_label: Label
var harvest_status_label: Label
var crop_option: OptionButton
var worker_spin: SpinBox
var pump_button: Button
## Podzbiór Crops.CROPS dostępny W TYM mieście (patrz Crops.is_crop_available)
## — np. "Przemycana uprawa" tylko w Ankarze/Gwatemali. Trzymany osobno, bo
## crop_option.selected to indeks w TEJ przefiltrowanej liście, nie w pełnym
## Crops.CROPS.
var available_crops: Array[String] = []
var cell_size: float = 22.0
var column_width: float = 260.0
var legend_text_width: float = 200.0


func _ready() -> void:
	Music.play_track(Music.PLANTATION_TRACK)
	ScreenHelpers.make_background(self, "res://art/backgrounds/plantation.jpg")
	## use_menu_frame=false: zgłoszone przez użytkownika — ozdobna ramka na
	## cały ekran ma zniknąć na wszystkich ekranach (ten sam fix co wcześniej
	## w AuctionHouse.gd/Gallery.gd). "Plantacje" u góry info_column i
	## "Powrót" u dołu legend_column (patrz niżej) już PRZED tą zmianą
	## realizowały dokładnie ten wzorzec przypięcia do krawędzi, więc tu nie
	## trzeba nic dodatkowo spinać na poziomie root — tylko poprawić liczenie
	## rozmiaru siatki, bo zakładało DOKŁADNIE geometrię usuniętej ramki.
	var root := ScreenHelpers.make_root(self, false)

	var main_row := HBoxContainer.new()
	main_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_row.add_theme_constant_override("separation", int(COLUMN_SEPARATION))
	root.add_child(main_row)

	## Siatka ma wypełniać CAŁĄ wysokość ekranu, a szerokość dostosowuje się
	## tak, żeby siatka zostawała KWADRATEM (16×16 pól) — zgłoszone przez
	## użytkownika. Liczone z get_viewport_rect() (nie ze stałej liczby
	## pikseli w kodzie), tak jak inne miejsca w grze zależne od
	## rozdzielczości (patrz TravelMap.gd/_build_pins, TravelAnimation.gd).
	## Bez ozdobnej ramki (use_menu_frame=false) root wypełnia CAŁY ekran bez
	## wcięcia (patrz plain_root w screen_helpers.gd), więc liczone wprost z
	## viewport_size — wcześniejsze 0.9 * ekran - 2×CONTENT_INSET_WITH_FRAME
	## odpowiadało geometrii ramki, która już nie istnieje.
	var viewport_size := get_viewport_rect().size
	var frame_content_width := viewport_size.x
	var frame_content_height := viewport_size.y

	var grid_total_size := frame_content_height
	cell_size = (
		grid_total_size - GRID_CONTENT_MARGIN * 2.0 - GRID_CELL_SEPARATION * (PlayerPlantations.GRID_SIZE - 1)
	) / PlayerPlantations.GRID_SIZE

	## Reszta szerokości (obok kwadratowej siatki) podzielona NA PÓŁ — 2
	## kolumny obok siebie: opis/sterowanie (lewa) i legenda wyglądu pól
	## (prawa) — zgłoszone przez użytkownika. Guziki/etykiety w obu kolumnach
	## dostają ten wyliczony rozmiar WPROST (zamiast domyślnych, szerszych
	## stałych z ScreenHelpers), żeby kolumna faktycznie zmieściła się w
	## swojej połowie, a nie ją rozepchnęła.
	var right_half_width := frame_content_width - grid_total_size - COLUMN_SEPARATION
	column_width = (right_half_width - COLUMN_SEPARATION) / 2.0
	legend_text_width = column_width - LEGEND_ICON_SIZE - 8.0

	## Siatka 16x16 (256 pól) w oprawionej ramce, jak w oryginale (zrzut
	## ekranu użytkownika: zielone pole z rzeką w niebieskiej ramce) — widok
	## płaski od góry, NIE izometryczny.
	var grid_frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.05, 0.15, 0.05, 0.6)
	frame_style.border_color = ScreenHelpers.COLOR_GOLD
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(4)
	frame_style.content_margin_left = GRID_CONTENT_MARGIN
	frame_style.content_margin_right = GRID_CONTENT_MARGIN
	frame_style.content_margin_top = GRID_CONTENT_MARGIN
	frame_style.content_margin_bottom = GRID_CONTENT_MARGIN
	grid_frame.add_theme_stylebox_override("panel", frame_style)
	grid_frame.custom_minimum_size = Vector2(grid_total_size, grid_total_size)
	main_row.add_child(grid_frame)

	grid_container = GridContainer.new()
	grid_container.columns = PlayerPlantations.GRID_SIZE
	grid_container.add_theme_constant_override("h_separation", int(GRID_CELL_SEPARATION))
	grid_container.add_theme_constant_override("v_separation", int(GRID_CELL_SEPARATION))
	grid_frame.add_child(grid_container)

	var right_half := HBoxContainer.new()
	right_half.alignment = BoxContainer.ALIGNMENT_CENTER
	right_half.add_theme_constant_override("separation", int(COLUMN_SEPARATION))
	main_row.add_child(right_half)

	## ALIGNMENT_BEGIN (nie CENTER) na obu kolumnach — zgłoszone przez
	## użytkownika: legenda ma zaczynać się od samej góry, tak samo jak opis.
	## Z CENTER każda kolumna centrowała się NIEZALEŻNIE w wysokości wiersza,
	## a że legenda miała mniej treści niż opis, wizualnie zaczynała się
	## niżej — z BEGIN obie zaczynają się dokładnie w tym samym miejscu.
	var info_column := VBoxContainer.new()
	info_column.alignment = BoxContainer.ALIGNMENT_BEGIN
	info_column.add_theme_constant_override("separation", 8)
	right_half.add_child(info_column)

	var legend_column := VBoxContainer.new()
	legend_column.alignment = BoxContainer.ALIGNMENT_BEGIN
	legend_column.add_theme_constant_override("separation", 6)
	right_half.add_child(legend_column)

	## Zgłoszenie użytkownika: lokalizacja/data NAD napisem "Plantacje"
	## (nie osobna skrzynka w rogu ekranu jak na innych ekranach) — siatka MA
	## być liczona na całą wysokość viewportu bez żadnych wyjątków, więc tu
	## etykieta jest zwykłym elementem info_column, nie absolutnym overlayem.
	location_label = ScreenHelpers.make_info_box(info_column, "", 0.0, 0, StatIconScript.Kind.DATE)
	ScreenHelpers.make_title(info_column, "Plantacje")
	ScreenHelpers.make_turn_indicator(info_column)

	## Bez wyboru miasta z listy — zgłoszone przez użytkownika: stojąc na
	## plantacji w jednym mieście nie powinno dać się zdalnie sadzić na
	## plantacji w INNYM mieście. Ekran zawsze zarządza plantacją miasta, w
	## którym gracz aktualnie się znajduje (Hub i tak pokazuje "Plantacje"
	## tylko w miastach typu plantacyjnego, patrz
	## Hub.LOCATION_GATED_DESTINATIONS, więc Travel.current_city zawsze jest
	## poprawnym miastem plantacyjnym, kiedy ten ekran jest w ogóle osiągalny).
	var city_label := ScreenHelpers.make_label(info_column, Cities.get_city_name(Travel.current_city))
	city_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	## custom_minimum_size.y: rezerwuje miejsce na zawsze DOKŁADNIE 4 wiersze
	## (patrz _update_info) — bez tego wysokość zależałaby od aktualnej
	## treści i przesuwałaby resztę kolumny przy każdej zmianie (patrz
	## komentarz przy _update_info). Szerokość = wyliczona column_width, nie
	## stała wartość — musi się zmieścić w połowie "reszty" obok siatki.
	## Wysokość na 3 wiersze (Gotówka przeniesiona do skrzynki w rogu, patrz
	## _ready wyżej — zostały Pola/Robotnicy/Zboże).
	info_label.custom_minimum_size = Vector2(column_width, 90)
	info_column.add_child(info_label)

	## Jedna plantacja może jednocześnie uprawiać WSZYSTKIE 4 rodzaje towaru
	## naraz (zgłoszone przez użytkownika) — każde pole ma WŁASNĄ uprawę
	## (patrz PlayerPlantations.plant_tile), więc to nie jest już "uprawa
	## całej plantacji". Ten dropdown wybiera tylko, KTÓRĄ uprawę zasadzić
	## przy najbliższym dotknięciu gołego (kupionego, ale niezasianego) pola.
	var crop_row := HBoxContainer.new()
	crop_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_column.add_child(crop_row)
	var crop_caption := Label.new()
	crop_caption.text = tr("Sadzić:")
	crop_caption.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	crop_row.add_child(crop_caption)
	crop_option = OptionButton.new()
	crop_option.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	## Zgłoszenie użytkownika (docs/DODATKOWE_MECHANIKI.md): "przemycana
	## uprawa" ma iść do sadzenia TYLKO w Ankarze/Gwatemali — filtrowane tu
	## (nie w samym Crops.CROPS, żeby generyczne pętle gdzie indziej w grze
	## dalej widziały ją jak każdą inną uprawę, patrz komentarz w Crops.gd).
	available_crops.clear()
	for crop in Crops.CROPS:
		if Crops.is_crop_available(crop, Travel.current_city):
			available_crops.append(crop)
			crop_option.add_item(Crops.CROP_NAMES[crop])
	crop_row.add_child(crop_option)

	var worker_row := HBoxContainer.new()
	worker_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_column.add_child(worker_row)
	var worker_caption := Label.new()
	worker_caption.text = tr("Robotnicy:")
	worker_caption.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	worker_row.add_child(worker_caption)
	worker_spin = SpinBox.new()
	worker_spin.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	worker_spin.min_value = 0
	worker_spin.max_value = PlayerPlantations.MAX_WORKERS
	worker_spin.step = 10
	worker_spin.value_changed.connect(_on_workers_changed)
	worker_row.add_child(worker_spin)

	harvest_status_label = ScreenHelpers.make_label(info_column, "")
	harvest_status_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	harvest_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	## custom_minimum_size.y: rezerwuje miejsce na 2 wiersze na stałe — bez
	## tego przełączanie między pustym tekstem (przed zbiorami) i najdłuższym
	## komunikatem ("Nic do zebrania — ...", 2 linie) zmieniało wysokość
	## etykiety i przesuwało guziki poniżej (ten sam problem co info_label
	## wyżej — patrz _update_info). Wysokość podniesiona do 60 (z 50) wraz z
	## większą czcionką.
	harvest_status_label.custom_minimum_size = Vector2(column_width, 60)

	## Puste miejsce nad guzikami rośnie/kurczy się (SIZE_EXPAND_FILL), więc
	## guziki zostają zawsze WYRÓWNANE OD DOŁU kolumny, na tej samej wysokości
	## co Spichlerz/Powrót w legend_column — zgłoszone przez użytkownika:
	## guziki pod napisem "Plantacje" mają się wyrównać do dołu tak samo jak
	## te pod legendą. status_label MUSI być PRZED spacerem (nie po guzikach,
	## jak poprzednio) — inaczej to on, nie guzik, byłby ostatnim elementem
	## kolumny i guziki kończyłyby się wyżej niż w legend_column.
	info_column.add_child(ScreenHelpers.make_expand_spacer())

	## Guziki akcji jeden POD drugim (nie obok siebie w jednym rzędzie, jak
	## poprzednio) — w węższej kolumnie (połowa "reszty" obok siatki, zamiast
	## całej prawej strony ekranu) dwa standardowe 320px-owe guziki obok
	## siebie by się nie zmieściły. column_width przekazane WPROST do
	## make_button (opcjonalny parametr width) zamiast domyślnych 320px.
	ScreenHelpers.make_button(info_column, "Zbierz plony", _on_harvest_pressed, column_width)
	## "Wyślij i sprzedaj" (bez "(Nowy Jork)", tak jak analogiczny guzik w
	## Warehouse.gd — jedyny magazyn w grze i tak jest tylko jeden) — pełny
	## napis z nazwą miasta był za długi na węższą kolumnę (column_width),
	## Godot obcinał go wewnątrz guzika.
	ScreenHelpers.make_button(info_column, "Wyślij i sprzedaj", _on_sell_pressed, column_width)
	## Pompa wodna (docs/DODATKOWE_MECHANIKI.md) — jednorazowa inwestycja per
	## plantacja, chroni przed suszą/powodzią (PlayerPlantations.WEATHER_RISK_CHANCE_PER_WEEK)
	## i podnosi plon o WATER_PUMP_YIELD_BONUS. Tekst/disabled aktualizowane w
	## _update_info(), zależnie od tego, czy TA plantacja już ją ma.
	pump_button = ScreenHelpers.make_button(info_column, "", _on_buy_pump_pressed, column_width)

	## Legenda WYGLĄDU pól — ikonka + podpis dla każdego stanu pola (nie tylko
	## opis liczbowy) — zgłoszone przez użytkownika: musi być pokazane, jak
	## wygląda każdy rodzaj pola, nie tylko ile ich jest. Rzeka/wolne/puste
	## Twoje pole/sąsiedztwo rzeki to stałe, zawsze te same wpisy (patrz
	## PlantationTileIcon.gd — kolor/kształt ikonki ma być czytelny sam z
	## siebie, legenda tu tylko dopowiada, co dana ikonka oznacza).
	## Zgłoszenie użytkownika: gotówka NAD napisem "Legenda", ta sama zasada
	## co location_label nad "Plantacje" wyżej — bez naruszania wysokości siatki.
	money_label = ScreenHelpers.make_info_box(legend_column, "", 0.0, 0, StatIconScript.Kind.MONEY)
	ScreenHelpers.make_title(legend_column, "Legenda")
	_add_legend_row(legend_column, PlantationTileIconScript.Kind.RIVER, "", false, tr("Rzeka"))
	_add_legend_row(legend_column, PlantationTileIconScript.Kind.VACANT, "", false, tr("Wolne pole (do kupienia)"))
	_add_legend_row(legend_column, PlantationTileIconScript.Kind.SOIL, "", false, tr("Twoje pole (niezasiane)"))
	_add_legend_row(legend_column, PlantationTileIconScript.Kind.SOIL, "", true, tr("Sąsiaduje z rzeką (większy plon)"))
	## Siatka miasta jest teraz wspólna dla wszystkich graczy (zgłoszone przez
	## użytkownika: "ten który zasieje w lepszym miejscu będzie miał lepsze
	## plony") — tylko w hot-seat multiplayer w ogóle może dojść do tego, że
	## pole jest zajęte przez KOGOŚ INNEGO (kolor + inicjał imienia, patrz
	## PlantationTileIcon.gd), więc wpis legendy tylko wtedy.
	if Players.is_multiplayer():
		_add_legend_row(legend_column, PlantationTileIconScript.Kind.OWNED_BY_OTHER, "", false, tr("Zajęte przez innego gracza (kolor/inicjał = kto)"))

	## Uprawy mają WŁASNY, dynamiczny podzbiór legendy (ikonka koloru danej
	## uprawy + ile pól nią obsianych) — jedyna część legendy, która się
	## zmienia, więc trzyma osobny kontener przebudowywany w _update_legend,
	## zamiast przebudowywać całą legendę (statyczne wpisy wyżej nigdy się
	## nie zmieniają).
	legend_crop_rows = VBoxContainer.new()
	legend_crop_rows.add_theme_constant_override("separation", 6)
	legend_column.add_child(legend_crop_rows)

	## Spichlerz/Powrót POD legendą (nie pod opisem, jak wcześniej) —
	## zgłoszone przez użytkownika. Efekt uboczny, którego użytkownik szukał
	## bez nazywania go wprost: opis (info_column) był wyższy niż legenda,
	## więc razem z siatką na pełną wysokość ramki całość nie mieściła się w
	## pionie i dokładała pasek przewijania (obcinając "Powrót" u dołu) —
	## przeniesienie tych dwóch guzików do krótszej kolumny wyrównuje obie
	## kolumny i usuwa potrzebę scrolla. Spacer przed nimi (jak w info_column
	## wyżej) — WYRÓWNANE OD DOŁU, na tej samej wysokości co guziki w drugiej
	## kolumnie, niezależnie od tego, ile pól ma akurat obsianych każda uprawa.
	legend_column.add_child(ScreenHelpers.make_expand_spacer())
	ScreenHelpers.make_button(legend_column, "Spichlerz »", func(): SceneRouter.goto_scene(SceneRouter.WAREHOUSE), column_width)
	ScreenHelpers.make_button(legend_column, "« Powrót", func(): SceneRouter.goto_hub(), column_width)

	_setup_current_plantation()


## Jeden wiersz legendy: mała ikonka pola (ta sama klasa co kafelki siatki,
## patrz PlantationTileIcon.gd) + tekstowy podpis obok niej.
func _add_legend_row(parent: Container, kind: int, crop: String, river_adjacent: bool, text: String) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var icon: Control = PlantationTileIconScript.new()
	icon.custom_minimum_size = Vector2(LEGEND_ICON_SIZE, LEGEND_ICON_SIZE)
	## SIZE_SHRINK_CENTER (pionowo) — zgłoszone przez użytkownika: gdy podpis
	## zawijał się na 2 linie, HBoxContainer domyślnie rozciągał ikonkę na
	## całą wysokość wiersza (do wysokości 2 linii tekstu), a _draw() w
	## PlantationTileIcon.gd rysuje na całym `size` kontrolki — więc ikonka
	## wizualnie "rozciągała się" zamiast zostać kwadracikiem w rozmiarze
	## pojedynczego pola siatki. Z SHRINK_CENTER ikonka zostaje przy swoim
	## custom_minimum_size niezależnie od wysokości wiersza, wyśrodkowana w
	## pionie obok tekstu.
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.kind = kind
	icon.crop = crop
	icon.river_adjacent = river_adjacent
	row.add_child(icon)

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
	label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	## autowrap + szerokość ograniczona do legend_text_width (column_width
	## minus ikonka minus odstęp) — najdłuższy podpis ("Sąsiaduje z rzeką...")
	## inaczej byłby szerszy niż kolumna i rozpychałby ją ponad wyliczoną
	## szerokość (ten sam problem co gdzie indziej w grze, patrz
	## make_info_box w screen_helpers.gd).
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(legend_text_width, 0)
	row.add_child(label)


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
## ikonka wypełniająca cały kafelek. Cztery klikalne/nieklikalne stany: "+"
## (kup pole), goła ziemia (kup, ale jeszcze nie zasiane — dotknij, żeby
## zasadzić wybraną w dropdownie uprawę), rzeka/obsiane pole (nieklikalne) i
## pole zajęte przez INNEGO gracza (nieklikalne — zgłoszone przez
## użytkownika: siatka miasta jest teraz wspólna dla wszystkich graczy,
## patrz PlayerPlantations.city_grids). Jedna plantacja może mieć różne
## uprawy na różnych polach naraz (zgłoszone przez użytkownika) — kolor/
## ikonka zależy od uprawy TEGO konkretnego pola.
func _rebuild_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	var plantation: Dictionary = PlayerPlantations.plantations[plantation_index]
	var city: String = plantation["city"]
	var grid: Dictionary = PlayerPlantations.city_grids[city]
	var tile_owner: Array = grid["tile_owner"]
	var tile_crops: Array = grid["tile_crops"]
	## Faza wzrostu (docs/GRAFIKA_LEONARDO.md wiersz 9) wspólna dla
	## WSZYSTKICH obsianych pól tej plantacji — last_harvest_day jest
	## wartością per-plantacja (patrz PlayerPlantations.calculate_harvest),
	## nie per-pole, więc im dłużej od ostatnich zbiorów (relatywnie do
	## PlayerPlantations.REFERENCE_PERIOD_DAYS, tego samego okresu co plon),
	## tym "dojrzalej" wyglądają rośliny — czysto kosmetyczne, nie wpływa na
	## faktyczny plon.
	var days_since_harvest: int = Players.active_day() - int(plantation["last_harvest_day"])
	var growth_ratio: float = clampf(days_since_harvest / PlayerPlantations.REFERENCE_PERIOD_DAYS, 0.0, 1.0)
	var growth_phase: int
	if growth_ratio < 1.0 / 3.0:
		growth_phase = PlantationTileIconScript.GrowthPhase.SEEDLING
	elif growth_ratio < 2.0 / 3.0:
		growth_phase = PlantationTileIconScript.GrowthPhase.GROWING
	else:
		growth_phase = PlantationTileIconScript.GrowthPhase.HARVEST
	for tile_index in tile_owner.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(cell_size, cell_size)
		btn.flat = true

		var icon: Control = PlantationTileIconScript.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if PlayerPlantations.is_river_tile(plantation_index, tile_index):
			icon.kind = PlantationTileIconScript.Kind.RIVER
			btn.disabled = true
		elif int(tile_owner[tile_index]) == Players.active_index:
			icon.river_adjacent = PlayerPlantations.is_adjacent_to_river(plantation_index, tile_index)
			var tile_crop: String = tile_crops[tile_index]
			if tile_crop != "":
				icon.kind = PlantationTileIconScript.Kind.CROP
				icon.crop = tile_crop
				icon.growth_phase = growth_phase
				btn.disabled = true
			else:
				icon.kind = PlantationTileIconScript.Kind.SOIL
				btn.pressed.connect(_on_plant_tile_pressed.bind(tile_index))
		elif int(tile_owner[tile_index]) != -1:
			icon.kind = PlantationTileIconScript.Kind.OWNED_BY_OTHER
			icon.owner_index = int(tile_owner[tile_index])
			btn.disabled = true
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
	var crop: String = available_crops[crop_option.selected]
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


func _on_buy_pump_pressed() -> void:
	if PlayerPlantations.buy_water_pump(plantation_index):
		harvest_status_label.text = tr("Pompa wodna kupiona — plantacja odporna na suszę/powódź.")
	else:
		harvest_status_label.text = tr("Za mało gotówki na pompę wodną.")
	_update_info()


## TRZY krótkie, stałe wiersze (każdy z osobna, sam jeden, zawsze mieści się
## w custom_minimum_size.x bez zawijania) zamiast jednego długiego zdania z
## autowrap — długość samej TREŚCI zmieniała liczbę zawiniętych linii, więc
## wysokość etykiety się zmieniała i przesuwała wszystko poniżej niej w tej
## samej kolumnie (zgłoszone przez użytkownika). "Uprawa" zniknęła z tej listy
## (jedna plantacja ma teraz WIELE upraw naraz, patrz _update_legend) —
## zamiast niej "Pola" ma teraz własny, osobny wiersz. "Gotówka" przeniesiona
## do skrzynki w prawym górnym rogu (patrz _ready), więc zostały 3 wiersze.
func _update_info() -> void:
	location_label.text = tr("%s\n%s") % [Cities.get_city_name(Travel.current_city), Calendar.format_day(Players.active_day())]
	money_label.text = tr("%.0f M") % Economy.player_money

	var plantation: Dictionary = PlayerPlantations.plantations[plantation_index]
	var stored: Dictionary = plantation["stored_goods"]
	var total_stored := 0
	for amount in stored.values():
		total_stored += int(amount)
	info_label.text = "%s\n%s\n%s" % [
		tr("Pola: %d") % PlayerPlantations.get_owned_tile_count(plantation_index),
		tr("Robotnicy: %d") % int(plantation["workers"]),
		tr("Zboże w magazynie: %d") % total_stored,
	]

	var has_pump := PlayerPlantations.has_water_pump(plantation_index)
	pump_button.text = tr("Pompa wodna (kupiona)") if has_pump else tr("Kup pompę wodną (%.0f M)") % PlayerPlantations.WATER_PUMP_COST
	pump_button.disabled = has_pump

	_update_legend()


## Dynamiczna część legendy: ikonka koloru KAŻDEJ DOSTĘPNEJ TU uprawy + ile
## pól jest nią obsianych — zgłoszone przez użytkownika. ZAWSZE dokładnie
## tyle samo wierszy, ile dostępnych upraw w TYM mieście (patrz
## available_crops — 4 zwykłe wszędzie, +1 "Przemycana uprawa" tylko w
## Ankarze/Gwatemali), nawet przy 0 pól — stała liczba wierszy niezależnie
## od wartości, żeby nic nie "skakało" przy sadzeniu kolejnych pól.
func _update_legend() -> void:
	for child in legend_crop_rows.get_children():
		child.queue_free()
	for crop in available_crops:
		var count := PlayerPlantations.get_planted_tile_count(plantation_index, crop)
		_add_legend_row(legend_crop_rows, PlantationTileIconScript.Kind.CROP, crop, false, tr("%s: %d pól") % [Crops.CROP_NAMES[crop], count])
