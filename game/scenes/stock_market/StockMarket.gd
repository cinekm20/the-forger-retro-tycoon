extends Control
## Giełda — działające kupno/sprzedaż akcji linii żeglugowych, z kursem
## powiązanym z aktywnością gracza na plantacjach (docs/MECHANIKI_EKONOMICZNE.md
## pkt. 7) i losowym dziennym dryfem (ShippingCompanies._on_day_advanced).
## Ceny towarów i kontrakty terminowe mają od tego osobny ekran — Rynek
## (scenes/market/Market.gd), zgłoszone przez użytkownika jako rozdzielenie
## dwóch odrębnych plansz z jednego ekranu Giełdy.

const VaultIconScript := preload("res://scripts/ui/VaultIcon.gd")
const PriceChartScript := preload("res://scripts/ui/PriceChart.gd")

## Kolory serii na wykresie (PriceChart.gd) — osobne od kolorów w
## PlantationTileIcon.CROP_COLORS (te dobrane pod tło pola/ikonkę, dość
## przygaszone). Tu każda spółka ma wyraźnie odróżnialny odcień.
const SHIPPING_COLORS := {
	"lloyd": Color(1.0, 0.83, 0.4),
	"star": Color(0.3, 0.78, 0.78),
	"hanse": Color(0.88, 0.35, 0.35),
	"royal": Color(0.6, 0.75, 0.95),
}

var rows_container: HFlowContainer
var location_label: Label
var money_label: Label
var trade_status_label: Label
var shipping_chart: Control


## Skrzynki lokalizacja/data (lewy górny róg) i gotówka (prawy górny róg)
## nawiązują do układu oryginału (patrz zrzuty ekranu użytkownika: "LONDON
## DEN 1.1.1918" / "50000 M") — ten sam trik co Hub.gd _build_top_row,
## współdzielony przez ScreenHelpers.make_corner_status_row.
func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/stock_market.jpg")
	var corner := ScreenHelpers.make_corner_status_row(self, "", "")
	location_label = corner["left"]
	money_label = corner["right"]

	## use_menu_frame=false + ALIGNMENT_BEGIN + rozpychacze: zgłoszone przez
	## użytkownika — ozdobna ramka znika, nazwa ekranu zostaje przypięta na
	## samej górze, przycisk powrotu na samym dole (ten sam wzorzec co
	## Gallery.gd _build_category_detail_view).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Giełda")
	ScreenHelpers.make_turn_indicator(root)
	root.add_child(ScreenHelpers.make_expand_spacer())

	## HFlowContainer zamiast HBoxContainer: na wąskim (portretowym) ekranie
	## 4 sejfy obok siebie by się nie zmieściły — FlowContainer sam
	## zawija do kolejnego wiersza, kiedy brakuje miejsca, więc układ
	## dostosowuje się do szerokości ekranu bez ręcznego liczenia kolumn.
	rows_container = HFlowContainer.new()
	rows_container.alignment = FlowContainer.ALIGNMENT_CENTER
	rows_container.add_theme_constant_override("h_separation", 20)
	rows_container.add_theme_constant_override("v_separation", 16)
	root.add_child(rows_container)

	trade_status_label = ScreenHelpers.make_label(root, "")

	## Wykres kursu linii żeglugowych w czasie (ShippingCompanies.price_history)
	## — rysowany natywnie (PriceChart.gd), tak jak sejfy/pinezki/ramki
	## indziej w tej grze (Leonardo.ai generuje pełne sceny zamiast czystego
	## wykresu). Legenda pod wykresem: kolorowy kwadracik + nazwa spółki.
	shipping_chart = PriceChartScript.new()
	shipping_chart.custom_minimum_size = Vector2(420, 140)
	shipping_chart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(shipping_chart)
	_build_chart_legend(root, ShippingCompanies.COMPANIES.keys(), func(id): return ShippingCompanies.COMPANIES[id]["name"], SHIPPING_COLORS)

	root.add_child(ScreenHelpers.make_expand_spacer())
	ScreenHelpers.make_back_button(root)

	_rebuild_rows()
	_update_info()


