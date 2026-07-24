extends Node
## Kontrakty terminowe: dostawa X towaru w przyszłości po dziś ustalonej
## cenie. Cena nie zmienia się nawet po reformie walutowej — ale
## niedostarczenie towaru na czas oznacza karę umowną.
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 5, docs/DODATKOWE_MECHANIKI.md.

signal contract_fulfilled(contract: Dictionary)
signal contract_failed(contract: Dictionary)

const PENALTY_RATIO := 0.2  ## kara umowna = 20% wartości niedostarczonego kontraktu
const DUE_IN_DAYS := 30
const CONTRACT_AMOUNT := 100
const PRICE_PREMIUM := 1.1  ## kontrakt terminowy płaci 10% powyżej dzisiejszej ceny rynkowej

var active_contracts: Array[Dictionary] = []


func reset_new_game() -> void:
	active_contracts.clear()


func propose_contract(crop: String) -> void:
	var price_per_unit := Crops.get_price(crop) * PRICE_PREMIUM
	active_contracts.append({
		"crop": crop,
		"amount": CONTRACT_AMOUNT,
		"price_per_unit": price_per_unit,
		"due_day": Players.active_day() + DUE_IN_DAYS,
		"penalty": CONTRACT_AMOUNT * price_per_unit * PENALTY_RATIO,
	})


## Tor B — termin kontraktu liczony wg WŁASNEGO dnia aktywnego gracza (nie
## globalnego zegara), wywoływane wprost przez Players.advance_active_player_time
## (NIE podłączone do Calendar.day_advanced).
func apply_player_days_elapsed(_days_elapsed: int) -> void:
	var current_day := Players.active_day()
	var remaining: Array[Dictionary] = []
	for contract in active_contracts:
		if current_day < contract["due_day"]:
			remaining.append(contract)
			continue
		var available := PlayerPlantations.get_total_stored(contract["crop"])
		if available >= contract["amount"]:
			PlayerPlantations.consume_stored(contract["crop"], contract["amount"])
			Economy.earn(contract["amount"] * contract["price_per_unit"])
			contract_fulfilled.emit(contract)
		else:
			Economy.player_money -= contract["penalty"]
			contract_failed.emit(contract)
	active_contracts = remaining
