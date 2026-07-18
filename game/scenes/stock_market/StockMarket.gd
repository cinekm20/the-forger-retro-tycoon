extends Control
## Placeholder — docelowo wykres cen, kupno/sprzedaż akcji, kontrakty
## terminowe. Patrz GDD.md pkt. 4.3. Pokazuje już żywe kursy linii
## żeglugowych z ShippingCompanies (docs/MECHANIKI_EKONOMICZNE.md pkt. 7).

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Giełda (placeholder)")

	for company_id in ShippingCompanies.COMPANIES.keys():
		var company_name: String = ShippingCompanies.COMPANIES[company_id]["name"]
		var price := ShippingCompanies.get_price(company_id)
		ScreenHelpers.make_label(root, "%s: %.1f M" % [company_name, price])

	ScreenHelpers.make_label(root, "TODO: wykres cen, kupno/sprzedaż, kontrakty terminowe")
	ScreenHelpers.make_back_button(root)
