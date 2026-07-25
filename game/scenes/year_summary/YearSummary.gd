extends Control
## Podsumowanie roku — pokazywane automatycznie zaraz po przekroczeniu
## Sylwestra w grze (patrz Hub.gd _ready, sprawdza YearlyReport.has_pending()
## PRZED zbudowaniem reszty Huba). Migawka gospodarki na koniec właśnie
## zakończonego roku: kursy 4 linii żeglugowych, ceny 4 towarów, inflacja,
## kurs dolara — tak jak "MONATSBERICHT" w oryginale (zrzut ekranu
## użytkownika), tylko raz na rok zamiast raz na miesiąc (uproszczony,
## turowy kalendarz gry nie ma osobnych miesięcznych raportów, patrz
## Calendar.gd).

var report: Dictionary = {}


func _ready() -> void:
	report = YearlyReport.consume_pending()

	ScreenHelpers.make_background(self, "res://art/backgrounds/stock_market.jpg")
	## use_menu_frame=false + ALIGNMENT_BEGIN + rozpychacze: zgłoszone przez
	## użytkownika — ozdobna ramka znika, nazwa ekranu zostaje przypięta na
	## samej górze, przycisk "Kontynuuj" na samym dole (ten sam wzorzec co
	## Gallery.gd _build_category_detail_view).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN

	ScreenHelpers.make_title(root, tr("Podsumowanie roku %d") % int(report.get("year", Calendar.get_year() - 1)))
	ScreenHelpers.make_turn_indicator(root)
	root.add_child(ScreenHelpers.make_expand_spacer())

	ScreenHelpers.make_label(root, tr("Linie żeglugowe"))
	var shipping_row := HBoxContainer.new()
	shipping_row.alignment = BoxContainer.ALIGNMENT_CENTER
	shipping_row.add_theme_constant_override("separation", 12)
	root.add_child(shipping_row)
	var shipping: Dictionary = report.get("shipping", {})
	for company_id in ShippingCompanies.COMPANIES.keys():
		var box := ScreenHelpers.make_boxed_row(shipping_row)
		var company_name: String = ShippingCompanies.COMPANIES[company_id]["name"]
		var label := Label.new()
		label.text = "%s\n%.1f M" % [company_name.to_upper(), float(shipping.get(company_id, ShippingCompanies.STARTING_PRICE))]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		box.add_child(label)

	ScreenHelpers.make_label(root, tr("Ceny towarów"))
	var crops_row := HBoxContainer.new()
	crops_row.alignment = BoxContainer.ALIGNMENT_CENTER
	crops_row.add_theme_constant_override("separation", 12)
	root.add_child(crops_row)
	var crops: Dictionary = report.get("crops", {})
	for crop in Crops.CROPS:
		var box := ScreenHelpers.make_boxed_row(crops_row)
		var label := Label.new()
		label.text = "%s\n%.1f M" % [Crops.CROP_NAMES[crop], float(crops.get(crop, Crops.BASE_CROP_PRICE.get(crop, 0.0)))]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		box.add_child(label)

	ScreenHelpers.make_label(root, tr("Inflacja: %.1f%%\nKurs dolara: %.2f M") % [
		float(report.get("inflation", Economy.inflation)) * 100.0,
		float(report.get("dollar_rate", Economy.dollar_rate)),
	])

	root.add_child(ScreenHelpers.make_expand_spacer())
	ScreenHelpers.make_button(root, tr("Kontynuuj »"), func(): SceneRouter.goto_hub())
