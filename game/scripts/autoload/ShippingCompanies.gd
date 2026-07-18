extends Node
## 4 fikcyjne linie żeglugowe, notowane na giełdzie — ich kurs rośnie wraz
## z aktywnością gracza na plantacjach danego regionu.
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 7.

const COMPANIES := {
	"lloyd": {"name": "Lloyd", "region": "asia"},
	"star": {"name": "Star", "region": "africa"},
	"hanse": {"name": "Hanse", "region": "south_america"},
	"royal": {"name": "Royal", "region": "north_america"},
}

const STARTING_PRICE := 100.0  ## zgodnie z realiami startu gry (1918, Londyn)

var stock_price: Dictionary = {}


func reset_new_game() -> void:
	stock_price.clear()
	for company_id in COMPANIES.keys():
		stock_price[company_id] = STARTING_PRICE


func boost_from_region_activity(region: String, amount: float) -> void:
	for company_id in COMPANIES.keys():
		if COMPANIES[company_id]["region"] == region:
			stock_price[company_id] += amount


func get_price(company_id: String) -> float:
	return stock_price.get(company_id, STARTING_PRICE)
