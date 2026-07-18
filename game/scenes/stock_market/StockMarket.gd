extends Control
## Giełda — działające kupno/sprzedaż akcji linii żeglugowych, z kursem
## powiązanym z aktywnością gracza na plantacjach (docs/MECHANIKI_EKONOMICZNE.md
## pkt. 7) i losowym dziennym dryfem (ShippingCompanies._on_day_advanced).

var rows_container: VBoxContainer
var info_label: Label


func _ready() -> void:
	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Giełda")

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)

	rows_container = VBoxContainer.new()
	root.add_child(rows_container)

	ScreenHelpers.make_label(root, "TODO: wykres cen w czasie, kontrakty terminowe")
	ScreenHelpers.make_back_button(root)

	_rebuild_rows()
	_update_info()


func _rebuild_rows() -> void:
	for child in rows_container.get_children():
		child.queue_free()
	for company_id in ShippingCompanies.COMPANIES.keys():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		rows_container.add_child(row)

		var company_name: String = ShippingCompanies.COMPANIES[company_id]["name"]
		var price := ShippingCompanies.get_price(company_id)
		var owned := ShippingCompanies.get_shares_owned(company_id)

		var label := Label.new()
		label.text = "%s: %.1f M (masz: %d)" % [company_name, price, owned]
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)

		var buy_btn := Button.new()
		buy_btn.text = "Kup 10"
		buy_btn.pressed.connect(_on_buy_pressed.bind(company_id))
		row.add_child(buy_btn)

		var sell_btn := Button.new()
		sell_btn.text = "Sprzedaj 10"
		sell_btn.pressed.connect(_on_sell_pressed.bind(company_id))
		row.add_child(sell_btn)


func _on_buy_pressed(company_id: String) -> void:
	ShippingCompanies.buy_shares(company_id, 10)
	_rebuild_rows()
	_update_info()


func _on_sell_pressed(company_id: String) -> void:
	ShippingCompanies.sell_shares(company_id, 10)
	_rebuild_rows()
	_update_info()


func _update_info() -> void:
	info_label.text = "Gotówka: %.0f M | Data: %s" % [Economy.player_money, Calendar.get_date_string()]
