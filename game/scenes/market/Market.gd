extends Control
## Rynek — ceny towarów (kawa/tytoń/herbata/kakao) i kontrakty terminowe.
## Wydzielone z dawnego wspólnego ekranu Giełdy (StockMarket.gd) na wyraźne
## życzenie użytkownika: Giełda = akcje linii żeglugowych, Rynek = towary.
## Kontrakty terminowe idą tutaj, nie do Giełdy, bo dotyczą wyłącznie
## dostaw towarów (patrz ForwardContracts.gd — pole "crop"), nie akcji.

const PriceChartScript := preload("res://scripts/ui/PriceChart.gd")

## Kolory serii na wykresie (PriceChart.gd) — osobne od kolorów w
## PlantationTileIcon.CROP_COLORS (te dobrane pod tło pola/ikonkę, dość
## przygaszone — kawa i kakao wychodzą tam prawie tym samym brązem, co na
## LINII wykresu byłoby nieczytelne). Tu każda uprawa ma wyraźnie
## odróżnialny odcień.
const CROP_CHART_COLORS := {
	"coffee": Color(0.65, 0.42, 0.18),
	"tobacco": Color(0.88, 0.78, 0.25),
	"tea": Color(0.35, 0.68, 0.35),
	"cocoa": Color(0.75, 0.28, 0.18),
}

var crop_rows_container: HBoxContainer
var contracts_label: Label
var location_label: Label
var money_label: Label
var crop_chart: Control


## Skrzynki lokalizacja/data (lewy górny róg) i gotówka (prawy górny róg) —
## ten sam trik co Giełda/Hub, patrz ScreenHelpers.make_corner_status_row.
func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/market.jpg")
	var corner := ScreenHelpers.make_corner_status_row(self, "", "")
	location_label = corner["left"]
	money_label = corner["right"]

	## use_menu_frame=false + ALIGNMENT_BEGIN + JEDEN rozpychacz na końcu:
	## zgłoszone przez użytkownika — ozdobna ramka znika, nazwa ekranu zostaje
	## przypięta na samej górze, przycisk powrotu na samym dole. Treść leci
	## zaraz pod tytułem (bez rozpychacza między nimi) — patrz Races.gd po
	## szczegółowe uzasadnienie, czemu JEDEN rozpychacz (nie dwa).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Rynek")
	ScreenHelpers.make_turn_indicator(root)

	ScreenHelpers.make_title(root, "Ceny towarów")
	## HBoxContainer (nie VBoxContainer): zgłoszone przez użytkownika —
	## przycisk powrotu wychodził poza ekran ("za nisko"), bo bez ozdobnej
	## ramki ten ekran nie ma już ScrollContainera jako zabezpieczenia (patrz
	## plain_root w screen_helpers.gd), a suma wysokości WSZYSTKICH sekcji
	## (4 ceny towarów pod sobą + wykres + legenda + kontrakty) przekraczała
	## 720px. Jeden poziomy rząd zamiast 4 osobnych wierszy oszczędza
	## najwięcej miejsca bez utraty żadnej informacji.
	crop_rows_container = HBoxContainer.new()
	crop_rows_container.alignment = BoxContainer.ALIGNMENT_CENTER
	crop_rows_container.add_theme_constant_override("separation", 24)
	root.add_child(crop_rows_container)

	## Wykres cen towarów w czasie (Crops.price_history) — rysowany natywnie
	## (PriceChart.gd), tak jak sejfy/pinezki/ramki indziej w tej grze
	## (Leonardo.ai generuje pełne sceny zamiast czystego wykresu). Legenda
	## pod wykresem: kolorowy kwadracik + nazwa towaru. Oba w jednej złotej
	## ramce (ScreenHelpers.make_framed_box) — zgłoszone przez użytkownika:
	## "w rynku i giełdzie pod samym wykresem z legendą powinna być ramka".
	var chart_frame := ScreenHelpers.make_framed_box(root)
	crop_chart = PriceChartScript.new()
	crop_chart.custom_minimum_size = Vector2(420, 140)
	crop_chart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chart_frame.add_child(crop_chart)
	_build_chart_legend(chart_frame, Crops.CROPS, func(id): return Crops.CROP_NAMES[id], CROP_CHART_COLORS)

	ScreenHelpers.make_title(root, "Kontrakty terminowe")
	ScreenHelpers.make_label(
		root,
		tr("Kontrakt: %d jednostek za %d dni, cena dziś ×%.1f, kara %.0f%% przy niedostarczeniu") % [
			ForwardContracts.CONTRACT_AMOUNT, ForwardContracts.DUE_IN_DAYS,
			ForwardContracts.PRICE_PREMIUM, ForwardContracts.PENALTY_RATIO * 100.0,
		],
	)
	var contract_row := HBoxContainer.new()
	contract_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(contract_row)
	for crop in Crops.CROPS:
		var propose_btn := Button.new()
		propose_btn.text = tr("Zawrzyj: %s") % Crops.CROP_NAMES[crop]
		propose_btn.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		propose_btn.pressed.connect(_on_propose_contract_pressed.bind(crop))
		contract_row.add_child(propose_btn)

	contracts_label = ScreenHelpers.make_label(root, "")

	## Ozdobna skrzynka Art Deco w prawym dolnym rogu, TA SAMA co boczny
	## panel na TravelMap.gd/Hub.gd — zgłoszone przez użytkownika: przycisk
	## powrotu ma wyglądać tak samo na wszystkich ekranach (oprócz Plantacji).
	## Zakotwiczona niezależnie od `root`, więc bez rozpychacza.
	ScreenHelpers.make_boxed_back_button(self)

	_rebuild_crop_rows()
	_update_info()


