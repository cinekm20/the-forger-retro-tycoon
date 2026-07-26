extends Node
## Kolejka wydarzeń "gazetowych" pokazywanych jako pełnoekranowa karta MIĘDZY
## TURAMI (scenes/world_event/WorldEventCard.gd), zanim Hub zbuduje normalny
## widok — zgłoszone przez użytkownika: "w formie gazety i popup między
## turami". Kolejka (Array), nie pojedynczy `pending` jak w YearlyReport.gd,
## bo w jednym dużym skoku dni (np. długa podróż) może uzbierać się kilka
## zdarzeń naraz — pokazywane jedno po drugim, nie zlewane w jeden komunikat.
##
## Dwa źródła zdarzeń:
## 1. Reforma walutowa (Economy.currency_reform) — dziś cicha zmiana
##    liczbowa (patrz Economy.gd _on_day_advanced), teraz dostaje kartę.
## 2. Kryzys na plantacji: strajk (brak wypłat) albo zamieszki (niestabilny
##    region) — patrz PlayerPlantations._apply_crisis_hit.

var queue: Array[Dictionary] = []


func _ready() -> void:
	Economy.currency_reform.connect(_on_currency_reform)


func reset_new_game() -> void:
	queue.clear()


func has_pending() -> bool:
	return not queue.is_empty()


## Wywoływać RAZ, tuż przed zbudowaniem karty — zdejmuje i zwraca NAJSTARSZE
## zdarzenie z kolejki (kolejność wydarzeń w czasie), żeby to samo zdarzenie
## nie pokazało się drugi raz.
func consume_next() -> Dictionary:
	return queue.pop_front()


func _on_currency_reform(ratio: float) -> void:
	queue.append({
		"kind": "reform",
		"ratio": ratio,
		"dollar_rate": Economy.dollar_rate,
	})


## Wywoływane z PlayerPlantations._apply_crisis_hit — cause: "wages" (strajk
## z zaległych wypłat) albo "unrest" (zamieszki w niestabilnym regionie).
func report_plantation_crisis(cause: String, city: String, workers_lost: int, crops_lost: bool, plantation_lost: bool) -> void:
	queue.append({
		"kind": "crisis",
		"cause": cause,
		"city": city,
		"workers_lost": workers_lost,
		"crops_lost": crops_lost,
		"plantation_lost": plantation_lost,
	})
