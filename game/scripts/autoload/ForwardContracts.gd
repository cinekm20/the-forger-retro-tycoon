extends Node
## Kontrakty terminowe: dostawa X towaru w przyszłości po dziś ustalonej
## cenie. Cena nie zmienia się nawet po reformie walutowej — ale
## niedostarczenie towaru na czas oznacza karę umowną.
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 5, docs/DODATKOWE_MECHANIKI.md.

signal contract_fulfilled(contract: Dictionary)
signal contract_failed(contract: Dictionary)

var active_contracts: Array[Dictionary] = []


func reset_new_game() -> void:
	active_contracts.clear()


func create_contract(crop: String, amount: int, price_per_unit: float, due_day: int, penalty: float) -> void:
	active_contracts.append({
		"crop": crop,
		"amount": amount,
		"price_per_unit": price_per_unit,
		"due_day": due_day,
		"penalty": penalty,
	})


## Wywoływać przy sprawdzaniu stanu kontraktów (np. po advance_days w Calendar).
func check_due_contracts(current_day: int, delivered_amounts: Dictionary) -> void:
	var remaining: Array[Dictionary] = []
	for contract in active_contracts:
		if current_day < contract["due_day"]:
			remaining.append(contract)
			continue
		var delivered: int = delivered_amounts.get(contract["crop"], 0)
		if delivered >= contract["amount"]:
			Economy.earn(contract["amount"] * contract["price_per_unit"])
			contract_fulfilled.emit(contract)
		else:
			Economy.player_money -= contract["penalty"]
			contract_failed.emit(contract)
	active_contracts = remaining