func _rebuild_crop_rows() -> void:
	for child in crop_rows_container.get_children():
		child.queue_free()
	for crop in Crops.CROPS:
		var label := Label.new()
		label.text = tr("%s: %.1f M / jednostkę") % [Crops.CROP_NAMES[crop], Crops.get_price(crop)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		crop_rows_container.add_child(label)


func _on_propose_contract_pressed(crop: String) -> void:
	ForwardContracts.propose_contract(crop)
	_update_info()


func _update_info() -> void:
	location_label.text = tr("%s\n%s") % [Cities.get_city_name(Travel.current_city), Calendar.format_day(Players.active_day())]
	money_label.text = tr("%.0f M") % Economy.player_money
	_rebuild_crop_rows()
	_update_chart()

	var lines: Array[String] = []
	for contract in ForwardContracts.active_contracts:
		lines.append(tr("%s: %d szt. po %.1f M, termin dzień %d, kara %.0f M") % [
			Crops.CROP_NAMES[contract["crop"]], contract["amount"], contract["price_per_unit"],
			contract["due_day"], contract["penalty"],
		])
	contracts_label.text = "\n".join(lines) if not lines.is_empty() else tr("Brak aktywnych kontraktów.")


## Kolorowy kwadracik + nazwa dla każdej serii, pod wykresem — czysty tekst
## wygodniej zrobić zwykłymi Labelami niż draw_string() w środku PriceChart.
func _build_chart_legend(parent: Container, ids: Array, name_for_id: Callable, colors: Dictionary) -> void:
	var legend_row := HBoxContainer.new()
	legend_row.alignment = BoxContainer.ALIGNMENT_CENTER
	legend_row.add_theme_constant_override("separation", 16)
	parent.add_child(legend_row)

	for id in ids:
		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 4)
		legend_row.add_child(entry)

		var swatch := ColorRect.new()
		swatch.color = colors.get(id, Color.WHITE)
		swatch.custom_minimum_size = Vector2(14, 14)
		entry.add_child(swatch)

		var label := Label.new()
		label.text = name_for_id.call(id)
		label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		entry.add_child(label)


## Odświeża wykres z aktualnej historii cen (Crops.price_history) —
## wywoływane za każdym razem, gdy coś mogło zmienić ceny (nowy kontrakt,
## wejście na ekran).
func _update_chart() -> void:
	var crop_series := {}
	for crop in Crops.CROPS:
		crop_series[crop] = {
			"values": Crops.price_history.get(crop, []),
			"color": CROP_CHART_COLORS.get(crop, Color.WHITE),
		}
	crop_chart.set_series(crop_series)