## Jedna kolumna na spółkę: sejf (VaultIcon) + nazwa pod spodem, tak jak w
## oryginale (patrz zrzut ekranu użytkownika — 5 sejfów z podpisami LLOYD/
## STAR/HANSE/ROYAL/US$), z ceną/przyciskami kup-sprzedaj poniżej.
func _rebuild_rows() -> void:
	for child in rows_container.get_children():
		child.queue_free()
	for company_id in ShippingCompanies.COMPANIES.keys():
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 4)
		rows_container.add_child(column)

		var icon: Control = VaultIconScript.new()
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(icon)

		var company_name: String = ShippingCompanies.COMPANIES[company_id]["name"]
		var name_label := Label.new()
		name_label.text = company_name.to_upper()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
		name_label.add_theme_font_size_override("font_size", 16)
		column.add_child(name_label)

		var price := ShippingCompanies.get_price(company_id)
		var owned := ShippingCompanies.get_shares_owned(company_id)
		var price_label := Label.new()
		price_label.text = tr("%.1f M (masz: %d)") % [price, owned]
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		column.add_child(price_label)

		var btn_row := HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(btn_row)

		var buy_btn := Button.new()
		buy_btn.text = "Kup 10"
		buy_btn.pressed.connect(_on_buy_pressed.bind(company_id))
		btn_row.add_child(buy_btn)

		var sell_btn := Button.new()
		sell_btn.text = "Sprzedaj 10"
		sell_btn.pressed.connect(_on_sell_pressed.bind(company_id))
		btn_row.add_child(sell_btn)


## Widoczna informacja o wyniku transakcji — wcześniej przycisk nic nie
## pokazywał przy nieudanym zakupie (np. za mało gotówki), więc wyglądało to,
## jakby stan gotówki "się nie aktualizował" (zgłoszone przez testera),
## mimo że transakcja po prostu nie doszła do skutku.
func _on_buy_pressed(company_id: String) -> void:
	var company_name: String = ShippingCompanies.COMPANIES[company_id]["name"]
	if ShippingCompanies.buy_shares(company_id, 10):
		trade_status_label.text = tr("Kupiono 10 akcji: %s.") % company_name
	else:
		trade_status_label.text = tr("Za mało gotówki, żeby kupić 10 akcji: %s.") % company_name
	_rebuild_rows()
	_update_info()


func _on_sell_pressed(company_id: String) -> void:
	var company_name: String = ShippingCompanies.COMPANIES[company_id]["name"]
	if ShippingCompanies.sell_shares(company_id, 10):
		trade_status_label.text = tr("Sprzedano 10 akcji: %s.") % company_name
	else:
		trade_status_label.text = tr("Nie masz 10 akcji, żeby sprzedać: %s.") % company_name
	_rebuild_rows()
	_update_info()


func _update_info() -> void:
	location_label.text = tr("%s\n%s") % [Cities.get_city_name(Travel.current_city), Calendar.format_day(Players.active_day())]
	money_label.text = tr("%.0f M") % Economy.player_money
	_update_chart()


## Kolorowy kwadracik + nazwa dla każdej serii, pod wykresem — czysty tekst
## wygodniej zrobić zwykłymi Labelami niż draw_string() w środku PriceChart.
func _build_chart_legend(parent: Container, ids: Array, get_name: Callable, colors: Dictionary) -> void:
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
		label.text = get_name.call(id)
		label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		entry.add_child(label)


## Odświeża wykres z aktualnej historii kursów (ShippingCompanies.price_history)
## — wywoływane za każdym razem, gdy coś mogło zmienić ceny (kupno/sprzedaż
## akcji, wejście na ekran).
func _update_chart() -> void:
	var shipping_series := {}
	for company_id in ShippingCompanies.COMPANIES.keys():
		shipping_series[company_id] = {
			"values": ShippingCompanies.price_history.get(company_id, []),
			"color": SHIPPING_COLORS.get(company_id, Color.WHITE),
		}
	shipping_chart.set_series(shipping_series)
